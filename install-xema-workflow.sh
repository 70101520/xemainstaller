#!/usr/bin/env bash
set -euo pipefail

OFFICIAL_INSTALL_URL="${XEMA_BASE_INSTALL_URL:-https://raw.githubusercontent.com/xema-in/install/master/install-xema.sh}"
PACKAGE_URL="${XEMA_WORKFLOW_PACKAGE_URL:-https://raw.githubusercontent.com/70101520/xemainstaller/main/packages/xema-workflow-linux-x64.tgz}"
PACKAGE_SHA256="${XEMA_WORKFLOW_PACKAGE_SHA256:-ee4807c581542c80ffc2f1274c3d25861327a39dd92324776bfefb5b03040f27}"

SKIP_BASE=0
SKIP_UPGRADE=0
BASE_ARGS=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --skip-base)
      SKIP_BASE=1
      shift
      ;;
    --skip-upgrade)
      SKIP_UPGRADE=1
      shift
      ;;
    --package-url)
      PACKAGE_URL="${2:?--package-url requires a URL}"
      shift 2
      ;;
    --package-file)
      PACKAGE_URL="file://$(realpath "${2:?--package-file requires a local archive}")"
      shift 2
      ;;
    --package-sha256)
      PACKAGE_SHA256="${2:?--package-sha256 requires a sha256 value}"
      shift 2
      ;;
    *)
      BASE_ARGS+=("$1")
      shift
      ;;
  esac
done

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root, for example:" >&2
  echo "  curl -fsSL https://raw.githubusercontent.com/70101520/xemainstaller/main/install-xema-workflow.sh | sudo bash -s -- -d -vvv" >&2
  exit 1
fi

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

need_cmd curl
need_cmd tar
need_cmd sha256sum
need_cmd systemctl
need_cmd python3

timestamp="$(date +%Y%m%d-%H%M%S)"
workdir="$(mktemp -d /tmp/xema-workflow-install.XXXXXX)"
backup_dir=""
deploy_started=0
config_backup=""
config_paths=(/etc/nginx/sites-available/xema.nginx /etc/nginx/snippets/xema-proxy-security.conf
  /etc/ssl/certs/certificate.pem /etc/ssl/private/key.pem
  /etc/asterisk/http.conf /etc/asterisk/modules.conf /etc/asterisk/pjsip.conf
  /etc/asterisk/keys/xema-cert.pem /etc/asterisk/keys/xema-key.pem
  /etc/systemd/system/xema-manager.service.d/self-contained.conf)

cleanup() {
  rm -rf "$workdir"
}

rollback() {
  local exit_code=$?
  if [ "$deploy_started" -eq 1 ] && [ -n "$backup_dir" ] && [ -d "$backup_dir" ]; then
    echo "Install failed. Restoring backup: $backup_dir" >&2
    systemctl stop xema-manager >/dev/null 2>&1 || true
    rm -rf /var/lib/xema/manager
    cp -a "$backup_dir" /var/lib/xema/manager
    for path in "${config_paths[@]}"; do
      if [ -e "$config_backup$path" ]; then cp -a "$config_backup$path" "$path";
      else rm -f "$path"; fi
    done
    systemctl daemon-reload >/dev/null 2>&1 || true
    systemctl reset-failed xema-manager >/dev/null 2>&1 || true
    systemctl start xema-manager >/dev/null 2>&1 || true
    nginx -t && systemctl reload nginx || true
    systemctl restart asterisk || true
  fi
  cleanup
  exit "$exit_code"
}

trap rollback ERR
trap cleanup EXIT

run_base_install() {
  if [ "$SKIP_BASE" -eq 1 ]; then
    echo "Skipping official base install."
    return 0
  fi

  echo "Downloading official XEMA base installer..."
  local base_script="$workdir/install-xema.sh"
  curl -fsSL "$OFFICIAL_INSTALL_URL" -o "$base_script"
  chmod +x "$base_script"

  echo "Running official XEMA base installer..."
  bash "$base_script" "${BASE_ARGS[@]}"
}

download_package() {
  if [ "$SKIP_UPGRADE" -eq 1 ]; then
    echo "Skipping XEMA workflow package upgrade."
    return 0
  fi

  echo "Downloading XEMA workflow package..."
  local package="$workdir/xema-workflow-linux-x64.tgz"
  curl -fL "$PACKAGE_URL" -o "$package"

  [[ "$PACKAGE_SHA256" =~ ^[[:xdigit:]]{64}$ ]] || { echo 'A package SHA256 is required.' >&2; exit 1; }
  echo "${PACKAGE_SHA256}  ${package}" | sha256sum -c -

  python3 - "$package" <<'PY'
import pathlib, sys, tarfile
with tarfile.open(sys.argv[1]) as archive:
    for entry in archive.getmembers():
        path = pathlib.PurePosixPath(entry.name)
        if path.is_absolute() or '..' in path.parts or not (entry.isfile() or entry.isdir()):
            raise SystemExit('Unsafe package member: ' + entry.name)
PY

  mkdir -p "$workdir/package"
  tar -xzf "$package" -C "$workdir/package"
  test -s "$workdir/package/deploy/apply-xema-web-security.sh"
  test -s "$workdir/package/deploy/configure-xema-security.py"
  test -s "$workdir/package/deploy/xema-secure.nginx"
  test -s "$workdir/package/SECURITY_BASELINE.txt"
}

copy_app_without_local_settings() {
  local src="$1"
  local dst="$2"

  find "$src" -mindepth 1 -maxdepth 1 ! -name 'appsettings*.json' -exec cp -a {} "$dst"/ \;
}

deploy_workflow_package() {
  if [ "$SKIP_UPGRADE" -eq 1 ]; then
    return 0
  fi

  local package_dir="$workdir/package"
  local manager_dir="/var/lib/xema/manager"

  if [ ! -d "$manager_dir" ]; then
    echo "Base install did not create $manager_dir" >&2
    exit 1
  fi

  if [ ! -d "$package_dir/app" ] || [ ! -d "$package_dir/wwwroot" ]; then
    echo "Invalid package layout. Expected app/ and wwwroot/ folders." >&2
    exit 1
  fi

  for portal in agent admin live-view data-portal; do
    local index="$package_dir/wwwroot/$portal/index.html"
    if [ ! -s "$index" ] || grep -qi 'stub' "$index" || ! grep -q '<app-root' "$index"; then
      echo "Package has a missing or placeholder portal: $portal" >&2
      exit 1
    fi
    if ! find "$package_dir/wwwroot/$portal" -maxdepth 1 -name 'main*.js' -size +0c | grep -q .; then
      echo "Package missing JavaScript bundle: $portal" >&2
      exit 1
    fi
  done

  backup_dir="/root/xema-manager-backup-${timestamp}"
  if systemctl is-active --quiet asterisk; then
    if [ -n "$(asterisk -rx 'core show channels concise')" ]; then
      echo 'Active calls detected; installation deferred.' >&2
      exit 1
    fi
  fi
  echo "Backing up current manager to $backup_dir"
  cp -a "$manager_dir" "$backup_dir"
  config_backup="${backup_dir}-config"
  mkdir -p -m 0700 "$config_backup"
  for path in "${config_paths[@]}"; do
    if [ -e "$path" ]; then cp -a --parents "$path" "$config_backup/"; fi
  done
  deploy_started=1

  echo "Stopping xema-manager..."
  systemctl stop xema-manager

  echo "Deploying backend files..."
  copy_app_without_local_settings "$package_dir/app" "$manager_dir"
  chmod +x "$manager_dir/Manager" "$manager_dir/DbV2" "$manager_dir/Typelings" 2>/dev/null || true

  echo "Deploying web portals..."
  mkdir -p "$manager_dir/wwwroot"
  for portal in agent admin live-view data-portal; do
    if [ ! -d "$package_dir/wwwroot/$portal" ]; then
      echo "Package missing wwwroot/$portal" >&2
      exit 1
    fi
    rm -rf "$manager_dir/wwwroot/$portal"
    mkdir -p "$manager_dir/wwwroot/$portal"
    cp -a "$package_dir/wwwroot/$portal/." "$manager_dir/wwwroot/$portal/"
  done

  echo "Applying runtime prerequisites..."
  bash "$package_dir/deploy/apply-xema-runtime-prereqs.sh"

  echo "Restarting services..."
  systemctl restart asterisk
  systemctl daemon-reload
  systemctl reset-failed xema-manager
  systemctl start xema-manager
}

verify_install() {
  if [ "$SKIP_UPGRADE" -eq 1 ]; then
    return 0
  fi

  echo "Verifying XEMA workflow install..."
  systemctl is-active --quiet xema-manager
  systemctl is-active --quiet asterisk
  for attempt in $(seq 1 30); do
    if curl -fsS http://127.0.0.1:4200/api/Setup/Ping >/dev/null; then break; fi
    sleep 2
  done
  test "$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:4200/hangfire/)" = 401
  test "$(curl -ks -o /dev/null -w '%{http_code}' https://127.0.0.1/netdata/api/v1/info)" = 401
  test "$(curl -ks -o /dev/null -w '%{http_code}' https://127.0.0.1/api/Admin/SystemHealth)" = 401
  grep -Fq '/api/Admin/SystemHealth' /var/lib/xema/manager/wwwroot/admin/main*.js

  if grep -Ei 'stub' \
    /var/lib/xema/manager/wwwroot/agent/index.html \
    /var/lib/xema/manager/wwwroot/admin/index.html \
    /var/lib/xema/manager/wwwroot/live-view/index.html \
    /var/lib/xema/manager/wwwroot/data-portal/index.html >/dev/null 2>&1; then
    echo "Stub page detected after deploy." >&2
    exit 1
  fi

  if ! asterisk -rx "module show like websocket" | grep -q "res_http_websocket.so"; then
    echo "Asterisk websocket module verification failed." >&2
    exit 1
  fi

  echo "XEMA workflow install completed successfully."
}

download_package
run_base_install
deploy_workflow_package
verify_install

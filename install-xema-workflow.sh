#!/usr/bin/env bash
set -euo pipefail

OFFICIAL_INSTALL_URL="${XEMA_BASE_INSTALL_URL:-https://raw.githubusercontent.com/xema-in/install/master/install-xema.sh}"
PACKAGE_URL="${XEMA_WORKFLOW_PACKAGE_URL:-https://raw.githubusercontent.com/70101520/xemainstaller/main/packages/xema-workflow-linux-x64.tgz}"
PACKAGE_SHA256="${XEMA_WORKFLOW_PACKAGE_SHA256:-fcd84a9d5f40695b8424564a09201708ca95635203abe34bea6c10f0725ac0ad}"

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

timestamp="$(date +%Y%m%d-%H%M%S)"
workdir="$(mktemp -d /tmp/xema-workflow-install.XXXXXX)"
backup_dir=""
deploy_started=0

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
    rm -f /etc/systemd/system/xema-manager.service.d/self-contained.conf
    systemctl daemon-reload >/dev/null 2>&1 || true
    systemctl reset-failed xema-manager >/dev/null 2>&1 || true
    systemctl start xema-manager >/dev/null 2>&1 || true
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

  if [ -n "$PACKAGE_SHA256" ]; then
    echo "${PACKAGE_SHA256}  ${package}" | sha256sum -c -
  fi

  mkdir -p "$workdir/package"
  tar -xzf "$package" -C "$workdir/package"
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

  backup_dir="/root/xema-manager-backup-${timestamp}"
  echo "Backing up current manager to $backup_dir"
  cp -a "$manager_dir" "$backup_dir"
  deploy_started=1

  echo "Stopping xema-manager..."
  systemctl stop xema-manager

  echo "Deploying backend files..."
  copy_app_without_local_settings "$package_dir/app" "$manager_dir"
  chmod +x "$manager_dir/Manager" "$manager_dir/DbV2" "$manager_dir/Typelings" 2>/dev/null || true

  echo "Deploying web portals..."
  mkdir -p "$manager_dir/wwwroot"
  for portal in agent admin live-view; do
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

  if grep -R "Agent Stub\|Admin Stub\|Live View Stub" \
    /var/lib/xema/manager/wwwroot/agent \
    /var/lib/xema/manager/wwwroot/admin \
    /var/lib/xema/manager/wwwroot/live-view >/dev/null 2>&1; then
    echo "Stub page detected after deploy." >&2
    exit 1
  fi

  if ! asterisk -rx "module show like websocket" | grep -q "res_http_websocket.so"; then
    echo "Asterisk websocket module verification failed." >&2
    exit 1
  fi

  echo "XEMA workflow install completed successfully."
}

run_base_install
download_package
deploy_workflow_package
verify_install

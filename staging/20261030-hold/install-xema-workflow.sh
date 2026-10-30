#!/usr/bin/env bash
set -Eeuo pipefail

PACKAGE_URL="${XEMA_WORKFLOW_PACKAGE_URL:-https://raw.githubusercontent.com/70101520/xemainstaller/main/staging/20261030-hold/xema-workflow-linux-x64.tgz}"
PACKAGE_SHA256="${XEMA_WORKFLOW_PACKAGE_SHA256:-7cb48438d99684c60ff485ef5b709af831f0f686e6381b41685c8c6945f1c307}"

SKIP_BASE=0
SKIP_UPGRADE=0
STAGING=0
VERIFY_ONLY=0
BASE_ARGS=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --staging)
      STAGING=1
      shift
      ;;
    --verify-package-only)
      VERIFY_ONLY=1
      shift
      ;;
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

if [ "$VERIFY_ONLY" -eq 1 ] && [ "$SKIP_UPGRADE" -eq 1 ]; then
  echo '--verify-package-only cannot skip package verification.' >&2
  exit 1
fi
if [ "$SKIP_UPGRADE" -eq 1 ] && [ "$STAGING" -ne 1 ]; then
  echo 'Production installations cannot bypass the qualified workflow package.' >&2
  exit 1
fi
if [ "$STAGING" -ne 1 ]; then
  for argument in "${BASE_ARGS[@]}"; do
    if [[ "$argument" =~ ^-[^-]*d ]]; then
      echo 'Dev base installations require explicit --staging; production must not use -d.' >&2
      exit 1
    fi
  done
fi
if [ "${#BASE_ARGS[@]}" -gt 0 ]; then
  echo 'Unsupported base arguments: the reviewed package-local installer does not accept legacy/unknown options.' >&2
  exit 1
fi
if [ "$VERIFY_ONLY" -ne 1 ] && [ "$(id -u)" -ne 0 ]; then
  echo "Run as root, for example:" >&2
  echo "  sudo bash install-xema-workflow.sh --package-file reviewed-release.tgz --package-sha256 REVIEWED_SHA256" >&2
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
manager_was_active=0
manager_was_enabled=0
started_workers=()
enabled_workers=()
config_backup=""
config_paths=(/etc/nginx/sites-available/xema.nginx /etc/nginx/snippets/xema-proxy-security.conf
  /etc/ssl/certs/certificate.pem /etc/ssl/private/key.pem
  /etc/asterisk/http.conf /etc/asterisk/modules.conf /etc/asterisk/pjsip.conf
  /etc/asterisk/keys/xema-cert.pem /etc/asterisk/keys/xema-key.pem
  /etc/systemd/system/xema-manager.service.d/self-contained.conf)

cleanup() {
  rm -rf "$workdir"
}

check_calls() {
  local counts channels
  if systemctl is-active --quiet asterisk || pgrep -x asterisk >/dev/null; then
    counts="$(asterisk -rx 'core show channels count')" || return 1
    grep -qx '0 active channels' <<< "$counts" || return 1
    grep -qx '0 active calls' <<< "$counts" || return 1
    channels="$(asterisk -rx 'core show channels concise')" || return 1
    [ -z "$channels" ] || return 1
  fi
}

start_manager() {
  systemctl cat xema-manager >/dev/null 2>&1 || return 1
  if systemctl is-failed --quiet xema-manager; then
    systemctl reset-failed xema-manager || return 1
  fi
  systemctl start xema-manager || return 1
  systemctl enable xema-manager
}

check_websocket_module() {
  local modules
  modules="$(asterisk -rx 'module show like websocket')" || return 1
  grep -Fq 'res_http_websocket.so' <<< "$modules"
}

preflight() {
  . /etc/os-release
  [ "$ID" = ubuntu ] && [[ "$VERSION_ID" = 22.04 || "$VERSION_ID" = 24.04 ]] || {
    echo 'This package requires a reviewed Ubuntu 22.04/24.04 host.' >&2; return 1;
  }
  [ "$(uname -m)" = x86_64 ] || { echo 'This package requires x86-64/AMD64.' >&2; return 1; }
  if [ "$SKIP_BASE" -ne 1 ] && [ -s /var/lib/xema/manager/appsettings.json ]; then
    echo 'Existing XEMA detected: base reinstall refused. Use a reviewed --skip-base upgrade with full backups.' >&2
    return 1
  fi
  check_calls || { echo 'Installation deferred: calls active or call-state check failed.' >&2; return 1; }
  if [ "$SKIP_BASE" -eq 1 ] && [ "${XEMA_REPLACE_STOCK_NGINX:-0}" != 1 ]; then
    local site
    site="$(readlink -f /etc/nginx/sites-enabled/xema.nginx)"
    if [ ! -f "$site" ] || ! grep -q 'XEMA managed security configuration v1' "$site"; then
      echo 'Custom/missing nginx layout requires explicit operator review before upgrade; no service was stopped.' >&2
      return 1
    fi
  fi
}

rollback() {
  local exit_code="${1:-$?}"
  trap - ERR EXIT
  if [ "$deploy_started" -eq 1 ] && [ -n "$backup_dir" ] && [ -d "$backup_dir" ]; then
    if ! check_calls; then
      echo "Rollback deferred: calls active or call-state check failed. Retain $backup_dir and $config_backup for manual recovery." >&2
      exit "$exit_code"
    fi
    echo "Install failed. Restoring backup: $backup_dir" >&2
    for service in "${started_workers[@]}"; do systemctl stop "$service" >/dev/null 2>&1 || true; done
    for service in "${enabled_workers[@]}"; do systemctl disable "$service" >/dev/null 2>&1 || true; done
    systemctl stop xema-manager >/dev/null 2>&1 || true
    rm -rf /var/lib/xema/manager
    cp -a "$backup_dir" /var/lib/xema/manager
    for path in "${config_paths[@]}"; do
      if [ -e "$config_backup$path" ]; then cp -a "$config_backup$path" "$path";
      else rm -f "$path"; fi
    done
    systemctl daemon-reload >/dev/null 2>&1 || true
    systemctl reset-failed xema-manager >/dev/null 2>&1 || true
    if [ "$manager_was_active" -eq 1 ]; then systemctl start xema-manager >/dev/null 2>&1 || true; fi
    if [ "$manager_was_enabled" -ne 1 ]; then systemctl disable xema-manager >/dev/null 2>&1 || true; fi
    nginx -t && systemctl reload nginx || true
    systemctl restart asterisk || true
  fi
  cleanup
  exit "$exit_code"
}

finish_install() {
  local exit_code=$?
  trap - EXIT
  if [ "$exit_code" -ne 0 ]; then rollback "$exit_code"; fi
  cleanup
}

trap 'rollback $?' ERR
trap finish_install EXIT

run_base_install() {
  if [ "$SKIP_BASE" -eq 1 ]; then
    echo "Skipping fresh base setup."
    return 0
  fi

  test -s "$workdir/package/deploy/install-xema-base.sh"
  test -s "$workdir/package/deploy/configure-xema-base.py"
  test -s "$workdir/package/deploy/xema-base-assets.lock.json"
  echo "Running the reviewed package-local fresh base installer..."
  bash "$workdir/package/deploy/install-xema-base.sh" "$workdir/package"
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
  python3 - "$workdir/package" "$STAGING" <<'PY'
import hashlib, json, pathlib, re, sys
root = pathlib.Path(sys.argv[1])
status_path = root / 'RELEASE_STATUS.json'
if not status_path.is_file():
    raise SystemExit('Package qualification manifest is missing; do not mix an old archive with this launcher.')
status = json.loads(status_path.read_text())
if status.get('schemaVersion') != 1 or type(status.get('productionApproved')) is not bool:
    raise SystemExit('Invalid package qualification manifest.')
if status.get('productionApproved') is not True and sys.argv[2] != '1':
    raise SystemExit('Production installation blocked: this package is staging-only. Resolve its blockers; --staging is for isolated tests only.')
if status.get('qualification') not in ('staging-only', 'production-approved'):
    raise SystemExit('Unknown package qualification.')
if status['productionApproved'] != (status['qualification'] == 'production-approved'):
    raise SystemExit('Inconsistent package qualification.')
files = sorted((path for path in root.rglob('*') if path.is_file() and path != status_path),
               key=lambda path: path.relative_to(root).as_posix())
tree = ''.join(path.relative_to(root).as_posix() + '\t' + hashlib.sha256(path.read_bytes()).hexdigest() + '\n' for path in files)
if status.get('payloadTreeSha256') != hashlib.sha256(tree.encode('utf-8')).hexdigest():
    raise SystemExit('Package payload does not match its tested qualification manifest.')
dependencies = json.loads((root / 'app/Manager.deps.json').read_text())['libraries']
database_dependencies = sorted(name for name in dependencies if name.startswith((
    'Microsoft.EntityFrameworkCore/', 'Pomelo.EntityFrameworkCore.MySql/', 'Microting.EntityFrameworkCore.MySql/')))
if len(database_dependencies) != 2 or sorted(status.get('databaseDependencies', [])) != database_dependencies:
    raise SystemExit('Package/database dependency manifest mismatch.')
if status['productionApproved'] and any('/10.0.' not in name for name in database_dependencies):
    raise SystemExit('Production database-provider support lifecycle is not qualified.')
runtime = json.loads((root / 'app/Manager.runtimeconfig.json').read_text())['runtimeOptions']
version = status.get('runtimeVersion', '')
frameworks = {item['name']: item['version'] for item in runtime.get('includedFrameworks', [])}
if status.get('framework') != 'net10.0' or runtime.get('tfm') != 'net10.0' or not re.fullmatch(r'10\.0\.\d+', version):
    raise SystemExit('Matching self-contained .NET 10 backend required.')
if any(frameworks.get(name) != version for name in ('Microsoft.NETCore.App', 'Microsoft.AspNetCore.App')):
    raise SystemExit('Package/runtime version mismatch.')
print('Verified package qualification: ' + status['qualification'])
PY
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
  check_calls || { echo 'Installation deferred: calls active or call-state check failed.' >&2; return 1; }
  echo "Backing up current manager to $backup_dir"
  cp -a "$manager_dir" "$backup_dir"
  config_backup="${backup_dir}-config"
  mkdir -p -m 0700 "$config_backup"
  for path in "${config_paths[@]}"; do
    if [ -e "$path" ]; then cp -a --parents "$path" "$config_backup/"; fi
  done
  if systemctl is-active --quiet xema-manager; then manager_was_active=1; fi
  if systemctl is-enabled --quiet xema-manager; then manager_was_enabled=1; fi
  deploy_started=1

  check_calls || { echo 'Installation deferred: calls active or call-state check failed.' >&2; return 1; }
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
  check_calls || { echo 'Restart deferred: calls active or call-state check failed.' >&2; return 1; }
  systemctl restart asterisk
  systemctl daemon-reload
  start_manager
}

verify_install() {
  if [ "$SKIP_UPGRADE" -eq 1 ]; then
    return 0
  fi

  echo "Verifying XEMA workflow install..."
  systemctl is-active --quiet xema-manager
  systemctl is-active --quiet asterisk
  local ready=0
  for attempt in $(seq 1 30); do
    if curl -fsS http://127.0.0.1:4200/api/Setup/Ping >/dev/null; then ready=1; break; fi
    sleep 2
  done
  [ "$ready" -eq 1 ] || { echo 'Manager readiness timed out.' >&2; return 1; }
  for service in xema-fastagi xema-astermq xema-simplecdr xema-bff xema-ava xema-sipper xema-metrics; do
    if systemctl cat "$service" >/dev/null 2>&1; then
      if ! systemctl is-active --quiet "$service"; then started_workers+=("$service"); fi
      if ! systemctl is-enabled --quiet "$service"; then enabled_workers+=("$service"); fi
      systemctl enable --now "$service"
      systemctl is-active --quiet "$service"
    fi
  done
  sleep 5
  for service in xema-fastagi xema-astermq xema-simplecdr xema-bff xema-ava xema-sipper xema-metrics; do
    systemctl is-active --quiet "$service" || { echo "Auxiliary service did not stay running: $service" >&2; return 1; }
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

  if ! check_websocket_module; then
    echo "Asterisk websocket module verification failed." >&2
    exit 1
  fi

  echo "XEMA workflow install completed successfully."
}

download_package
if [ "$VERIFY_ONLY" -eq 1 ]; then
  echo 'Package verified without installing, restarting services or running the base installer.'
  exit 0
fi
preflight
run_base_install
deploy_workflow_package
verify_install

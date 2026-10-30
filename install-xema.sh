#!/usr/bin/env bash
set -Eeuo pipefail

channel=production
channel_selected=0
verify_only=0
workdir=''

usage() {
  printf '%s\n' 'XEMA full fresh installation: Ubuntu Server 24.04 AMD64.' \
    'Default: frozen production baseline. -d / --dev: isolated dev/staging.' \
    '--verify-package-only: download/check only; never install or restart.' \
    'Site IP/DNS and trusted SIP networks are requested through /dev/tty.' \
    'This is not an existing-site upgrade command.'
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -d|--dev|--production)
        [ "$channel_selected" -eq 0 ] || { echo 'Select only one install channel.' >&2; return 1; }
        channel_selected=1
        if [ "$1" = --production ]; then channel=production; else channel=dev; fi
        ;;
      --verify-package-only) verify_only=1 ;;
      -h|--help) usage; exit 0 ;;
      *) echo "Unsupported option: $1" >&2; return 1 ;;
    esac
    shift
  done
}

select_channel() {
  # Independent pins: updating dev must never move the production baseline.
  case "$channel" in
    production)
      release=20261030-RC1
      release_url=https://raw.githubusercontent.com/70101520/xemainstaller/090b24e91b17be0c8ee8d3b1c422729567e8a4a9/releases/20261030-rc1
      launcher_sha=55aa1ecff18d6f3578ebe543c52dbe797188e60670eedeeedaaad92cc9c06b1d
      package_sha=8e4e331654dc44a47dd91c9cbbe76b885c8f3492b69d5ba9f3be97fa89c79e52
      ;;
    dev)
      release=20261030-RC1-test
      release_url=https://raw.githubusercontent.com/70101520/xemainstaller/090b24e91b17be0c8ee8d3b1c422729567e8a4a9/releases/20261030-rc1
      launcher_sha=55aa1ecff18d6f3578ebe543c52dbe797188e60670eedeeedaaad92cc9c06b1d
      package_sha=8e4e331654dc44a47dd91c9cbbe76b885c8f3492b69d5ba9f3be97fa89c79e52
      ;;
    *) echo 'Unknown install channel.' >&2; return 1 ;;
  esac
}

check_install_host() {
  [ "$(id -u)" -eq 0 ] || { echo 'Run through sudo bash.' >&2; return 1; }
  . /etc/os-release
  [ "$ID" = ubuntu ] && [ "$VERSION_ID" = 24.04 ] && [ "$(uname -m)" = x86_64 ] || {
    echo 'Fresh installation requires Ubuntu Server 24.04 AMD64.' >&2; return 1;
  }
  if [ -e /etc/asterisk ] || [ -e /etc/xema/install-secrets.json ] ||
     [ -e /var/lib/xema/manager/appsettings.json ]; then
    echo 'Existing PBX/XEMA found: fresh installation refused. Do not delete site files to bypass this guard.' >&2
    return 1
  fi
}

read_setting() {
  local name="$1" prompt="$2" value
  if [ -n "${!name:-}" ]; then return 0; fi
  if ! read -r -p "$prompt" value < /dev/tty; then
    echo "Missing $name: use an interactive terminal or explicitly supply the site environment settings." >&2
    return 1
  fi
  [ -n "$value" ] || { echo "$name cannot be empty." >&2; return 1; }
  printf -v "$name" '%s' "$value"
}

prepare_settings() {
  XEMA_PUBLIC_HOST="${XEMA_PUBLIC_HOST:-${XEMA_SERVER_IP:-}}"
  XEMA_SIP_CIDRS="${XEMA_SIP_CIDRS:-}"
  if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != root ]; then
    XEMA_INSTALL_ADMIN="$SUDO_USER"
  else
    XEMA_INSTALL_ADMIN="${XEMA_INSTALL_ADMIN:-}"
  fi
  read_setting XEMA_PUBLIC_HOST 'Server IP/DNS (without https://): '
  read_setting XEMA_SIP_CIDRS 'Trusted SIP-provider/LAN/VPN CIDRs, comma-separated: '
  read_setting XEMA_INSTALL_ADMIN 'Existing Linux administrator username: '
  export XEMA_PUBLIC_HOST XEMA_SIP_CIDRS XEMA_INSTALL_ADMIN
}

confirm_rollout() {
  local answer
  if [ "$channel" = dev ]; then
    echo 'DEV/STAGING selected. Do not use on a live customer server.' >&2
    return 0
  fi
  echo 'Production baseline RC1: clean-install/recovery acceptance and Agent/Live heartbeat / auxiliary worker metadata gaps remain open.' >&2
  echo 'This fresh rollout is your explicit decision; the package is not certified production-qualified.' >&2
  if [ "${XEMA_ACCEPT_KNOWN_RISKS:-}" = 1 ]; then return 0; fi
  if ! read -r -p 'Type INSTALL to accept these known risks and continue: ' answer < /dev/tty; then
    echo 'Explicit rollout acceptance required; nothing installed.' >&2
    return 1
  fi
  [ "$answer" = INSTALL ] || { echo 'Installation cancelled; nothing installed.' >&2; return 1; }
}

ensure_dependencies() {
  if ! command -v python3 >/dev/null 2>&1 || [ ! -s /etc/ssl/certs/ca-certificates.crt ]; then
    if [ "$verify_only" -eq 1 ]; then
      echo 'Verification requires python3 and trusted CA certificates; no packages were installed.' >&2
      return 1
    fi
    apt-get update
    apt-get install -y python3 curl ca-certificates
  fi
  local command
  for command in curl tar sha256sum systemctl python3 getent; do
    command -v "$command" >/dev/null 2>&1 || { echo "Missing required command: $command" >&2; return 1; }
  done
}

validate_settings() {
  python3 - "$XEMA_PUBLIC_HOST" "$XEMA_SIP_CIDRS" "$XEMA_INSTALL_ADMIN" <<'PY'
import ipaddress, re, sys
host, cidrs, admin = sys.argv[1:]
if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9.-]*', host):
    raise SystemExit('Invalid server IP/DNS; do not include https:// or a path.')
entries = cidrs.split(',')
if not cidrs.strip() or any(not entry.strip() for entry in entries):
    raise SystemExit('Trusted SIP CIDRs must be explicitly supplied without empty entries.')
try:
    networks = [ipaddress.ip_network(entry.strip(), strict=False) for entry in entries]
except ValueError:
    raise SystemExit('Invalid SIP CIDR; use actual provider IP /32 and authorized LAN/VPN networks.')
if any(network.prefixlen == 0 for network in networks):
    raise SystemExit('Unrestricted SIP access (0.0.0.0/0 or ::/0) is refused.')
if not re.fullmatch(r'[A-Za-z_][A-Za-z0-9_.-]*\$?', admin):
    raise SystemExit('Invalid Linux administrator username.')
PY
  getent -- passwd "$XEMA_INSTALL_ADMIN" >/dev/null || {
    echo 'Administrator must be an existing Linux account; no account/password is created by this prompt.' >&2
    return 1
  }
}

cleanup() {
  if [ -n "$workdir" ]; then rm -rf -- "$workdir"; fi
}

run_launcher() {
  local launcher="$workdir/install-xema-workflow.sh"
  curl -fLsS --retry 3 --connect-timeout 15 --proto '=https' --tlsv1.2 \
    "$release_url/install-xema-workflow.sh" -o "$launcher"
  printf '%s  %s\n' "$launcher_sha" "$launcher" | sha256sum -c -
  local args=(--package-url "$release_url/xema-workflow-linux-x64.tgz" --package-sha256 "$package_sha")
  if [ "$channel" = production ]; then args+=(--accept-unqualified-production); else args+=(--staging); fi
  if [ "$verify_only" -eq 1 ]; then args+=(--verify-package-only); fi
  bash "$launcher" "${args[@]}"
}

main() {
  parse_args "$@"
  select_channel
  printf 'XEMA channel: %s | release: %s\n' "$channel" "$release"
  if [ "$verify_only" -ne 1 ]; then
    check_install_host
    prepare_settings
    confirm_rollout
  fi
  ensure_dependencies
  if [ "$verify_only" -ne 1 ]; then validate_settings; fi
  workdir="$(mktemp -d /tmp/xema-bootstrap.XXXXXX)"
  trap cleanup EXIT
  run_launcher
}

main "$@"

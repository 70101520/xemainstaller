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
    'Local IP/certificate and sudo-user/root Admin are selected automatically.' \
    'Netplan, VPN, routing and existing firewall policy are not changed.' \
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
      release=20261030-RC1-install2
      release_url=https://raw.githubusercontent.com/70101520/xemainstaller/xema-install-20261030-2/releases/20261030-rc1-install2
      launcher_sha=926ce0e00fb91ea9c240287c6aeb89fee46630ea137d6b96401e505a475842d6
      package_sha=56ead83ba4d6165b4cade0a2fd0e3757345e64718628c8f5201ea235be5b8c03
      ;;
    dev)
      release=20261030-RC1-install2-test
      release_url=https://raw.githubusercontent.com/70101520/xemainstaller/xema-install-20261030-2/releases/20261030-rc1-install2
      launcher_sha=926ce0e00fb91ea9c240287c6aeb89fee46630ea137d6b96401e505a475842d6
      package_sha=56ead83ba4d6165b4cade0a2fd0e3757345e64718628c8f5201ea235be5b8c03
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

prepare_settings() {
  export XEMA_FIREWALL_MODE="${XEMA_FIREWALL_MODE:-preserve}"
  case "$XEMA_FIREWALL_MODE" in
    preserve) ;;
    managed)
      [ -n "${XEMA_SIP_CIDRS:-}" ] || { echo 'Managed firewall mode requires XEMA_SIP_CIDRS.' >&2; return 1; }
      ;;
    *) echo 'XEMA_FIREWALL_MODE must be preserve or managed.' >&2; return 1 ;;
  esac
  echo 'Netplan/VPN/routing are manual. Existing firewall policy is preserved unless managed mode was explicitly configured.'
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
  workdir="$(mktemp -d /tmp/xema-bootstrap.XXXXXX)"
  trap cleanup EXIT
  run_launcher
}

main "$@"

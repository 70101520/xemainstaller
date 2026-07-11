# XEMA Workflow Installer

One-command installer for the XEMA workflow build maintained from:

- Source repo: `https://github.com/70101520/XEMA_MAIN`
- Source branch: `XEMA_WORKFLOW`
- Installer repo: `https://github.com/70101520/xemainstaller`

## Install

Run on a fresh Ubuntu 22.04 XEMA server:

```bash
curl -fsSL https://raw.githubusercontent.com/70101520/xemainstaller/main/install-xema-workflow.sh | sudo bash -s -- -d -vvv
```

The script first runs the official XEMA base installer, then applies the XEMA workflow package from this repo.

## Upgrade Existing Base Install

If the official base install is already done:

```bash
curl -fsSL https://raw.githubusercontent.com/70101520/xemainstaller/main/install-xema-workflow.sh | sudo bash -s -- --skip-base
```

## What It Does

- Runs the official installer from `xema-in/install`.
- Backs up `/var/lib/xema/manager` to `/root/xema-manager-backup-<timestamp>`.
- Deploys the self-contained Linux x64 Manager package.
- Preserves local `appsettings*.json`.
- Deploys real `agent`, `admin`, and `live-view` web assets.
- Applies WebRTC runtime prerequisites:
  - Asterisk websocket modules.
  - TLS certificate files.
  - nginx `/ws` proxy.
  - self-contained `xema-manager` systemd override.
- Restarts `asterisk` and `xema-manager`.
- Verifies service status and checks that stub UI pages were not deployed.

## Update Package

When `XEMA_MAIN` changes:

1. Build a new `packages/xema-workflow-linux-x64.tgz`.
2. Update `PACKAGE_SHA256` in `install-xema-workflow.sh`.
3. Commit and push this installer repo.

## Rollback

If the upgrade phase fails, the script attempts to restore the backup automatically.

Manual rollback example:

```bash
sudo systemctl stop xema-manager
sudo rm -rf /var/lib/xema/manager
sudo cp -a /root/xema-manager-backup-YYYYMMDD-HHMMSS /var/lib/xema/manager
sudo rm -f /etc/systemd/system/xema-manager.service.d/self-contained.conf
sudo systemctl daemon-reload
sudo systemctl start xema-manager
```

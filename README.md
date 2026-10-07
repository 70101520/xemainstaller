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

The script downloads and verifies the workflow package before running the official
XEMA base installer, then applies the verified package. Use a maintenance window;
the full installer restarts Asterisk and Manager. Do not run it over live calls.

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
- Deploys real `agent`, `admin`, `live-view`, and `data-portal` web assets.
- Includes the responsive Xema landing and redesigned Admin sign-in page.
- Includes the VM-tested AdminUI1 native CPU/RAM/disk, service, call/agent and
  floor-activity dashboard. No additional monitor is required for this page.
- Its side lists show only the verified Xema components: AsterMQ, FastAGI,
  Manager and Simple CDR. Supporting software and the absent BFF placeholder
  are not shown there; no server dependency is uninstalled.
- Applies the Admin allowlist/password policy, secure cookies, explicit CORS
  origins and authenticated diagnostic access from the tested source.
- Applies WebRTC runtime prerequisites:
  - Asterisk websocket modules.
  - TLS certificate files.
  - nginx `/ws` proxy.
  - self-contained `xema-manager` systemd override.
- Restarts `asterisk` and `xema-manager`.
- Verifies service status and checks that stub UI pages were not deployed.

## Update Package

Required order when `XEMA_MAIN` changes:

1. Back up, deploy and test the affected workflow on the test VM. Do not publish a failed or deferred change.
2. Commit/push the verified source only to `XEMA_MAIN`'s `github/XEMA_WORKFLOW`; never contact its official Azure `origin`.
3. Build `packages/xema-workflow-linux-x64.tgz` from the same tested backend/portal artifacts, using `deploy/Build-XemaWorkflowPackage.ps1` in the source repo.
4. Verify archive contents, absence of site settings/secrets and SHA256. Update `PACKAGE_SHA256` in `install-xema-workflow.sh`.
5. Commit/push the launcher and matching archive together to this user's own installer GitHub repo. Its `origin` is GitHub, not the source repo's Azure remote.

## Tested Package: 2026-10-07

- Source commit: `25b4301a` on `XEMA_MAIN/XEMA_WORKFLOW`.
- Archive SHA256: `558fb8c08595664fb7a5a79adb2678e13b40635c12f087e4ec2ce39b53386773`.
- Manager SHA256: `6bc94c11e4c817e036c16add3c8467c5400502c49e8db93860d776d48ffd90b8`.
- Existing VM deployment, 58 focused backend tests, 9 dashboard data/polling tests,
  4 Angular/Chrome tests, inherited 11 Live View regressions and 14 actual Admin dashboard
  desktop/mobile viewport checks passed. RAM/disk/service states were compared
  with the OS, configured-agent counts with the existing API; read-only Admin
  navigation and login/security regressions also passed.
- Archive integrity, path safety, exact tested Manager/Admin artifacts and absence
  of site settings/keys were checked. Landing/login/other portals and Manager
  dependencies match the previous release. See source
  `docs/ADMIN_SYSTEM_DASHBOARD_20261007.md` for backup and metric semantics.
- The service-list follow-up changed only Admin static files; the VM needed
  no service restart. Backend/config/other-portal hashes and service invocation
  IDs matched before and after deployment.
- The full clean-machine installation was not executed. Client TLS trust and
  remaining dependency advisories are documented in the source security notes.
- Fresh Admin access defaults to the installing sudo user and root. An
  SSH-key-only user needs an explicitly configured OS password; no default
  Admin password is created. See source `docs/PORTAL_SECURITY_FIX_20261007.md`.

## Rollback

If the upgrade phase fails, the script attempts to restore Manager and the backed
up runtime/security configuration automatically. Retain both the Manager backup
and its `-config` companion directory, root-only; they contain site secrets.

Manual recovery needs the matching Manager and config backup, an active-call
check and review of the target paths/services. Do not restore an older backend
casually: a pre-security-fix backup also restores its original vulnerabilities.

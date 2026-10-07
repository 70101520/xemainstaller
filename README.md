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
- Includes protected Delete actions for stopped dialers and unlinked datasets.
  Delete archives the configuration; uploaded rows, batches, caches, dialplan and
  CDR history remain safe. Active/linked/uploading items are blocked. Archived
  dialer names remain reserved; a new dialer uses a new name.
- Adds the nullable archive columns automatically through normal Manager
  migrations on existing and fresh installations; no site-specific SQL is needed.
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

- Source commit: `f5a195f1` on `XEMA_MAIN/XEMA_WORKFLOW`.
- Archive SHA256: `57e065a20c776d204ca19dbff772fd4154fdcae299f05b9c07b448cba20a4c23`.
- Manager SHA256: `60f838846270ee313b97df25aa7802db18826dc13b37c2e6aa2f00d2aa44531c`.
- DbV2 SHA256: `33d782ca434530b406e0026871c8305b283a34c6abdaf018b3f0e2d127bb32bc`.
- Existing VM deployment, 83 focused backend tests, 9 dashboard data/polling tests,
  13 Angular/Chrome tests and 11 local/actual-VM desktop/mobile viewports per
  deletion list passed. The actual VM API/DB test used uniquely named, stopped,
  pace-zero fixtures, without placing a call. It checked upload/append/cache refresh,
  authorization/CSRF, active and linked deletion guards, stale IDs and retained
  row/batch/column/CDR checksums; the user's original records remained unchanged.
- Archive integrity, path safety, exact tested Manager/Admin artifacts and absence
  of site settings/keys were checked. Landing/login/other portals and Manager
  dependencies match the previous release. See source
  `docs/ADMIN_DIALER_DATASET_DELETE_20261007.md` for deletion/retention semantics,
  migration behavior and SQL/binary backups. The native dashboard/service-list
  implementation and its prior verification are retained.
- This release restarted only Manager after two zero-channel checks. Site settings,
  landing/login/other portals, TLS, nginx and Asterisk configuration hashes were
  unchanged. Asterisk and nginx were not restarted.
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

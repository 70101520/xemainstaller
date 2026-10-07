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
- Includes a compact Dataset/Batches/File format view with actual uploaded-record
  summaries, configured duplicate-check status, independent table sorting and
  responsive loading/error/retry states. Existing CSV mapping, batch upload,
  dialer selection and protected Delete behavior are preserved.
- Includes controlled manual Rechurn for verified No Answer/Busy/Not Reachable
  outcomes, batch selection, preview, retry limits/wait interval and cancellation.
  Called flags and CDR history are retained; queuing never starts the dialer.
  Attempt history is additive. Unknown/legacy outcomes are not guessed.
  Test=Target uses Target only; initial uploaded/pending/attempted counts differ.
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

- Source commit: `5789579e` on `XEMA_MAIN/XEMA_WORKFLOW`.
- Archive SHA256: `8010db3076211faf930921f8e8605c81219efa6e9ec5906b0d0cef86e8b032a4`.
- Manager SHA256: `c199a707f73940f3f5970ef53807149baec2150b08f61ac0320dac43cad6155e`.
- DbV2 SHA256: `50d3a46fb18f9f5efda612e1c32186513f020c3553a30864743470ccc230d0ba`.
- 104 focused backend, 34 Angular/Chrome and 9 dashboard Node checks passed.
  Dialer passed 11 local/actual-VM viewports including loading/error/recovery.
  Actual VM datasets/detail and safe-deletion cancellation regressions passed.
- 21 actual VM MariaDB fixture checks covered claims, retry filters/budget,
  queue idempotency, due-time gating, cancellation/rescheduling and per-attempt
  CDR/recording correlation. Fixtures were cleaned and existing CDR count and
  duration totals were unchanged. No actual outbound calls were placed.
- Archive integrity, path safety, exact tested Manager/Admin artifacts and absence
  of site settings/keys were checked. Landing/login/other portals and Manager
  dependencies match the previous release. See source
  `docs/DIALER_RECHURN_20261007.md` for current retry behavior/acceptance gaps and
  backups; `docs/ADMIN_DIALER_DATASET_DELETE_20261007.md` retains the previous
  deletion/retention, migration and SQL/binary-backup notes.
- Manager was restarted with backup and empty active-channel checks.
  The additive attempt-history table was applied by normal migrations. Landing,
  other portal assets, site settings, TLS, nginx and Asterisk configuration were
  preserved; Asterisk was not restarted.
- Actual trunk-to-Agent dialing, recording playback and corresponding Data
  Portal/Live activity acceptance remain pending the user's laptop test.
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

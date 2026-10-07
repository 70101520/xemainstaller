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
- Includes readable Live View Normal/Dark/Auto monitor tabs, tables, status
  buttons and counters, with theme controls on Dashboard and Real Monitor.
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
- Maps direct SIP phone outbound CLI/DNI/phone and recording from the same linked
  originating leg without inventing an Agent/Dialer. The primary native CallId,
  report SQL/calculations and historical rows are preserved. Data Portal includes
  visible recording controls, unmuted native audio and download/playback errors.
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

- Source commit: `39b1d26b` on `XEMA_MAIN/XEMA_WORKFLOW`.
- Archive SHA256: `ee4807c581542c80ffc2f1274c3d25861327a39dd92324776bfefb5b03040f27`.
- Archive size: 63,129,956 bytes; 645 verified files.
- Live View theme fix: 10 focused Angular checks passed. Actual VM public assets
  passed contrast, hover and layout checks at 1366/768/390/320px across Dashboard
  and Team/Queues/Dialers/Wall monitor views. Auto boundaries at 06:00/18:00,
  manual modes, login day/night and error/recovery states passed. Browser-only
  realtime fixtures were used; no real user session was borrowed and these
  checks do not certify actual live counts. An untouched AppComponent scaffold
  has a private Title access compilation error in the full spec suite; the
  isolated focused theme suite passed. See source
  `docs/LIVE_VIEW_THEME_FIX_20261007.md`.
- Live View main bundle: `main-6T3NS2VL.js`, SHA256
  `db98cb4f85386ae38d7b094e6847dc1ae010b1ef748bf796cf77c9f8fc85c577`.
  CSS: `styles-2FIFOUKQ.css`, SHA256
  `e230b2db243c3ff8b3ca6cd0283a93d8a47ecab0e1cdb11988bb6758b16fd49b`.
  Only static Live View assets were deployed for this release; no services
  restarted. Original rollback: `/root/xema-live-view-20261007-135228`.
  Backend, report calculations, dialer logic and other portals are unchanged.
- The following Test call/CDR/Rechurn results are retained from prior releases,
  not claimed as newly rerun for the theme-only change.
- Manager SHA256: `9463aa9b2e786f9f0b66f93a51d65cce62cab128017508a55b0335aefd534479`.
- DbV2 SHA256: `50d3a46fb18f9f5efda612e1c32186513f020c3553a30864743470ccc230d0ba`.
- 120 focused backend and 34 focused Admin Angular checks passed. Three untouched
  legacy dataset scaffold tests failed for missing HttpClient providers in a
  broader run; they are not claimed as passing.
- Test call no longer requires a dataset Batch. It uses a dedicated validated
  ID/number request with Admin CSRF and stopped-engine protection. Backend and
  UI failures are explicit; reload older Admin tabs to pick up the protected flow.
  Actual VM auth/CSRF/validation checks and dialog/error states at three screen
  sizes passed. Dataset readonly regression passed at 11 screen sizes.
- One real VM button Test call to the authorized MicroSIP `9001` connected:
  CDR `1791378647.122`, Out/CLI1234/DNI9001/Balaram/Phone1001/Dialer5/Recorded1.
  Its recording was valid GSM and stayed on the VM. Campaign progress remained
  2 attempted / 0 pending, with two Answered retry-history entries. No Called
  reset or rechurn was performed. See source `docs/DIALER_TEST_CALL_FIX_20261007.md`.
- The previous eight recording/report Angular checks and five desktop/mobile
  VM-asset playback/error/download fixture checks are retained. The user has
  now separately confirmed authenticated Data Portal playback is working.
- A real user manual `1001 -> 9001` call after deployment saved correct CLI/DNI,
  phone, outbound direction and recording path without an invented Agent/Dialer.
  Two existing completed OBD rows were confirmed in both the database and the
  user's downloaded Outbound CSV. A configured missing DNIS export column is
  not silently added; owners still control their report configuration.
- In the previous Rechurn release, 21 actual VM MariaDB fixtures covered claims, retry filters/budget,
  queue idempotency, due-time gating, cancellation/rescheduling and per-attempt
  CDR/recording correlation. Fixtures were cleaned and existing CDR count and
  duration totals were unchanged. That fixture run did not place actual calls.
- Archive integrity, path safety, exact tested Manager/Live View/retained VM DbV2
  artifacts and absence of site settings/keys were checked. Landing/login,
  Agent/Admin/Data Portal and Manager dependencies match the previous release.
  The previous package's actual DbV2 hash differed from its manifest; this
  archive and manifest are aligned to the actual retained VM binary. See source
  `docs/MANUAL_CDR_RECORDING_FIX_20261007.md` for this fix/verification and
  `docs/DIALER_RECHURN_20261007.md` for retained retry behavior/acceptance gaps and
  backups; `docs/ADMIN_DIALER_DATASET_DELETE_20261007.md` retains the previous
  deletion/retention, migration and SQL/binary-backup notes.
- For the prior Test call release, Manager was restarted with backup and empty active-channel checks.
  The previous additive attempt-history migration is retained. Landing/other
  portal assets, site settings, TLS, nginx and Asterisk configuration were
  preserved; Asterisk was not restarted. Historical CDR rows were not rewritten.
  No new migration was needed for the Test call fix.
- Broader end-to-end retry and QMon predictive acceptance remain separate tests;
  the actual test campaign is Simple Dialer, not QMon.
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

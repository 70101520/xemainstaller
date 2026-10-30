# Working Hold Checkpoint: Staging Only

This archive saves the current tested work. It is not the production-default
installer, a client handover approval, or clean-machine installation acceptance.
The existing root launcher and `packages/` release pair are not replaced.

Source: `70101520/XEMA_MAIN`, branch `XEMA_WORKFLOW`, commit
`b59f2409446e784411730686d8cf50b603bc03d3`.
Source evidence: `docs/DELIVERY_CHECKPOINT_20261030.md` and
`docs/NATIVE_HOLD_20261030.md` in that commit.

## Included

- Exact staging-tested Manager and Agent/Live portal artifacts; installed
  runtime/dependencies and the published Admin/Data Portal baseline retained.
- Native Asterisk Hold/Unhold source and matching-header build helper. Fresh
  dependencies include asterisk-dev, gcc and libc6-dev. No precompiled module
  is assumed compatible with another Asterisk build.
- Self-contained .NET 10.0.14, EF10/MariaDB provider checkpoint, reviewed
  bootstrap/runtime helpers and payload qualification manifest.
- No site appsettings, private keys, passwords, logs, CDR rows or call audio.

Archive SHA256:
`7cb48438d99684c60ff485ef5b709af831f0f686e6381b41685c8c6945f1c307`.
Matching launcher checksum and archive are published together. `SHA256SUMS`
also covers the launcher itself.

## Verified Boundary

196 compiled Linux backend assertions, 31 shared-client checks, six native AMI
protocol checks, 13 mocked bootstrap guards, 21 package checks, 26 staging
verify-only/call-safety checks and 40 read-only service/auth/exposure checks.
604 effective application/runtime/portal files match the staging VM; Manager
debug symbols match the new assembly instead of its retained old VM symbols.
The native module also compiled directly from this final archive on staging.

The user confirmed native Hold/Resume worked. Call 1793340371.347 saved one
agent leg, Talk=16s, Hold=15s, Agent=31s, Total=32s, one Hold and Recorded=1.
Actual recording search/playback/download and Chrome audio playback passed;
anonymous recording access was denied. No historical report calculation changed.

## Verification Only

On an approved Ubuntu test host, after obtaining this directory's files:

```bash
sha256sum -c SHA256SUMS
bash install-xema-workflow.sh --staging --verify-package-only \
  --package-file xema-workflow-linux-x64.tgz \
  --package-sha256 7cb48438d99684c60ff485ef5b709af831f0f686e6381b41685c8c6945f1c307
```

This command does not install, restart services or place calls. Without
`--staging`, the launcher rejects this package. Do not bypass the qualification
gate or use `--staging` to relabel a production/customer server as a test server.

## Pending Before Production

Auxiliary SimpleCdrWorker/Sipper schema access and Ava ARI credentials require
their separately authorized fixes. Real Data Portal report/CSV acceptance needs
the user's manual report configuration. Complete remaining OBD/hold-recovery/
privacy checks, uninterrupted clean installation, backup/restore/reboot and
actual provider acceptance. The small staging VM does not qualify 500-call load.

No functional VM code/config was changed while saving this snapshot. Future
fixes must be verified on staging and saved with another matching archive and
launcher checksum. Do not overwrite this dated checkpoint in place.

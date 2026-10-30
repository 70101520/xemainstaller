# Worker Prerequisites Checkpoint: Staging Only

This snapshot fixes worker schema access and Ava ARI credential mapping. It
does not replace the root production-default installer or certify a client
handover/clean-machine installation.

Source: `70101520/XEMA_MAIN`, branch `XEMA_WORKFLOW`, commit
`3da9d81fdd5629ce49a62808d722e00cfb6ed26b`.
Evidence: `docs/WORKER_PREREQS_FIX_20261030.md` in that commit.

## Fix

Fresh setup now includes `SimpleCdrWorker` and `Sipper` alongside the existing
application schemas, with schema-scoped `xema@localhost` grants. No global
privilege or password rotation is added. Existing Ava `Ari` options receive
the generated PBX credentials; app/port/AudioSocket options remain unchanged.
The guarded staging repair utility is also included in `deploy/`.

Backend and portal artifacts are identical to the preceding native Hold
checkpoint. No Manager, Asterisk, Agent/Live, SIP/trunk or report-calculation
code was rebuilt/changed to repair these prerequisites. No site configuration,
password, backup SQL, CDR rows or call recording is included.

## Actual Verification

- 23 mocked/pure installer/repair checks passed locally and on staging.
- 35 functional/preservation checks passed: both schemas migrated, worker
  grants verified, Ava's actual ARI app registered, anonymous ARI denied,
  Sipper DB API 500 resolved to 200, historical CDR/protected files unchanged.
- Real local call 1793348181.404 saved authoritative Balaram/1004 CDR with
  Talk9s/Hold7s/one Hold, Recorded1; actual 16.86-second recording search,
  playback/download and Chrome audio playback passed.
- 21 local package checks and 26 staging verify-only/call-safety checks passed.
  Packaged bootstrap/repair code matches the actual staging-tested source.

## Open Compatibility Gap

The separate auxiliary worker now ingests/saves the same call, but its row
has missing AgentId and Hold metadata. The authoritative legacy `SimpleCdr`
row remains correct. Do not switch reports to `SimpleCdrWorker`, rewrite either
history or claim full report parity. A separate reviewed Manager/worker event
interop correction and regression test is still needed.

Sipper capture stayed idle; packet capture was not automatically enabled. Ava
ARI connectivity is not AI-conversation acceptance. Full OBD/hold-recovery/
privacy, manual report configuration, clean installation, recovery/reboot and
actual provider/load acceptance remain open. Production approval is still false.

## Verification Only

```bash
sha256sum -c SHA256SUMS
bash install-xema-workflow.sh --staging --verify-package-only \
  --package-file xema-workflow-linux-x64.tgz \
  --package-sha256 290482a537c096d130ec78dcf3b9864b33e311011b96b824d84063cbedb58a6d
```

This verifies without installing, restarting services or placing calls. The
launcher rejects this archive in production mode. Never bypass the gate by
calling a customer/production server staging. The previous dated Hold snapshot
and production-default files are retained unchanged.

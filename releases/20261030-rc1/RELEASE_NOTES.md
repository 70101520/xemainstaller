# XEMA 20261030-RC1 Freeze

The operator requested freezing the current build for a direct fresh production
rollout instead of waiting for another clean staging installation. This records
that decision, not a passed clean-install or production qualification.

## Frozen Payload

- Runtime/application source checkpoint: `7a6b8358e0ee04ac71cea776a55a82714a37f2c3`.
- Branch/remote: `XEMA_WORKFLOW`, user-owned `github` only. Never contact Azure.
- Installer directory: `releases/20261030-rc1/` in the user's installer repository.
- Reuse the exact `20261030-legacy-report` archive; no backend/portal rebuild.
- Archive SHA256: `8e4e331654dc44a47dd91c9cbbe76b885c8f3492b69d5ba9f3be97fa89c79e52`.
- Manager SHA256: `351606e4369dc59d27f339529443148ed14cd62f8b2f3a0d82dfde8fc9b2d9c4`.
- .NET runtime 10.0.14, EF Core 10.0.14 / Microting MySQL provider 10.0.13.
- Package manifest remains `productionApproved=false`, `qualification=staging-only`.

## Actual OBD Observation

On staging `192.168.252.131`, the operator triggered campaign `testd` (Id 6),
batch 28. This inspection did not originate calls, reset rows or change schedules.
The initial read-only snapshot reported `Outside schedule`; a later operator
configuration created `DIALER-6` and one actual campaign attempt originated.

- CallId `1793362329.461`, outbound, DialerId 6, Balaram / phone 1004.
- Final attempt: `Answered`, disconnect code 16, one attempt, no queued/in-flight
  claim left. Cache Called=1, pending=0; dialer subsequently observed Active=0.
  This does not independently prove the operator did not stop it manually.
- Original `SimpleCdr.Calls`: AgentTime 93, TalkTime 93, HoldTime 0,
  ConnectedTime 94, QueueTime 1, Recorded=1.
- GSM recording exists, 153153 bytes, SHA256
  `93652367cec6ccf994d82822b0f53aa7cd0ff8586df8cca914181c83cc11a20e4`.
  Playback for this new outbound call was not verified in the portal.
- Asterisk ended at zero active channels/calls. No Manager/Asterisk restart,
  report SQL change or manual database change was made by this inspection.

Earlier native Hold and original manual Inbound CDR/CSV/playback acceptance are
in `NATIVE_HOLD_20261030.md` and `LEGACY_INBOUND_CDR_20261030.md`.

## Known Open Gaps

- AgentHub heartbeat timeouts/reconnects occurred during the observation window;
  uninterrupted Agent/Live recovery is not qualified.
- Auxiliary `SimpleCdrWorker.Calls` still lacks AgentId on the outbound call.
  Earlier Hold calls also have different Hold/Talk metadata there. Do not switch
  existing reports away from the original `SimpleCdr.Calls` or backfill history.
- Manager logged `Agent Break Information Lost`, unhandled AMI event notices and
  an external licensing/DNS job failure. These are not declared resolved.
- A complete uninterrupted install of this exact archive on a new Ubuntu 24.04
  machine, reboot recovery, full backup/restore, real-provider/SIP/VPN acceptance,
  all Rechurn/failure scenarios and 500-call capacity remain unqualified.

## Explicit Operator Rollout

The paired launcher supports `--accept-unqualified-production` for the requested
fresh rollout. It prints the outstanding risks and preserves the package's
unqualified manifest. Without the flag, normal production qualification still
rejects this candidate. The flag cannot combine with staging, skip-base or
skip-upgrade, and cannot bypass checksum/tree/runtime, existing-site or call guards.
It is not an approval for a future existing-site upgrade or a no-data-loss promise.

The final launcher passed 33 qualification/call-safety checks on the actual
Ubuntu staging VM: default rejection, explicit risk-acceptance verification,
incompatible options, checksum and payload-tamper rejection, and mocked service/
active-call safeguards. No base installation or service restart was run. All 23
local runtime/package checks also passed, including exact backend/portal hashes,
required assets, archive integrity, absence of site settings/keys in the backend,
and rejection of unsupported production qualification. These are verify-only
results, not a completed fresh production installation.

Use only a new Ubuntu 24.04 AMD64 host, the exact frozen launcher/archive/checksum
pair and explicitly trusted SIP-provider/LAN/VPN CIDRs. No production server was
contacted by this freeze task. Site report registration remains manual; the SOUTH
SQL is a reference, not an automatic universal report or production seed.

Future changes require a new version, staging verification, own-GitHub source save
and a matching installer pair. Back up all databases, recordings, uploaded data,
site settings, certificates and Asterisk configuration before any existing-site
maintenance. Application rollback alone is not database/data recovery.

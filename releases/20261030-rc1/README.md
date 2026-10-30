# XEMA 20261030-RC1

Frozen for the operator's requested direct fresh-production rollout. This is
**not production-qualified**: the operator explicitly elects to proceed before
clean-install/recovery and all remaining functional acceptance tests pass.
Read `RELEASE_NOTES.md` for the known heartbeat, auxiliary-worker and other gaps.

Source checkpoint: `d0f301405f273349986f5228dcf3105092a7dcb8` on
`70101520/XEMA_MAIN`, branch `XEMA_WORKFLOW`. Runtime payload remains the exact
tested `7a6b8358` archive; no backend/portal rebuild or report-calculation change.

## Before Installing

- Use a new Ubuntu Server **24.04 LTS AMD64** host, not an existing XEMA/PBX.
- Preserve the old staging VM/snapshot. Back up anything already on the target.
- Use an existing Linux sudo administrator; that user and root become the
  Linux Admin allowlist. Installing from an already-root shell additionally
  requires `XEMA_INSTALL_ADMIN` naming an existing Linux account.
- Decide the actual server IP/DNS and trusted SIP-provider, LAN and VPN CIDRs.
  Include all networks that legitimately register SIP/send RTP. Do not guess
  these networks or use `0.0.0.0/0`; unrelated VPN/network settings are not imported.
- Keep working SSH access and internet access to Ubuntu package repositories
  and the pinned component assets. Review existing firewall/network policy.
- Do not use legacy `-d -vvv`, disable security checks or rerun fresh setup over
  an existing or partially installed site. Stop and inspect a failed install.

## Download And Verify

Run these in a new working directory as the normal Linux sudo user. The
`20261030-rc1` directory is frozen; for reproducible downloads use this installer's
Git commit ID in place of `main` in all three URLs when available.

```bash
curl -fL https://raw.githubusercontent.com/70101520/xemainstaller/main/releases/20261030-rc1/install-xema-workflow.sh -o install-xema-workflow.sh
curl -fL https://raw.githubusercontent.com/70101520/xemainstaller/main/releases/20261030-rc1/xema-workflow-linux-x64.tgz -o xema-workflow-linux-x64.tgz
curl -fL https://raw.githubusercontent.com/70101520/xemainstaller/main/releases/20261030-rc1/SHA256SUMS -o SHA256SUMS
sha256sum -c SHA256SUMS
bash ./install-xema-workflow.sh --verify-package-only --accept-unqualified-production --package-file ./xema-workflow-linux-x64.tgz
```

Expected launcher SHA256:
`55aa1ecff18d6f3578ebe543c52dbe797188e60670eedeeedaaad92cc9c06b1d`.
Expected archive SHA256:
`8e4e331654dc44a47dd91c9cbbe76b885c8f3492b69d5ba9f3be97fa89c79e52`.
Do not continue if either checksum or package verification fails.

## Explicit Fresh Rollout

The prompts below require the real site values, not the staging IP/subnet.
CIDRs are comma-separated, for example individual provider `/32` addresses and
the actual authorized LAN/VPN networks. No passwords are passed in these arguments.

```bash
read -r -p 'Server IP or DNS name (without https://): ' public_host
read -r -p 'Trusted SIP-provider/LAN/VPN CIDRs, comma-separated: ' sip_cidrs
sudo env XEMA_PUBLIC_HOST="$public_host" XEMA_SIP_CIDRS="$sip_cidrs" \
  bash ./install-xema-workflow.sh --accept-unqualified-production \
  --package-file ./xema-workflow-linux-x64.tgz
```

The flag is fresh-only and prints an unqualified-rollout warning. It does not
turn the manifest into `productionApproved=true`, and cannot be combined with
`--skip-base`, `--skip-upgrade` or `--staging`. Checksum/payload/runtime checks,
trusted-network requirements, existing-site refusal and call checks remain.
For isolated staging use `--staging` instead, never both options together.

## Handover Checks

Before giving the client access, check services, all four portal logins, GUI
trunk/IVR routing, SIP registrations, inbound/OBD answer, Hold/Resume, no-answer,
batch/retry behavior, Live values and CDR/recording playback for the same CallId.
The one observed OBD call does not qualify every outbound/failure scenario.

Use each site's original manual report commands. The optional SOUTH reference
SQL is inside the archive at `deploy/sql/`; the installer never executes it.
Existing reports use original `SimpleCdr.Calls`, not the separate auxiliary
`SimpleCdrWorker.Calls`, whose Agent/Hold metadata parity remains open.

Verify licensing/DNS, correct site reporting timezone, HTTPS/client trust and
provider/VPN media paths. Inspect logs, then verify restart/reboot recovery in a
maintenance window. Start with the intended small pilot; 500 calls are not tested.

Do not use this fresh-install risk override for later production upgrades.
Back up all databases, recordings, uploaded data, site settings/certificates and
Asterisk config before maintenance. Rehearse recovery; the application's backup/
rollback is not a full database restore or a zero-data-loss/zero-downtime guarantee.

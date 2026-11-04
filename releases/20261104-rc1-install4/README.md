# XEMA RC1 Install4: Guarded GUI SIP Activation

Fresh Ubuntu Server 24.04 AMD64 only. Do not rerun the fresh installer over a
working production server. This is the user's own tested XEMA package, not a
call to another installer. Existing RC1/install2/install3 snapshots remain intact.

```bash
curl -fsSL https://raw.githubusercontent.com/70101520/xemainstaller/main/install-xema.sh | sudo bash
```

Dev/staging uses the same verified payload with the independent `-d` entrypoint
channel. Network/VPN/routing, site SIP/PJSIP binds, GUI site setup and report SQL
remain manual. Local IP/TLS and installer Admin selection retain prior behavior.

## What Changed

- Admin legacy SIP trunk New/Edit checks idle calls and local/free SIP binds,
  privately backs up modules.conf, persists the choice and loads only chan_sip
  through its native AMI action. No Asterisk restart or shell fallback is added.
- Already-running legacy drivers remain running. PJSIP types bypass activation.
- Conflicts refuse before saving; the Edit UI displays the backend reason.
- All seven trunk names/type codes/driver mappings and registration/dialplan
  templates remain unchanged. See the source [GUI verification record](https://github.com/70101520/XEMA_MAIN/blob/XEMA_WORKFLOW/docs/GUI_LEGACY_SIP_ACTIVATION_REVIEW_20261104.md).

Only Manager.dll, the Admin devices/runtime/index bundle files, the compatibility
guide and the payload manifest differ from install3. All 725 package paths were
compared; other backend/runtime, Agent/Live/Data Portal, workers, Hold source,
manual SQL and deployment helpers remain byte-identical. Tested Manager/Admin
artifacts are reused without rebuilding after VM acceptance.

## Evidence And Limits

Staging actual GUI New/Edit and backend peer checks passed for all seven types;
unsafe legacy New/Edit refused with readable desktop/mobile errors and unchanged
records. Original site files and trunk/DNIS rows were restored after fixture
cleanup. The new Manager/Admin remain on staging; production was not changed.

202 existing Linux assertions, 44 activation assertions, 24 local package checks,
24 Ubuntu entrypoint tests, 33 installer safety tests, 12 module-policy tests and
8 SIP preservation tests passed. The fixture used local test peers only; real
provider registration/RTP, a new clean-machine install, reboot/recovery and
capacity qualification are not claimed. ProductionApproved remains false and
the existing explicit unqualified-rollout warning remains in place.

Disjoint provider/VPN SIP and PJSIP binds are still required. A conflicting
wildcard listener, unavailable VPN IP, custom included policies or legacy TLS
needs review, not a forced load. Activation loads all configured legacy peers,
not merely the edited trunk. Read the packaged compatibility guide.

Verify this immutable snapshot with `sha256sum -c SHA256SUMS`. Exact versions,
source checkpoint and hashes are in [VERSION.txt](VERSION.txt).

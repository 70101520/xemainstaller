# BSNL Module Fix Delivery

## Current Install4 GUI Activation

Source checkpoint pushed to the user's `github/XEMA_WORKFLOW`:
`14dc02fd155869894abba5cd50b69732fe3840e5`.
Matching immutable installer: `xema-install-20261104-4` /
`releases/20261104-rc1-install4`; see its VERSION.txt/SHA256SUMS.

All seven actual Admin trunk New/Edit options passed staging GUI and backend
peer checks. Legacy first-time load uses guarded native AMI ModuleLoad; PJSIP
options bypass that path. A real port conflict refused before record changes,
with readable desktop/mobile errors. Original site files and Trunks/Numbers
rows were restored after fixture Delete; tested Manager/Admin remain on staging.
Production was not contacted or changed for this update.

Final checks: 202 existing Linux assertions, 44 activation assertions, 24 local
package checks, 24 Ubuntu entrypoint tests, 33 installer safety tests, 12 module
policy tests and 8 SIP preservation tests. Full 725-file baseline comparison
allows only the tested Manager/Admin, compatibility guide and payload manifest
changes. Actual provider calls/RTP, clean-machine installation, reboot/recovery
and capacity acceptance were not repeated or certified by this update.

No dropdown mappings, SIP/PJSIP templates, VPN/routes/binds, agent Hold, dialer
scheduling, CDR/report calculations, worker binaries or other portals changed.
Future legacy New/Edit can persist/load the driver when the operator's network
and disjoint SIP/PJSIP binds are ready; custom/unsafe configuration fails for
review rather than forcing a load. Do not reinstall a working production site.

## Earlier Install3 Delivery

Installer payload commit/tag:
`24dd28bcb7fa3313d8fd22be2f2f1b4780785705` / `xema-install-20261104-3`.
Runtime-helper source commit: `c3956cfbf6faebab4d878676dbc331062a43995a`.
Additional source verification notes: `973bb6e937ee9b0a56b11e6222f5a43065acc9c5`.
This note does not change the frozen application or immutable installer artifacts.

Production's explicitly approved VPN-only chan_sip enable/load registered BSNL
and retained the laptop 9001 PJSIP contact, without Manager/Asterisk restart.
Only modules.conf was changed by the operation; unrelated concurrent operator
GUI/dialplan changes were not reverted and no calls were originated or interrupted.

An operator-initiated BSNL inbound call `1793791778.28` matched the existing
SimpleCdr report source: BSNL_SIP, Agent Abhishek, Phone 1001, TalkTime 57,
HoldTime 0, ConnectedTime 66, Recorded 1. The server-local GSM file was 94,842
bytes and decoded successfully to 459,840 samples / 57.48 seconds. It was not
downloaded or played in Data Portal. No CDR/recording data was repaired or changed.

Staging: 81 focused module/SIP/entrypoint/identity/launcher checks, plus actual
published production and dev package verify-only downloads. Windows: 24 exact
runtime/archive checks. All application and portal files remain byte-identical
to frozen RC1. The original RC1/install2 archives and tags were not overwritten.

Still separate: outbound provider calls, operator two-way voice acceptance,
Data Portal playback, reboot/VPN startup ordering, clean-install/recovery and
the known RC1 application qualification gaps. Asterisk was not upgraded;
installed and cached APT candidate versions matched, which is not a security
patch completeness claim. No production fresh reinstall is needed for this fix.

## Staging Deployment Follow-Up

Source `63d1228ccc4a6b62cf67d83434f7a969debd3024` adds the actual isolated Asterisk
regression test and deployment evidence in `docs/BSNL_STAGING_SYNC_20261104.md`.
The exact published deploy-helper tree is now installed on staging under
`/opt/xema/installer/20261104-rc1-install3/deploy` and its helper SHA256 matches
the archive. The test passed again against that deployed helper: actual chan_sip
Running/peer CLI, loopback-only binding, no provider registrations/calls, and
temporary process cleanup. Module/SIP preservation fixtures also passed again.

The main staging PBX was deliberately not given the production legacy load
policy: its existing legacy wildcard bind and BSNL gateway registration entries
need site review to avoid PJSIP conflicts or competing registration. Live staging
configs and Manager/Asterisk PIDs/restart counts were unchanged. No production
connection or change was made during this follow-up.

Install3 already includes the runtime fix/guide; no application or archive bytes
changed for this test/documentation-only follow-up. On a new BSNL legacy site,
configure its VPN and disjoint driver binds, then explicitly enable the module
as described in the guide. The installer preserves that reviewed choice but
does not infer provider settings or automatically enable legacy SIP everywhere.

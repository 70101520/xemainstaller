# BSNL Module Fix Delivery

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

# RC1 Application, Install3 Legacy SIP Policy Preservation

Source: `XEMA_MAIN/XEMA_WORKFLOW` commit
`c3956cfbf6faebab4d878676dbc331062a43995a`.
Immutable installer tag: `xema-install-20261104-3`.

The backend and all four portals are byte-identical to the frozen modified
XEMA RC1 build. From install2, only the runtime helper, a manual legacy SIP
guide and the payload manifest changed. No provider settings/secrets are shipped.

The helper preserves explicitly enabled chan_sip policies instead of disabling
them during WebRTC setup. Fresh PJSIP-only defaults remain unchanged and active
load/noload conflicts are rejected without writing. Existing legacy BSNL/TATA
trunks require Asterisk 20's module and reviewed disjoint driver binds. See
`deploy/asterisk/LEGACY_SIP_COMPATIBILITY.md` in the archive. This is not a PJSIP
migration, driver auto-enable, Asterisk upgrade, VPN or firewall configuration.

The explicitly approved production module-only correction reached BSNL Registered
and peer OK while the laptop 9001 PJSIP contact stayed Avail, without restarting
Manager/Asterisk. The operator reported a successful direct DID inbound call;
Agent, two-way media and recording acceptance remain separate. No call was
initiated by the agent. Concurrent GUI/dialplan edits were not reverted.

Ubuntu staging passed 12 module-policy, 8 SIP preservation, 24 entrypoint,
4 identity-handoff and 33 archive/launcher qualification/call-safety checks.
Windows passed 24 exact runtime/archive checks. These use temporary fixtures
and verify-only paths; no clean-machine installation or reboot test is claimed.
Existing RC1 qualification gaps remain and the manifest stays staging-only.

Use the normal short entrypoint only on a fresh Ubuntu Server 24.04 AMD64 host.
Do not reinstall an existing production site for this correction. Original RC1
and install2 snapshots/tags remain untouched.

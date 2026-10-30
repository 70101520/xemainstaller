# RC1 Application, Install2 Bootstrap

This is the user's frozen modified XEMA application, not the boss's installer.
Only automatic local installation settings and optional firewall preservation
changed. No application/portal files or report calculations changed.

Run the root `install-xema.sh` entrypoint on a fresh Ubuntu Server 24.04 AMD64
host after setting Netplan. It installs the full frozen XEMA stack and local
certificate. Local IPv4/Admin selection is automatic; production retains the
known-risk `INSTALL` acknowledgement. Browsers need explicit certificate trust.

OpenVPN/ISP routes, provider SIP, GUI trunks/agents/IVR and manual report SQL
remain site tasks. Existing firewall policy is preserved by the entrypoint;
review access separately before public exposure. No VPN/routes are modified.

The advanced launcher defaults to managed firewall mode unless called through
the short entrypoint or explicitly given `XEMA_FIREWALL_MODE=preserve`.
Managed mode requires trusted `XEMA_SIP_CIDRS`, never `/0`.

Temporary-fixture/verify-only checks passed on the existing staging VM, plus
23 runtime/package checks. A clean-machine full installation has NOT passed.
Qualification remains staging-only; operator acceptance is not qualification.
Original RC1 paths/tags are not overwritten. See the source repository's
`docs/INSTALLER_AUTO_SETTINGS_20261030.md` for scope/results.

Archive SHA256:
`56ead83ba4d6165b4cade0a2fd0e3757345e64718628c8f5201ea235be5b8c03`.
Advanced launcher SHA256:
`926ce0e00fb91ea9c240287c6aeb89fee46630ea137d6b96401e505a475842d6`.
Immutable tag: `xema-install-20261030-2`.

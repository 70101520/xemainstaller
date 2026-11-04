# One-Command Entry, Version 20261104-3

Production and dev independently pin `xema-install-20261104-3`, paired with the
explicit SHA256 values in `releases/20261104-rc1-install3`. Both retain the exact
frozen modified RC1 application; no backend/portal rebuild was performed.

Install3 preserves an explicit site legacy SIP module load policy and ships the
manual compatibility guide. It does not enable chan_sip by default, change SIP
binds or VPN routes, upgrade Asterisk or run a production reinstall. Existing
local IP/Admin/certificate selection and manual-network behavior remain.

Staging passed 81 focused checks; local runtime/package checks passed 24. A
separately approved production module-only correction registered BSNL and retained
the laptop PJSIP test trunk, without a service restart. This is not fresh-install,
Agent/media/recording, reboot or recovery qualification. See source delivery notes
`docs/BSNL_LEGACY_SIP_FIX_20261104.md` for evidence and remaining checks.

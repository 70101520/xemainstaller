# One-Command Entry, Version 20261030-2

Production/dev independently pin immutable tag `xema-install-20261030-2` and
the launcher/archive hashes in `releases/20261030-rc1-install2`. Both contain
the exact original RC1 application, with the install2 bootstrap-only change.

Local IP/Admin and local certificate are automatic. Existing firewall policy,
Netplan/VPN/routes and site SIP/report setup remain manual. Only the explicit
known-risk `INSTALL` acknowledgement remains on production. Client certificate
trust still needs configuration; this is not public-internet qualification.

Staging: 40 helper, 24 shell/PTY, 4 identity-handoff, 33 launcher and 8 SIP
preservation checks passed. The local package passed 23 runtime/archive checks.
Tests used temp files/read-only detection/verify-only paths, not a live reinstall.
No service restarts, SQL/CDR changes or production access. Clean-machine full
installation, recovery, provider SIP/VPN and capacity acceptance remain open.

Source delivery details: `docs/INSTALLER_AUTO_SETTINGS_20261030.md` in XEMA_MAIN.

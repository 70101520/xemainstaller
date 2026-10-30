# Own XEMA Full-Install Entry

Source: `47a6d1de09b724c1b50d83daadd4d59cddfbfdad`,
`70101520/XEMA_MAIN`, branch `XEMA_WORKFLOW`.
This directory freezes the exact VM-tested `install-xema.sh` published at the
installer repository root. SHA256 is in `SHA256SUMS` and `VERSION.txt`.

## Commands

Fresh production baseline, Ubuntu Server 24.04 AMD64:

```bash
curl -fsSL https://raw.githubusercontent.com/70101520/xemainstaller/main/install-xema.sh | sudo bash
```

Separate fresh dev/staging server:

```bash
curl -fsSL https://raw.githubusercontent.com/70101520/xemainstaller/main/install-xema.sh | sudo bash -s -- -d
```

The entry asks for the site's IP/DNS, actual trusted SIP-provider/LAN/VPN CIDRs,
and an existing Linux Admin if not invoked by a normal sudo user. Questions read
the terminal, not piped script text. Production asks for `INSTALL` confirmation
after its known-gap warning. There are no embedded site credentials.
For review-first use, download and inspect the entrypoint before running it.

The verified package-local base handles dependencies, MariaDB/databases/accounts,
application schema migrations, Asterisk, nginx, Manager, auxiliary workers and
all portals. Site GUI routing/users/phones/IVR and each site's manual report SQL
remain operator configuration. No boss installation script is invoked. Existing
hash-pinned upstream auxiliary binaries remain package dependencies; this does
not claim those workers were rewritten or their metadata gaps resolved.

## Frozen Payload And Channels

Production and dev independently pin installer commit
`090b24e91b17be0c8ee8d3b1c422729567e8a4a9`, the frozen RC1 launcher and archive.
The modes differ: production requires explicit unqualified-rollout acceptance;
dev passes isolated-staging mode. Both initially share the same tested payload.
Dev never reads an arbitrary live source branch or silently moves production.
Future verified releases need a new entry snapshot and deliberate channel update.

The RC1 launcher SHA256 is
`55aa1ecff18d6f3578ebe543c52dbe797188e60670eedeeedaaad92cc9c06b1d`.
Archive SHA256 is
`8e4e331654dc44a47dd91c9cbbe76b885c8f3492b69d5ba9f3be97fa89c79e52`.
Both are explicitly passed/checked; the archive and RC1 folder are unchanged.

## Verification And Limits

- Actual Ubuntu staging: 29 focused shell tests passed, including pseudo-terminal
  curl-pipe inputs, acceptance/cancellation, separate modes, invalid/wildcard SIP
  networks, Admin selection, the read-only existing-PBX guard, checksum tamper and
  failed-download containment. No full installer was invoked by those fixtures.
- Production and dev actual verify-only downloads passed with matching launcher,
  archive and payload/runtime manifest. An initially slow dev transfer was
  interrupted, then its retry passed. No service, SQL or network changes.
- All 23 local frozen-runtime/package checks passed; backend/portals remain the
  tested originals. Manager SHA256 and Manager/Asterisk process IDs remained.
- A full-install invocation on existing staging was blocked by tool safety review;
  its refusal guard was instead checked alone, without installation functions.
- Clean-machine full install, reboot/restore and production provider/capacity
  acceptance are not claimed. Known Agent/Live heartbeat and auxiliary worker
  Agent/Hold metadata gaps remain in the original RC1 release notes.
- This is a fresh-install command, not an existing-production upgrade. Existing
  PBX/site refusal, explicit trusted networks and archive/call guards remain.
  Back up all data/configuration before later maintenance; no zero-loss promise.

Neither the protected Azure repository nor the production server was contacted.

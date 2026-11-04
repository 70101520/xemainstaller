# Bootstrap 20261104-4

This immutable entrypoint selects production/dev independently and verifies the
matching install4 launcher/archive before invoking the existing guarded setup.
Only version/checksum pins differ from bootstrap 20261104-3; argument handling,
local identity/TLS, manual networking and explicit rollout acceptance are unchanged.

Entrypoint SHA256:
`e87aa634774496981bd1d3caad0b6e251b62e1446d1c25ed4fda444ec03121ca`

Pinned tag: `xema-install-20261104-4`.
Release: `releases/20261104-rc1-install4`.
Launcher SHA256: `3bbabe15ec6db1e172824d187744c05c436d8deebcca83202aa055d5e408e726`.
Archive SHA256: `25ab5bbbdc46b969d60043a169a2afd38dbff287cd52e8eab66ef732a39d04b8`.

Ubuntu verification: 24 entrypoint and 33 launcher safety checks passed; neither
verification installs the package or restarts services. GUI/backend evidence,
limits and exact source version are recorded in the matching release notes.

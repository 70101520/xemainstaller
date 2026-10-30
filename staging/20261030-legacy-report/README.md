# Original Inbound Report Staging Snapshot

Source checkpoint: `7a6b8358e0ee04ac71cea776a55a82714a37f2c3` on `XEMA_WORKFLOW`.
This immutable snapshot is staging-only, not the production-default installer.
The matched launcher requires the staging option for this package.

Compared with `20261030-workers`, the archive adds only the operator's original
SOUTH Inbound CDR registration SQL and its usage note, plus an updated payload
manifest. Backend/runtime, all portals and existing deploy scripts are identical
to that previously tested package. Existing Hold/Resume, SIP/trunks, dialer
pacing, CDR calculations and historical data are not changed.

After installation, inspect `deploy/sql/README.md`, select the site's report
group and permissions, and manually run `deploy/sql/inbound-cdr-south-manual.sql`
in an authenticated database client. The installer does not run it. Existing
reports are untouched; sequential reruns do not duplicate the description.

Staging evidence:
- 202 compiled isolated Linux checks passed.
- Approved old report registered; a rerun created no duplicate or report change.
- 18 inbound rows x 35 original CSV fields matched the database and JSON report.
- Actual browser menu/download, empty-date and invalid-range/error-recovery
  checks passed without page script errors.
- Controlled call: Balaram/1004, Talk 19s, Hold 10s, Agent 29s, one Hold.
- GSM download matched its file; WAV playback passed; anonymous access denied.
- Protected CDR/campaign data and application/SIP/Hold file hashes unchanged;
  no Manager/Asterisk/service restart was needed.
- 23 local package and 26 VM verify-only installer/call-safety checks passed.

Both file hashes are in `SHA256SUMS`; the launcher's default URL/checksum matches
this archive. No site settings, passwords, private keys, backup SQL or call media
are included.

The separate auxiliary worker's Agent/Hold mismatch remains open. Do not switch
the old report from `SimpleCdr.Calls` to `SimpleCdrWorker.Calls`. This checkpoint
does not certify actual automatic-OBD/transfer/reconnect, a clean full install,
provider/VPN acceptance, recovery/reboot or capacity, and is not a production
approval. Existing operator/site configurations are not silently replaced.

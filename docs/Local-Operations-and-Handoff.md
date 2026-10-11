# Local operations and handoff

11 October 2026. This runbook covers the standalone Flutter Android/browser app with its own PHP/MySQL, routing and scanner. Local fixture accounts are test identities; reviews in regression tests are not actual legal, identity or transport approval.

## Start and verify

Run `tools/start_local.ps1` from PowerShell. It starts or verifies only the own loopback services: MariaDB 3317, PHP 8098, GraphHopper 8989/admin 8990, ClamAV 3320, and the thirty-second operations worker. It rejects an unrecognized owner on a required port. Leave the unrelated database on 3307 alone. Logs and process records remain under `.local/backend`; do not publish that directory.

Open `http://127.0.0.1:8098/demo/`. For an authorized USB Android device, run `.tools/android-sdk/platform-tools/adb.exe -s DEVICE_SERIAL reverse tcp:8098 tcp:8098` and install the matching signed release APK. The APK uses loopback for this test phase; it needs the USB tunnel. This is not yet the URL for remote clients. The user's HTTPS hosting address is pending, by choice.

The operations worker records fresh own-server routing/scanner checks, alerts the permitted on-call inbox about failures, reminds document owners of expiry and assigned/eligible staff of overdue cases, warns drivers before the work limit, and resolves approved timed restrictions only if access has not been superseded. Check `Operations health`, timestamps and actual service logs. A queue, an alert or a successful health probe does not prove a case was resolved or an emergency responder was dispatched.

## Roles and independent decisions

Customer owns booking and payment confirmation. Assigned driver alone accepts/arrives/starts/completes. Onboarding reviews clean private evidence and eligible vehicles. Routine support must claim a case before reply. Safety handles restricted evidence and restrictions. Finance handles collection/adjustment/refund/payout/hold proposals, with a different reviewer approving the exact hash and version. Admin handles configuration/access; it has no inherited finance or safety authority. Compliance owns reviewed legal holds and privacy decisions. On-call owns incidents and implemented-feature controls.

Provision an individual account with staff MFA before granting a staff role through an independently reviewed `role_grant`. Grants expire after 90 days; revoke obsolete access with a separate proposal. Keep authentic reviewer credentials and MFA recovery material outside public files. There is no public staff switch, shared administrative account or automatic driver approval. A future emergency/break-glass access workflow must define owner, reason, limited scope, expiry and follow-up review before it becomes available.

Restriction proposals include reviewed policy, duration (zero requires further review), scope and appeal window. Applying a restriction revokes sessions and blocks new work. Own Help and safe handling of an assigned ride remain accessible after sign-in. Expiry restores unchanged account access; it leaves suspended driver eligibility in onboarding review. A later access decision becomes `review_required` at expiry instead of being overwritten. The stated appeal date is an operational review date, not an assertion about a statutory limit.

Pending settlement destination changes pause payouts until independently reviewed or withdrawn. Previously approved payouts keep their original destination snapshot. Finance can independently hold/release settlement. Before actual execution the server rechecks hold, pending verification, identity, payable balance and exact proposal. Failed/held money movements record attempts without payment journals. Destination notices are saved in the authenticated inbox. Out-of-band prior-channel verification is a manual operating procedure; no email/SMS delivery is fabricated.

## Backup and recovery

`tools/verify_backup_restore.php` takes a private transaction-consistent dump of the isolated database, restores it into a fresh uniquely named temporary schema on 3317, checks user/trip/journal counts and journal balances, then removes only that temporary schema. It copies encrypted private evidence and the encryption secret to `.local/backups`. Successful evidence is `.local/backend/backup-restore-verification.json`. The original database remains untouched. Stop writes or use a coordinated maintenance window when taking a production snapshot so database and private-file/key backups describe the same point in time.

Protect database dumps, application encryption secrets, private identity/case evidence, signing key/password and reviewer MFA as secrets. A SQL dump alone cannot decrypt private files; an encryption key alone cannot reconstruct the records. Keep copies on separate protected storage for an actual disaster. Recovery into an empty owned host must restore matching database, encrypted files and key; provision restricted runtime credentials, run additive migrations, validate counts/balances and participant permissions, then restore service. This local restore drill is not proof of off-device disaster recovery.

## Privacy and retention

Privacy proposals record authenticated authority, jurisdiction, requested time and inventory version, and require current-password confirmation plus independent compliance review. Export delivery expires after 24 hours. Deletion pseudonymizes contact and revokes sessions while respecting active trips and documented legal holds. Financial records are preserved.

Retention has no arbitrary automatic legal default. Compliance must independently approve intervals, jurisdiction and actual legal basis. Run `tools/retention_worker.php` with `APP_ENV=local` first for a dry run; inspect its result. Use `--apply` only under an executed approved policy. The worker locks users/records, rechecks holds and open linked cases, commits redaction and a durable physical-deletion queue, then removes files. Failed physical removals remain queued for a later approved run. Keep encrypted backups under separately approved backup-retention rules; an app purge does not silently erase backups.

## Publishing later

Supply the own HTTPS backend, provision production environment secrets explicitly, migrate the owned MySQL database and routing/scanner data, rebuild both artifacts using `tools/build.ps1`, and run the same separate-account checks on that host. A downloaded Android APK, browser link and actual Android walkthrough can then be placed in the separate portfolio website. No portfolio page belongs to this app. Release metadata binds both binaries to current source fingerprints; walkthrough metadata must bind to the exact APK SHA-256. Native iOS remains deferred; iPhone visitors use the Flutter browser demo.

Real passenger operation also requires named operating owners for driver/equipment/routing legality, contact verification, cash remuneration, fatigue rules, terms/privacy/retention, support/safety response and on-call coverage. These are documented prerequisites, not fake app controls.

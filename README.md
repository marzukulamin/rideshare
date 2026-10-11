# RideShare — Flutter/Dart with a connected PHP/MySQL backend

Latest release: **1.2.1+4** — [APK, walkthrough video and portfolio asset package](https://github.com/marzukulamin/rideshare/releases/tag/v1.2.1). The existing video and captions are in [`media/`](media/), recorded on 1.2.0+3. See [GitHub and portfolio integration](docs/GitHub-and-Portfolio-Handoff.md) for copying the video into your website and the backend requirements for a live demo.

Android-first Customer, Driver and specialist staff app, plus the same Flutter browser client. Individual accounts and internal PHP/PDO endpoints use durable MySQL-compatible MariaDB state. Customer cannot accept, arrive, start or complete a driver's ride. Only the assigned driver controls those transitions. No external runtime APIs and no portfolio page are included.

Active client: `mobile/lib`. Active backend: `src/platform`, exposed through `public/api.php` and `public/shared.php`. Schema: `database/platform.sql` plus `connected-upgrade.sql` and additive `tools/migrate_connected.php`. Legacy synthetic showcase/HTML code is not the current client. Database refresh does not reset trips or produce invented earnings.

Own local test services are MariaDB 3317, PHP/static app 8098, GraphHopper 8989 and ClamAV 3320 on loopback. Open `http://127.0.0.1:8098/demo/` when all required services are running. A standalone static server on the former 8097 port is not the connected app. Flutter browser calls its own origin; Android has a build-time backend URL. Never connect Flutter directly to MySQL.

Build with `tools/build.ps1 -Target all -JavaHome E:\Java`, using the local Flutter/Android SDK and checked R-drive project alias. It runs analyzer/tests, builds web with bundled renderer assets and signs Android using the private release keystore, then stages hash-bound public artifacts. Keep `.local`, `.tools`, signing identity/passwords, test credentials, private documents and reference video outside the public web root.

Immediate cash passenger rides, genuine driver offers, private pickup PIN, route changes with both-party consent, safety/support/lost items, receipts/history/rebooking, documents, journal earnings and separately approved manual money/configuration/access workflows are implemented in source. Electronic payments, instant cash-out, stored-value wallet, guest/scheduled/parcel/family/enterprise extensions and native iOS are omitted. Android is installed natively; iPhone access is through its browser.

Current signed 1.2.1+4 includes startup error visibility, Retry connection, loading-state recovery and safe notifications after disposal. Flutter analyzer and all 12 tests pass; emulator and Samsung offline/reconnect recovery and separate Customer/Driver/Support browser smoke checks pass. Samsung installation preserved the existing customer session; place selection and server fare quote passed, and the phone was returned to Customer Home without requesting a ride. Use `tools/connect_android.ps1` to restore the local USB backend tunnel. See the verification report for current APK hash and earlier release evidence.

Previous 1.2.0+3 evidence: 146 backend checks, 10 connected browser journey checks, five native journey checks and five Samsung tracking checks. The navigator reset and keyboard-covered place list were fixed and regressed. Its 45-second actual Android walkthrough, captions and transcript are preserved privately after staging the new APK; they are not evidence for 1.2.1+4. Story-level partial clauses remain in the plan.

The user chose local testing until a hosting URL is supplied. USB forwarding lets the Samsung reach the computer's backend; this localhost APK will not work independently for remote clients. Later deployment needs an owned HTTPS PHP host, private database/routing/scanner/storage and a rebuilt APK. The separate portfolio website will link the app, APK and actual Android walkthrough; this repository does not add that website.

The earlier approval-review allowance interruption is resolved. Local services and operations worker are running. Use `tools/start_local.ps1` to start or reuse only this project’s services; see the local operations runbook.

- [Full implementation plan and all 172 acceptance stories](docs/RideShare-User-Stories-and-Implementation-Plan.md)
- [Portal gap audit](docs/Portal-Feature-Gap-Analysis.md)
- [Mobile and external portfolio delivery](docs/Flutter-Mobile-and-Portfolio-Delivery.md)
- [Local operations and handoff](docs/Local-Operations-and-Handoff.md)
- [Verification report](docs/Verification-Report.md)

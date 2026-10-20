# RideShare verification and local handoff

## Offline portfolio demo — 1.3.0+5

20 October 2026, Asia/Dhaka. The app now starts on a welcome screen with **Try Demo** and a separate real-account sign-in option. Try Demo does not initialize the backend store, read saved credentials, access GPS or request a real ride. Sample data and demo changes stay in memory. Existing real sessions and operations remain intact.

Flutter analysis is clean and all **15 tests pass**. Coverage includes a full simulated booking through driver match, arrival, pickup, completion, Activity, reset and exit at a 360px viewport, with backend requests blocked and an existing real session preserved. Model checks cover invalid same-place routes, active-booking preservation, cancellation and duplicate-history prevention.

The compiled browser demo passed on a plain static server with no PHP/database backend. Runtime interception blocked backend and external requests; the completed journey made **zero** such requests and produced no browser errors. Evidence is private under `.local/verification/offline-demo-browser.json` and `offline-demo-activity.png`.

Signed release APK: `release/site/downloads/rideshare-1.3.0.apk`, versionName `1.3.0`, versionCode `5`, minimum Android API 24. `apksigner verify` passed. APK SHA-256: `fb57b86950f476df4cf63c0cdbe674ab4f1cd074c48c496cc63f15356211a2ce`. No physical Android device was connected for this update; the earlier Samsung and emulator checks below apply to their named releases. This update was checked through model/widget tests, the compiled browser demo, Android release compilation and signature/manifest verification.

The existing walkthrough remains recorded on 1.2.0+3, accurately labeled in the release metadata. It does not show the new offline mode. The separate portfolio website has not been edited. See [Offline portfolio demo](Offline-Portfolio-Demo.md) for visitor instructions and [portfolio integration](GitHub-and-Portfolio-Handoff.md) for the optional APK download wording.

## Startup recovery update — 1.2.1+4

11 October 2026, Asia/Dhaka. The new signed Android APK and browser build passed Flutter analysis and all 12 tests. Android 16 emulator installation retained application data. The native recovery test removed the USB backend tunnel, observed the startup error and Retry connection, restored the tunnel, and verified return to the existing Driver account. Evidence is private under `.local/verification/startup-recovery.json`, `startup-offline.png` and `startup-recovered.png`.

The rebuilt browser client passed separate Customer, Driver and Support login and Customer booking-screen smoke checks, with no observed browser runtime errors or external runtime requests. The smoke script now supports Bengali labels and explicitly opens Home instead of assuming the account's saved tab.

Current APK: `release/site/downloads/rideshare-1.2.1.apk`, SHA-256 `66442776c3bb588930407587485c96c8f07b31f067d5d42fc09c9d32b80947ac`. It was installed on the emulator and subsequently the connected Samsung SM-S938B running Android 16, using an update install that preserved the existing customer session. Samsung offline startup and retry after restoring the USB tunnel passed. Pickup/destination selection and a server Car fare quote passed; no ride was requested and the phone was returned to Customer Home. No Flutter exception, fatal exception or out-of-memory error appeared in the recent logs inspected during these checks. This does not establish every possible device journey or background-service scenario.

Physical evidence: `.local/verification/startup-recovery-R5CY23MS2SP.json`, `booking-smoke-R5CY23MS2SP.json` and corresponding device-specific screenshots. The test helper now scrolls within visible scrollable app bounds to avoid swiping on the keyboard. Earlier booking script attempts failed due to verification assumptions; the final corrected check passed. The earlier Samsung journey/tracking and walkthrough results below apply to 1.2.0+3. At the user's request, the existing walkthrough is now included in `media/` and the GitHub release with its original version and APK hash explicitly preserved; it is not presented as footage of the new recovery fixes.

This APK still uses the computer's backend at `http://127.0.0.1:8098/` through USB forwarding. Independent remote client testing requires hosting the backend and rebuilding with its HTTPS URL. No hosting address or access is available yet, so remote deployment is incomplete. The database was not migrated or reset.

## Previous release evidence — 1.2.0+3

11 October 2026 · Asia/Dhaka. Version **1.2.0+3**. Results describe the recorded scenarios, not full acceptance of all 172 stories. Remaining clauses are recorded individually in [the implementation plan](RideShare-User-Stories-and-Implementation-Plan.md).

| Verification | Result | Scope |
|---|---|---|
| Backend | 146 checks passed | 37 core, 20 extended, 23 completion, 17 post-trip/maintenance, 21 policy/support/retention, 15 settlement/reveal, five backup/restore, three concurrent signup, five concurrent retention/hold. |
| Flutter | Analyzer clean; nine tests passed | Role/navigation boundaries, revoked session, network state, money validation, small/simple/Bengali layouts and keyboard-open destination picker. |
| Connected browser | 10 checks passed | Independent Customer/Driver/Support accounts, genuine offers, assigned-driver arrival/PIN/start/completion, cash confirmation and local PDF. No external runtime requests or browser exceptions observed. |
| Native journey | Five checks passed | Samsung Customer and emulator Driver use the final signed APK. Customer cold-launch restores the trip; only assigned Driver starts/completes; Customer independently confirms cash and opens history. |
| Samsung tracking | Five checks passed | Visible foreground service, background heartbeat with fresh physical GPS, disconnected-driver exclusion, reconnection recovery with fresh GPS, tracking-off service shutdown. Separate driver account prevents another client masking failure. |
| Local recovery | Five backend checks above | Private fresh-database restore rehearsal, preserved counts/balances and encrypted evidence/key backup. Off-device disaster recovery remains. |
| Walkthrough | 45 seconds; 1920×1080; 30fps | Actual native test footage, labeled Samsung Customer/emulator Driver, portrait mockup, VTT captions and transcript. No supplied reference footage or credentials. |

The legal-hold race used two PHP/MySQL connections and observed retention blocked on the held account row. Actual independently reviewed hold execution committed before retention resumed; case content, encrypted evidence and journals remained, and no file-purge record was created. This is evidence for that ordering; it does not prove every possible retention interleaving.

APK SHA-256: `7a59ec4166f09d117ad61bcf4c87104a09beb3254ba2b89c6bd814ac8217ecf7`. Both web and APK are bound to source fingerprint `db79b972737d7b0a915621e3cd6e2829193f82ebf53c235105ba171b8e498961`. The staging tool verifies active sources and artifact metadata before copying. Private scenario records, credentials, captures, keys and failed test history stay outside public artifacts.

Remaining device acceptance includes locked screen, battery saver, OS permission revocation, killed process, screen reader/large text, native crop/upload and iPhone/Safari. No killed-app tracking guarantee is made. Complete dynamic localization, advanced preferences/incentive rules, scheduled configuration, operating policy owners and staffing remain documented gaps.

Public handoff folder: `release/site`. APK: `downloads/rideshare-1.2.0.apk`; browser app: `demo/`; media: `media/rideshare-walkthrough.mp4`, `.vtt` and `walkthrough-transcript.txt`. No portfolio page is included. Backend hosting remains local by user choice: the APK currently requires the computer backend through USB forwarding. Remote app delivery requires owned HTTPS hosting and a rebuilt APK.

Phone tests are finished. Original power/rotation preferences were restored and RideShare was left on Customer Home. [Local operations and handoff](Local-Operations-and-Handoff.md) documents service startup, access provisioning, independent financial review, backup and data lifecycle.

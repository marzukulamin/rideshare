# Flutter mobile and external portfolio delivery

Approved: Flutter framework, Dart language, installed Android app, Flutter browser app and actual Android walkthrough with a phone mockup, captions and transcript. No portfolio page, marketing route or portfolio UI belongs in this app. The user's separate website will link to the exported artifacts. Native iOS is deferred because development is on Windows without a Mac; an iPhone can use the browser version.

## Current architecture and local testing

Individual Customer, Driver and specialist staff accounts use the same self-hosted PHP/MySQL state. There is no public role simulation or reset. The browser uses same-origin `/api.php` and `/shared.php`; Android uses the build-time `BACKEND_URL`. Both require the backend. Only internal APIs are used. Server-side PDO owns the database; Flutter never connects directly to MySQL.

Own local services: MariaDB `127.0.0.1:3317`; PHP app/static demo `127.0.0.1:8098`; GraphHopper route service `127.0.0.1:8989`; ClamAV `127.0.0.1:3320`. Keep database/router/scanner private. Local config/secrets/documents/signing/test accounts live under `.local`; SDKs under `.tools`. Neither directory is a public artifact.

The Samsung SM_S938B is authorized/unlocked. USB testing forwards device port 8098 to the computer. A localhost Android build requires that forwarding and is not usable by portfolio visitors independently. The user selected local testing for now and will provide hosting later. No deployment or remote URL is claimed.

## Artifact requirements and status

| Artifact | Acceptance | Present status |
|---|---|---|
| Signed Android APK | Release signing identity, version/minimum OS/checksum, clean install/update/launch, connected journey and real-device supported conditions | Current signed 1.2.0+3 is built, signature verified and installed on Samsung and emulator. Native coverage is documented separately; local USB backend remains required. |
| Flutter browser app | Same Dart contracts, `/demo/`, bundled renderer/fonts/maps, same-origin own backend, desktop/Android/iPhone browser tests, no external runtime requests | Current release build passed the 10-check connected journey after the navigator and picker fixes. Renderer/fonts/map are bundled; no external runtime requests observed. |
| Actual Android video | Record exact final APK, Customer/Driver/staff behavior, accurately labeled device/emulator, phone frame, captions/transcript and no secrets/reference footage | The 45-second 1920×1080/30fps actual Customer/Driver walkthrough, captions and transcript are exported and staged against the current APK hash. Samsung Customer and emulator Driver are labeled; staff native-device filming remains outside this short ride walkthrough. |
| Handoff manifest | Versioned download, size/SHA-256, backend requirement, web version, matching capture hash; no private data | Build/staging ran successfully and bind source fingerprint and binary hashes. Capture is independently hash checked before copying. |

`tools/build.ps1 -Target all -JavaHome E:\Java` uses the checked `R:` project alias, analyzer/tests, bundled web release and private release keystore. Staging rejects metadata/artifact hash mismatch and archives old public APK/media/demo output privately. Do not relabel old footage or stage unverified code as the final app.

Release paths after successful staging: `/demo/`, `/downloads/rideshare-1.2.0.apk`, `/release.json`; new `/media/rideshare-walkthrough.mp4`, VTT and transcript only when capture metadata matches that APK. These are local handoff paths; no public hosting is claimed. APK supports Android 7.0+. An AAB is not a direct install download.

When hosting is supplied, deploy the PHP entry points, private source/config/storage, restricted MySQL, local routing graph and scanner along with Flutter public assets on an owned HTTPS origin. Rebuild Android with that HTTPS URL, verify browser same-origin/session/CSRF behavior and retest. Serve only public artifacts; never upload `.local`, `.tools`, private signing identity, reference video, database dumps or test credentials to the document root. A static-only host cannot run this connected app.

The external portfolio can say Flutter/Dart Android app with a Flutter browser demonstration. Link the APK, browser app and actual Android recording separately. Browser access on iPhone is not native iOS. Local development fixtures are test accounts, not authentic passengers or proof of an operating transport service. User-facing services remain functional; deferred services are omitted.

## UI reference and UX contract

The supplied Uber recording informs the Customer layout: dark surfaces, clear primary actions, map/product sheet, pickup confirmation, Home/Services/Activity/Account, saved places, rebook, help/inbox/account/safety. RideShare uses original mint/charcoal branding and its own data. The recording did not demonstrate driver/admin workflows or a completed ride. Do not publish it or copy private account details.

SafeArea and keyboard-aware scroll, 48dp touch targets, semantic/focus labels, preserved drafts, meaningful async/empty/error states, larger simple mode and reduced motion are required. A customer sees only customer commands. Permission refresh cannot wipe an assigned driver's route. Final accessibility/Bangla/physical-device coverage remains tracked in the master plan.

The earlier approval-review interruption is resolved. Fresh analyzer/tests, backend regressions, signed builds, installation and browser journey passed. Remaining device/operating acceptance is explicit in the master plan.

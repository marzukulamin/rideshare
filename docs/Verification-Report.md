# RideShare verification and local handoff

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

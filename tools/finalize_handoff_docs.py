"""Update generated plans from completed, exact-build verification records."""
from pathlib import Path
import json,re
root=Path(__file__).resolve().parent.parent
apk=json.loads((root/'.local/build-metadata.json').read_text(encoding='utf-8-sig'))['android']['sha256']
for name in ['native-journey','phone-tracking']:
    record=json.loads((root/f'.local/verification/{name}.json').read_text())
    if record['passed']!=5 or record['apkSha256']!=apk:raise SystemExit('Device evidence is missing or stale.')
if json.loads((root/'.local/backend/retention-race-verification.json').read_text())['passed']!=5:raise SystemExit('Concurrent retention evidence is missing.')
for path in [root/'tools/update_implementation_docs.ps1',root/'tools/refresh_audit_docs.py']:
    text=path.read_text(encoding='utf-8-sig').replace('141','146')
    text=text.replace('15 settlement/reveal five local backup/restore and three concurrent signup checks','15 settlement/reveal, five local backup/restore, three concurrent signup and five concurrent retention/hold checks')
    text=text.replace('15 settlement/reveal, five local backup/restore and three concurrent signup checks','15 settlement/reveal, five local backup/restore, three concurrent signup and five concurrent retention/hold checks')
    text=text.replace('true concurrent hold-race regression remain','actual operating policy approval remains')
    text=text.replace('actual concurrent race matrix remain','expanded lifecycle/device matrix remains')
    text=text.replace('actual concurrent legal-hold/retention race remains','five actual concurrent legal-hold/retention checks passed; broader lifecycle interleavings remain')
    text=text.replace('Add true concurrent legal-hold/retention races; aggregate counts do not substitute for each story clause.','Five true concurrent legal-hold/retention checks passed with an observed blocked MySQL query; aggregate counts do not substitute for each story clause.')
    text=text.replace('Physical background behavior is unverified.','Samsung foreground/background GPS freshness, disconnect exclusion, recovery and tracking stop passed five checks; lock/battery/permission/killed-process scenarios remain.')
    text=text.replace('Complete and preserve native customer/assigned-driver journey, restart and physical background/network tests.','Preserve the five-check native customer/assigned-driver journey and five-check Samsung foreground/background/network tests, bound to this APK.')
    text=text.replace('Evidence: **146 backend checks**, clean analyzer, **nine Flutter tests** and **10 connected browser checks** passed.','Evidence: **146 backend checks**, clean analyzer, **nine Flutter tests**, **10 connected browser checks**, **five native journey checks** and **five Samsung tracking checks** passed.')
    text=text.replace('Native journey/background and exact-hash video evidence are kept separately; story-level partial clauses remain in the plan.','Five native journey and five Samsung tracking checks passed on this exact APK. The 45-second actual Android walkthrough, captions and transcript are staged; story-level partial clauses remain in the plan.')
    text=text.replace('Old captures are archived. New native source captures are recorded against the current APK hash; staging includes the walkthrough only when video/captions/transcript metadata matches.','The 45-second 1920×1080/30fps actual Customer/Driver walkthrough, captions and transcript are exported and staged against the current APK hash. Samsung Customer and emulator Driver are labeled; staff native-device filming remains outside this short ride walkthrough.')
    text=text.replace('The separate portfolio can use the APK, browser app and actual native walkthrough once an owned HTTPS backend is available.','The separate portfolio can use the exported walkthrough now; the APK and connected browser app need an owned HTTPS backend for remote visitors.')
    text=text.replace('Release manifests and capture metadata bind actual hashes; previous artifacts are archived, never relabeled.','Release manifests and capture metadata bind actual hashes; previous artifacts are archived, never relabeled. Five native journey checks and five Samsung tracking checks passed, including background fresh GPS, network-loss exclusion and recovery. See [the verification report](Verification-Report.md) for exact scope.')
    text=re.sub(r'(?:/account_policy){2,}','/account_policy',text)
    text=re.sub(r'(- \[Local operations and handoff\]\(docs/Local-Operations-and-Handoff.md\)\n){2,}',r'\1',text)
    text=re.sub(r'(- \[Local operations and handoff\]\(docs/Local-Operations-and-Handoff.md\))(?!\n- \[Verification)',r'\1\n- [Verification report](docs/Verification-Report.md)',text)
    path.write_text(text,encoding='utf-8')
report=f'''# RideShare verification and local handoff

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

APK SHA-256: `{apk}`. Both web and APK are bound to source fingerprint `db79b972737d7b0a915621e3cd6e2829193f82ebf53c235105ba171b8e498961`. The staging tool verifies active sources and artifact metadata before copying. Private scenario records, credentials, captures, keys and failed test history stay outside public artifacts.

Remaining device acceptance includes locked screen, battery saver, OS permission revocation, killed process, screen reader/large text, native crop/upload and iPhone/Safari. No killed-app tracking guarantee is made. Complete dynamic localization, advanced preferences/incentive rules, scheduled configuration, operating policy owners and staffing remain documented gaps.

Public handoff folder: `release/site`. APK: `downloads/rideshare-1.2.0.apk`; browser app: `demo/`; media: `media/rideshare-walkthrough.mp4`, `.vtt` and `walkthrough-transcript.txt`. No portfolio page is included. Backend hosting remains local by user choice: the APK currently requires the computer backend through USB forwarding. Remote app delivery requires owned HTTPS hosting and a rebuilt APK.

Phone tests are finished. Original power/rotation preferences were restored and RideShare was left on Customer Home. [Local operations and handoff](Local-Operations-and-Handoff.md) documents service startup, access provisioning, independent financial review, backup and data lifecycle.
'''
(root/'docs/Verification-Report.md').write_text(report,encoding='utf-8')
print('Updated verified handoff evidence and plan generators; all original story IDs retained.')

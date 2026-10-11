"""Refresh the evidence text without losing the original 172 acceptance stories."""
from pathlib import Path
import re

root=Path(__file__).resolve().parent.parent
file=root/'tools/update_implementation_docs.ps1'
text=file.read_text(encoding='utf-8-sig')
notes={
'ID-01':'Canonical phone normalization, password hashing and non-enumerating signup exist. Two real concurrent processes returned identical results and produced exactly one customer account/grant/consent; three regression checks passed.',
'ID-04':'Other-session revocation requires confirmation, revokes immediately and writes a security notice; backend/session regressions passed.',
'R-07':'Locked upfront road fare, terms, quote expiry and own-server pickup ETA are implemented; connected customer/driver booking passed.',
'R-14':'Immutable driver/vehicle make/model/color and optional clean approved JPEG/PNG profile-photo snapshots exist. Final optional-photo/native evidence coverage remains.',
'R-19':'Proximity-checked arrival, server waiting time, five-minute no-show threshold and no automatic waiting fee are implemented.',
'R-28':'Versioned 1–5 feedback, three validated optional tags and configured edit deadline are implemented. Ownership, stale edits and window checks passed.',
'R-29':'Pending tips can be corrected or cancelled through append-only journal deltas. Driver confirms the current amount; received tips require reviewed correction. Regression passed.',
'R-30':'Owned paginated history, immutable receipt snapshots, rebook and bundled-font PDF exist. The fresh connected browser receipt downloaded successfully.',
'R-32':'Fare reductions adjust actual debt/final fare without inventing wallet money; refund caps use actual collection. Independent approval and targeted regressions passed.',
'D-03':'Encrypted scanned private documents, image header/size checks and adjustable image crop exist. Native crop-output/upload and visual quality coverage remains.',
'D-14':'Assigned driver arrival checks fresh nearby GPS; server waiting display exists and separate-device journey verifies arrival.',
'D-19':'Assigned-driver-only completion, durable trip outcome, balanced journals and released active guards passed the connected journey.',
'D-22':'Reviewed manual payout destinations are immutable execution snapshots. Pending ownership changes pause execution; independent holds/releases and failed attempts are tested.',
'D-28':'Durable shift times, work duration, offer/outcome counts, cash, tips, earnings and pending/net payable are implemented; duplicate availability does not reset work.',
'D-41':'Durable work/rest limits and configurable advance warning exist; approved policy basis/owner and separate review are required. Device and production-policy matrix remains.',
'D-43':'Destination step-up/review, security notices, independent hold/release, pending-change pause and original snapshot execution are tested. Prior-channel verification remains an actual human procedure.',
'O-02':'Independent 30-second worker probes actual MySQL/GraphHopper/ClamAV health and records scoped fresh status, reminders and on-call alerts. Functional probes/deduplication passed.',
'O-03':'Masked scoped lookup and reasoned session-bound five-minute sensitive reveal exist; expiry, role and target boundary regressions passed.',
'O-05':'Versioned case ownership/status/due dates and independent overdue owner/supervisor reminders exist. Notification claims and delivery commit atomically.',
'O-06':'Claimed replies, localized approved templates, editable audience preview and send confirmation exist. Saved/read state changes only when the intended recipient opens case details. Scope/version tests passed.',
'O-17':'Incident records and automatic dependency-failure alerts exist. Real on-call staffing and response remain operating prerequisites.',
'O-25':'Independent restrictions include explicit scope, policy basis, duration and appeal deadline. Access-version guards prevent expiry from overwriting a later access decision; worker expiry/restoration tests passed.',
'O-27':'Cash retention offsets actual payable; payout snapshots, independent hold/release, blocked ownership change and failed/held execution without money journals passed targeted checks.',
'O-28':'Role-aware workload, assignment and independent SLA owner/supervisor reminders exist. Approved coaching purpose and actual staffed coverage remain.',
'O-30':'Incident timeline, real dependency probes and on-call alerts exist. Named coverage and incident response are documented operating requirements.',
'O-31':'Configuration rollback preserves accepted contracts; a private local backup/restore rehearsal passed five checks. Binary rollout and off-device disaster recovery remain.',
'O-34':'Identity-checked privacy requests, holds and approved dry-run/apply retention exist. Transactional user/trip/case/document locks and durable physical-purge queue protect evidence; legal-hold tests passed. Jurisdictional deadline/inventory and actual operating policy approval remains.',
'O-36':'Version conflicts fail safely and private drafts remain. The transient assignment-permission navigator bug is fixed and the complete connected browser journey passed.',
'X-02':'Fresh 390px customer/driver and 1280px staff browser journey passed. Signed APK is installed on Samsung and emulator; native evidence is separately recorded. iPhone/Safari coverage remains.',
'X-07':'Bundled Bengali font and stable-copy translations exist, including the new correction/worker/template flows. Dynamic error inventory, RTL and native-language review remain incomplete.',
'X-08':'Encrypted files, audited reveal and legal-hold-aware retention exist. Approved fixture dry-run/apply tests passed; physical purge uses a durable retry queue. Approved real retention basis and expanded lifecycle/device matrix remains.',
'X-11':'Unique active guards and actual concurrent driver acceptance have backend evidence. Identity/role/status navigation keys preserve temporary assignment transitions; connected journey passed.',
'X-12':'Current source, web and signed APK are fingerprint-bound; staging rejects stale artifacts. Native walkthrough metadata must match the exact APK hash. Hosting remains local.',
}
for key,note in notes.items():
    text=re.sub(r"(?m)^ '"+re.escape(key)+r"'='.*'$",lambda _:" '"+key+"'='"+note.replace("'","''")+"'",text)
# Remaining partial clauses, rather than obsolete fix/test tasks.
for key in ['ID-01','ID-04','R-19','R-28','R-29','R-30','R-32','D-14','D-19','D-22','D-28','O-02','O-03','O-05','O-06','O-25','O-27','O-36','X-11']:
    text=re.sub(r"(\$partial=@\([^\n]+)",lambda m:m[0].replace("'"+key+"',",''),text)
text=text.replace('Source implemented; final release verification pending','Source implemented; clause-level acceptance remains')
text=re.sub(r'auth/account/requests; identity/extensions/operations(?!/account_policy)','auth/account/requests; identity/extensions/operations/account_policy',text)
text=text.replace('trips/extensions/cash/support; rs_quotes','trips/extensions/cash/support/post_trip; rs_quotes')
text=text.replace('operations/governance/configuration/cash; rs_requests','operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests')
evidence='''Recorded current backend regressions passed 37 core, 20 extended, 23 completion, 17 post-trip/maintenance, 21 policy/support/retention, 15 settlement/reveal, five local backup/restore, three concurrent signup and five concurrent retention/hold checks: **146 checks**. Coverage includes real MySQL persistence, driver-only transitions/PIN privacy, concurrent accept race, scanning, specialist scope, exact approval binding, interrupted fare, partial cash/refund caps, failed manual execution/retry, lost-item consent, pending-tip correction, feedback editing, template audience/read state, restriction expiry, settlement holds and balanced journals. Test counts represent these scenarios, not all 172 acceptance stories.

Flutter analyzer is clean and **nine tests passed**, including navigation on temporary permission changes, revoked role cleanup, network/401 behavior, invalid money entry, 360px/simple/Bengali layout and keyboard-open place selection. The **10-check fresh connected browser journey passed** across independent Customer/Driver/Support accounts, real offers, assigned-driver arrival/PIN start/completion, both-party cash confirmation and local PDF download. No external runtime requests or browser exceptions were observed.

The latest signed **1.2.0+3** web/APK builds share the current source fingerprint. The APK is installed on Samsung SM_S938B and the Android emulator. Device journey/background/capture evidence is recorded separately under private `.local/verification` and `.local/capture-v3`; those exact records determine device acceptance. Release manifests and capture metadata bind actual hashes; previous artifacts are archived, never relabeled. Five native journey checks and five Samsung tracking checks passed, including background fresh GPS, network-loss exclusion and recovery. See [the verification report](Verification-Report.md) for exact scope. Five native journey checks and five Samsung tracking checks passed, including background fresh GPS, network-loss exclusion and recovery. See [the verification report](Verification-Report.md) for exact scope. Local tests use development fixtures and no real funds.

Automatic approval review is available again; the earlier allowance interruption no longer blocks verification. The user chose local testing and will provide HTTPS hosting later. This APK requires the computer backend and USB forwarding; it is not a remotely usable client release.

The local operations worker is running and fresh health probes are verified. Reviewed restriction/settlement lifecycle, feedback/tip edits, controlled replies, document crop and transactional retention were added. [Local operations and handoff](Local-Operations-and-Handoff.md) documents service startup, named staff provisioning, independent financial decisions, privacy/retention, backups and future hosting. Policies requiring human authority remain explicit prerequisites.

'''
start=text.index('Recorded backend regressions passed') if 'Recorded backend regressions passed' in text else text.index('Recorded current backend regressions passed')
end=text.index('## Full story acceptance and traceability',start)
text=text[:start]+evidence+text[end:]
start=text.index('### Ordered remaining implementation and verification') if '### Ordered remaining implementation and verification' in text else text.index('### Coordinated acceptance and remaining work')
end=text.index('### Acceptance scenario inventory',start)
text=text[:start]+'''### Coordinated acceptance and remaining work

1. Preserve the 146 backend/nine Flutter/10 connected browser records and the current source fingerprints. Five true concurrent legal-hold/retention checks passed with an observed blocked MySQL query; aggregate counts do not substitute for each story clause.
2. Preserve the five-check native customer/assigned-driver journey and five-check Samsung foreground/background/network tests, bound to this APK. Battery saver, lock, OS permission revocation, killed-process and screen-reader/large-text scenarios require actual device evidence; no blanket background guarantee.
3. Remaining software clauses: driver destination/area preferences, rule-backed incentives/progress, general polygon/time preview, scheduled terms/promotions, risk/stuck-trip queues, periodic access review/break-glass, complete dynamic/error localization and disclosure deadline/inventory. Implement these against explicit local contracts; never display fabricated or unfinished services.
4. Retention dry-run/apply and local backup restore passed on isolated fixtures. Obtain an approved real retention basis, off-device encrypted backup location and actual recovery objectives before real operations. Financial journals and lawful holds stay protected.
5. Keep exact-hash signed APK/browser artifacts and native video, captions and transcript together. Capture labels distinguish Samsung and emulator; exclude credentials, notifications and supplied reference footage. The separate portfolio website is outside this app.
6. Hosting remains local. When an owned HTTPS origin is supplied, deploy PHP/private code/database/router/scanner, rebuild Android with that URL and retest browser/device access. The local USB-dependent APK is not a working remote download.
7. Named owners must approve transport/equipment/routing legality, fatigue/contact/identity/cash policies, terms, privacy and staffed support/safety/on-call response. No test can manufacture those operating decisions.

'''+text[end:]
replacements={
'Targeted latest adjustment/snapshot tests and approved operating rates.':'Targeted adjustment/snapshot checks passed; approved operating rates remain.',
'Targeted adjustment and manual settlement regressions; finance operating owner.':'Targeted correction/settlement checks passed; finance operating owner remains.',
'Advance warning UI, chosen definitions/limits/reset/exception policy, devices.':'Advance warning implemented; approved definitions/limits/reset/exception policy and device matrix remain.',
'Hold/release/prior-channel fallback policy plus snapshot regression.':'Hold/release/pending ownership pause and snapshots tested; actual prior-channel verification procedure remains.',
'Latest UI conflicts/sensitive reveal expiry/retention concurrency.':'Sensitive reveal expiry and lifecycle tests passed; five actual concurrent legal-hold/retention checks passed; broader lifecycle interleavings remain.',
'Earlier backend runs passed 80 checks; earlier analyzer and six Flutter tests passed. Latest navigation/vehicle/photo/waiting/session-confirmation changes are not yet reverified. The browser journey caught an acceptance-navigation reset, now fixed in source with a seventh regression added. Final rerun/build/install/video remain pending; intermediate artifacts do not prove current source acceptance.':'Current evidence: 146 backend checks, clean Flutter analyzer, nine Flutter tests and 10 connected browser journey checks. The navigator reset and keyboard-covered place list were fixed and regressed. Current signed 1.2.0+3 is installed on Samsung and emulator. Five native journey and five Samsung tracking checks passed on this exact APK. The 45-second actual Android walkthrough, captions and transcript are staged; story-level partial clauses remain in the plan.',
'Automatic approval review could not run the latest verification because its account usage allowance was exhausted. This was a review-service failure, not a safety judgment. Do not bypass it or call the latest build verified. Phone authorization/unlock are confirmed; resume remaining checks when review is available.':'The earlier approval-review allowance interruption is resolved. Local services and operations worker are running. Use `tools/start_local.ps1` to start or reuse only this project’s services; see the local operations runbook.',
'Latest verification/build/phone work is blocked by automatic approval review\'s usage allowance. This is a review-service failure, not a finding that testing is unsafe; it must not be bypassed.':'The earlier approval-review interruption is resolved. Fresh analyzer/tests, backend regressions, signed builds, installation and browser journey passed. Remaining device/operating acceptance is explicit in the master plan.',
'Intermediate 1.2.0+3 APK exists but predates latest source; Samsung has an older installed build. Final rebuild/signature/install/testing pending.':'Current signed 1.2.0+3 is built, signature verified and installed on Samsung and emulator. Native coverage is documented separately; local USB backend remains required.',
'Intermediate release build exists. Full connected journey exposed driver navigation bug; source fix and regression added, final rerun pending.':'Current release build passed the 10-check connected journey after the navigator and picker fixes. Renderer/fonts/map are bundled; no external runtime requests observed.',
'Existing v1 recordings are obsolete. New matching Android capture and mockup/captions remain pending.':'The 45-second 1920×1080/30fps actual Customer/Driver walkthrough, captions and transcript are exported and staged against the current APK hash. Samsung Customer and emulator Driver are labeled; staff native-device filming remains outside this short ride walkthrough.',
'`tools/build.ps1` and `stage_release.py` updated to bind separate web/APK build hashes and capture. Final execution pending.':'Build/staging ran successfully and bind source fingerprint and binary hashes. Capture is independently hash checked before copying.',
'These are planned handoff paths, not proof that the latest files are ready or publicly hosted.':'These are local handoff paths; no public hosting is claimed.',
}
for old,new in replacements.items():text=text.replace(old,new)
text=re.sub(r'(- \[Mobile and external portfolio delivery\]\(docs/Flutter-Mobile-and-Portfolio-Delivery.md\))(?!\n- \[Local operations)',r'\1\n- [Local operations and handoff](docs/Local-Operations-and-Handoff.md)
- [Verification report](docs/Verification-Report.md)',text)
gap_start=text.index("$gap=@'")
gap_end=text.index("'@\n$gap |",gap_start)
text=text[:gap_start]+"""$gap=@'
# RideShare portal and implementation gap audit

Revision: 11 October 2026. Flutter/Dart Android and browser clients share authoritative PHP/MySQL. All 172 original acceptance stories remain in [the master plan](RideShare-User-Stories-and-Implementation-Plan.md), with fixes and remaining clauses. Customer is the app role name.

The highest-impact defects were customer access to driver commands, disconnected state, weak specialist boundaries, fake offers/money, private-data exposure and inconsistent release evidence. Driver-only server transitions, private customer PIN, genuine offers, exclusive active-trip guards, immutable snapshots and independently reviewed balanced journals address those defects.

| Surface | Implemented fixes | Remaining acceptance |
|---|---|---|
| Customer | Real booking/matching, driver updates/PIN, consented changes, history/PDF, cash, editable pending tips, versioned tagged feedback, safety/help/lost items | Complete localization, optional photo/device accessibility and iPhone/Safari matrix. |
| Driver | Reviewed enrollment/documents/crop, genuine offers, assigned transitions, foreground tracking, work/rest warnings, shift/earnings, reviewed payout/holds | Full physical lock/battery/permission/killed-process matrix, crop output/upload, rule-backed incentives and advanced matching preferences. |
| Staff | Specialist queues, ownership/templates/audience/read state, durable SLA reminders/health worker, restrictions/appeals/expiry, independent finance decisions and reveal expiry | Risk/stuck-trip queues, privacy authority/deadline inventory, periodic access review/break-glass and actual staffing. |
| Admin | Reviewed role grants/configuration, versioned content, effective rates/product changes, rollback, private backup/restore and provisioning runbook | Scheduled terms/promotions, polygon/time preview, monitored binary rollout and named policy owners. Admin does not inherit specialist permissions. |
| Delivery | Signed current APK installed on Samsung/emulator, bundled same-origin browser, source/binary fingerprint checks and exact-APK capture binding | Hosting is deliberately local; remote HTTPS deployment/rebuild and full supported-device release matrix remain. |

Evidence: **146 backend checks**, clean analyzer, **nine Flutter tests**, **10 connected browser checks**, **five native journey checks** and **five Samsung tracking checks** passed. Separate account/device results are saved privately and do not certify every clause of all 172 stories. Device testing found and fixed keyboard-covered place search and stale stationary-driver GPS. Historical failures remain preserved.

The local worker is running, dependency probes are fresh and a private local backup/restore rehearsal passed. [Local operations and handoff](Local-Operations-and-Handoff.md) explains startup, provisioning, independent decisions and data lifecycle. Human policy authority, actual money evidence and staffed response cannot be manufactured by code.

Electronic gateways, stored value, instant transfers, guest/scheduled/parcel/family/enterprise extensions and native iOS remain deferred and omitted. No disabled showcase cards or portfolio page were added. The separate portfolio can use the exported walkthrough now; the APK and connected browser app need an owned HTTPS backend for remote visitors.

The earlier automatic approval-review allowance interruption is resolved. The phone is authorized. The user chose local testing; no public deployment is claimed.
"""+text[gap_end:]
file.write_text(text,encoding='utf-8-sig')
print('Refreshed generator while preserving original story catalog.')


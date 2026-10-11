$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$docs=Join-Path $root 'docs'
$archive=Join-Path $root '.local\archive\plans\before-connected-audit'
New-Item -ItemType Directory -Path $archive -Force | Out-Null
foreach($relative in @('README.md','docs\RideShare-User-Stories-and-Implementation-Plan.md','docs\Portal-Feature-Gap-Analysis.md','docs\Flutter-Mobile-and-Portfolio-Delivery.md')){
 $source=Join-Path $root $relative
 $saved=Join-Path $archive (Split-Path $relative -Leaf)
 if(!(Test-Path -LiteralPath $saved)){Copy-Item -LiteralPath $source -Destination $saved}
}
$stories=@(Get-Content -LiteralPath (Join-Path $root '.local\story-catalog.json') -Raw | ConvertFrom-Json)
if($stories.Count -ne 172){throw 'The original acceptance catalog must contain all 172 stories.'}

$notes=@{
 'ID-01'='Canonical phone normalization, password hashing and non-enumerating signup exist. Two real concurrent processes returned identical results and produced exactly one customer account/grant/consent; three regression checks passed.'
 'ID-03'='Protected manual recovery intake, independent review and revoked sessions exist. Old/new contact verification procedure requires an operating owner.'
 'ID-04'='Other-session revocation requires confirmation, revokes immediately and writes a security notice; backend/session regressions passed.'
 'ID-06'='Reviewed export/deletion and legal-hold checks exist. Authority, deadlines and approved retention values remain policy prerequisites.'
 'ID-07'='Quote terms are displayed and accepted with version evidence; changed required terms require requoting. Optional channels must stay separate.'
 'ID-08'='Signed-out urgent/recovery intake and restricted status link are implemented; reviewing an appeal never grants normal marketplace privileges.'
 'R-01'='Device location, accuracy, manual place/map/coordinate alternatives and explicit pickup confirmation exist; physical permission-denial/approximate-location testing remains.'
 'R-03'='Pan/zoom and tap-to-select map with manual coordinates provide alternatives to dragging. A selected point must pass service boundary and road-snap validation.'
 'R-06'='Database products/capacity/price are displayed. Each type still requires genuine approved compatible supply; no fake driver is assigned when supply is absent.'
 'R-07'='Locked upfront road fare, terms, quote expiry and own-server pickup ETA are implemented; connected customer/driver booking passed.'
 'R-07a'='Local GraphHopper route, database rate and deterministic whole-BDT rounding exist; accepted rates/routes are immutable snapshots.'
 'R-08'='Cash and personal travel profile are supported. Electronic payment credentials and business billing are outside the selected release.'
 'R-09'='Deferred external gateway extension. No card, bKash, top-up or electronic charge controls are shown.'
 'R-10'='Eligible database promotions reduce the customer fare without silently reducing the configured driver remuneration. Stored-value credits are omitted.'
 'R-14'='Immutable driver/vehicle make/model/color and optional clean approved JPEG/PNG profile-photo snapshots exist. Final optional-photo/native evidence coverage remains.'
 'R-15'='Freshness/accuracy/reachability are shown; local road-based pickup ETA was added. Samsung foreground/background GPS freshness, disconnect exclusion, recovery and tracking stop passed five checks; lock/battery/permission/killed-process scenarios remain.'
 'R-16'='Private trip messages and canned pickup messages exist. No external call proxy, automatic SMS or delivery guarantee is claimed.'
 'R-19'='Proximity-checked arrival, server waiting time, five-minute no-show threshold and no automatic waiting fee are implemented.'
 'R-20'='Per-trip encrypted PIN is exposed only to the customer and validated by the assigned driver start endpoint. Required PIN cannot be bypassed by customer UI.'
 'R-21'='Time-limited own-server share links and owner revocation are implemented; no external messaging API is required.'
 'R-22'='Safety hub, urgent case intake and emergency calling/manual fallback exist; local anomaly checks have owned cases. Emergency staffing is an operating prerequisite.'
 'R-23'='Bundled local emergency information and native dialer/manual number fallback exist; no automatic dispatch or external emergency handoff is claimed.'
 'R-24'='Ordered stops, road repricing and customer confirmation plus driver acceptance exist. Already-visited stops cannot be silently reordered.'
 'R-25'='Customer proposes a new destination; only assigned driver can accept the change; expired/stale changes fail.'
 'R-26'='Authoritative refresh/poll/resume and persisted operation keys exist. Latest navigator correction preserves active trip when temporary permission changes.'
 'R-28'='Versioned 1–5 feedback, three validated optional tags and configured edit deadline are implemented. Ownership, stale edits and window checks passed.'
 'R-29'='Pending tips can be corrected or cancelled through append-only journal deltas. Driver confirms the current amount; received tips require reviewed correction. Regression passed.'
 'R-30'='Owned paginated history, immutable receipt snapshots, rebook and bundled-font PDF exist. The fresh connected browser receipt downloaded successfully.'
 'R-32'='Fare reductions adjust actual debt/final fare without inventing wallet money; refund caps use actual collection. Independent approval and targeted regressions passed.'
 'R-33'='Trip-linked lost-item report, driver finding, both-party consent and both return confirmations exist; no personal phone/home disclosure or invented return fee.'
 'R-35'='Outstanding actual receivable and partial manual collection are shown with dispute/help. No debt is silently attached to a future trip.'
 'R-36'='Manual repayment approval, held/failed attempts and evidenced execution are distinct; approval alone is never paid.'
 'R-37'='Safety specialist case-linked exclusions are enforced in matching/late accept. Duration is a development policy value awaiting operating approval.'
 'R-38'='Passenger capacity, helmets/luggage requirements and unsupported wheelchair supply checks exist. Local product/age/legal rules need an operating owner.'
 'R-39'='Interrupted outcome, separately reviewed fare/earning, failed vehicle hold and open assistance case exist. A new consenting booking does not imply guaranteed replacement supply.'
 'R-40'='Deferred guest booking extension. No guest passenger controls or unverified guest contacts are shown.'
 'R-41'='Deferred scheduled rides extension. No Later/Reserve controls or guaranteed reservation claim are shown.'
 'D-01'='Applicant enrollment is separate from approved driver access; enrollment never grants dispatch privileges.'
 'D-02'='Vehicle/application storage and latest make/model/color fields exist. Adding a new vehicle preserves the old approved selection pending review.'
 'D-03'='Encrypted scanned private documents, image header/size checks and adjustable image crop exist. Native crop-output/upload and visual quality coverage remains.'
 'D-05'='Manual evidence-based identity status and appeal exist; no unperformed external background check or biometric verification is claimed.'
 'D-08'='Desired availability is independent of active assignment; offline prevents new offers and preserves the current trip.'
 'D-09'='Product/equipment eligibility is enforced. Broader destination/area trip-preference controls require an explicit implemented matching contract.'
 'D-11'='Transactional accept, unique customer/driver/vehicle guards and real concurrent race verification exist. Customer has no accept authority.'
 'D-14'='Assigned driver arrival checks fresh nearby GPS; server waiting display exists and separate-device journey verifies arrival.'
 'D-16'='Only assigned eligible driver starts using customer PIN; server never returns the secret to driver. This is not a customer action.'
 'D-19'='Assigned-driver-only completion, durable trip outcome, balanced journals and released active guards passed the connected journey.'
 'D-22'='Reviewed manual payout destinations are immutable execution snapshots. Pending ownership changes pause execution; independent holds/releases and failed attempts are tested.'
 'D-23'='Deferred automated cash-out extension. No instant transfer button is shown; manual settlement is a separate reviewed workflow.'
 'D-24'='Driver incentive/opportunity rules and a complete progress/eligibility UI are not configured. Do not show fabricated incentive cards; implement when real local rules are chosen.'
 'D-27'='Durable shift start/end and availability states exist. Duplicate online/offline actions must not reset accumulated work.'
 'D-28'='Durable shift times, work duration, offer/outcome counts, cash, tips, earnings and pending/net payable are implemented; duplicate availability does not reset work.'
 'D-30'='Both-party lost-item flow is implemented with scoped history and a support mediation case.'
 'D-31'='Driver can interrupt for breakdown/unsafe ending; further offers stop, passenger assistance remains open, finance separately reviews the partial outcome.'
 'D-33'='Earnings statement reads journal entries and separates fare/earnings/cash/settlement. PDF is generated from bundled fonts.'
 'D-35'='Only own approved compatible vehicle can be selected while offline with no active trip; new vehicle approval is version guarded.'
 'D-36'='Non-financial six-step practice plus stopped-driver road hazard intake exist; reports are moderated cases, not automatic road graph edits.'
 'D-37'='Own ordinary feedback and separate serious safety reporting exist. Aggregated structured feedback/category treatment is incomplete.'
 'D-39'='Driver history has paginated period/lifetime counts by actual outcomes. Ended customer endpoints and recognition fields are minimized.'
 'D-40'='Android native foreground location service and first-party heartbeat exist; physical Samsung lock/background/battery/restart matrix has not passed. No killed-app/browser background guarantee.'
 'D-41'='Durable work/rest limits and configurable advance warning exist; approved policy basis/owner and separate review are required. Device and production-policy matrix remains.'
 'D-42'='Identity recheck makes new work ineligible without abandoning assigned passenger recovery; independently reviewed evidence restores eligibility.'
 'D-43'='Destination step-up/review, security notices, independent hold/release, pending-change pause and original snapshot execution are tested. Prior-channel verification remains an actual human procedure.'
 'D-44'='Vehicle capacity/equipment and product requirements are checked; specialized assistance certification must be chosen/verified before enabling those products.'
 'O-02'='Independent 30-second worker probes actual MySQL/GraphHopper/ClamAV health and records scoped fresh status, reminders and on-call alerts. Functional probes/deduplication passed.'
 'O-03'='Masked scoped lookup and reasoned session-bound five-minute sensitive reveal exist; expiry, role and target boundary regressions passed.'
 'O-05'='Versioned case ownership/status/due dates and independent overdue owner/supervisor reminders exist. Notification claims and delivery commit atomically.'
 'O-06'='Claimed replies, localized approved templates, editable audience preview and send confirmation exist. Saved/read state changes only when the intended recipient opens case details. Scope/version tests passed.'
 'O-07'='Finance-bound proposals, evidence, actual collection caps and reviewed fare reduction exist. Support does not gain unilateral money authority.'
 'O-08'='Distinct requester/reviewer and exact proposal hash/version binding exist, with single execution and failed/held manual attempts.'
 'O-10'='Encrypted evidence, scan state, reviewer reason, version guard and driver/vehicle prerequisites exist. Latest physical vehicle metadata policy needs regression.'
 'O-11'='Local Dhaka radius plus extracted road boundary, effective configuration and rollback exist. General polygon editor and time-window preview remain.'
 'O-12'='Reviewed effective pricing/product rules and immutable accepted fare contract exist. Terms/promotions currently publish immediately rather than scheduled promotion.'
 'O-13'='Implemented-feature cohorts, explicit owner/expiry, review and kill switch exist; flags cannot turn on unimplemented services.'
 'O-14'='Role-specific reviewed time-limited grants/revocation exist. Global admin does not inherit finance, dispatch or safety privileges.'
 'O-15'='Compliance-scoped own-data/deletion/hold review exists. Lawful disclosure authority, jurisdiction/deadline/inventory workflow remains incomplete.'
 'O-17'='Incident records and automatic dependency-failure alerts exist. Real on-call staffing and response remain operating prerequisites.'
 'O-18'='Manual release/cohort/gate/compatible migration/rollback records exist. Actual binary rollout automation and monitoring gates remain.'
 'O-19'='No machine learning model is used. ML governance is inapplicable until a model is explicitly selected; no fictitious model console.'
 'O-20'='Purpose-limited finance/aggregate reports and minimum-cohort suppression exist. Export authority is distinct from private trip/case access.'
 'O-21'='Freshness-labeled dispatch queue and canonical state lookup exist. Stuck-trip alert jobs are incomplete.'
 'O-22'='Reasoned version-bound dispatch rematch/interruption/assistance exists. Dispatch cannot impersonate driver start/completion.'
 'O-24'='Human restriction review with evidence exists. A dedicated provenance/confidence risk signal queue remains; no automated model imposes permanent loss.'
 'O-25'='Independent restrictions include explicit scope, policy basis, duration and appeal deadline. Access-version guards prevent expiry from overwriting a later access decision; worker expiry/restoration tests passed.'
 'O-26'='Cash disputes, partial settlements, held/failed execution attempts and balanced ledgers exist. Actual money evidence remains mandatory.'
 'O-27'='Cash retention offsets actual payable; payout snapshots, independent hold/release, blocked ownership change and failed/held execution without money journals passed targeted checks.'
 'O-28'='Role-aware workload, assignment and independent SLA owner/supervisor reminders exist. Approved coaching purpose and actual staffed coverage remain.'
 'O-29'='Named individual accounts, MFA, role expiry and immediate authorization refresh exist. Periodic review and reviewed break-glass workflow remain.'
 'O-30'='Incident timeline, real dependency probes and on-call alerts exist. Named coverage and incident response are documented operating requirements.'
 'O-31'='Configuration rollback preserves accepted contracts; a private local backup/restore rehearsal passed five checks. Binary rollout and off-device disaster recovery remain.'
 'O-32'='Versioned localized help/discovery/notices with expiry/fallback exist. Complete translated error inventory still needs review.'
 'O-33'='Exact approved effective changes, overlap guard, conflict outcome and version-bound rollback exist. All policy types do not yet share scheduled lifecycle.'
 'O-34'='Identity-checked privacy requests, holds and approved dry-run/apply retention exist. Transactional user/trip/case/document locks and durable physical-purge queue protect evidence; legal-hold tests passed. Jurisdictional deadline/inventory and actual operating policy approval remains.'
 'O-35'='Source MySQL aggregates and as_of exist; no seeded fake performance metrics. Additional report lineage documentation/operational freshness alerts remain.'
 'O-36'='Version conflicts fail safely and private drafts remain. The transient assignment-permission navigator bug is fixed and the complete connected browser journey passed.'
 'O-37'='Exact proposal hash and versions bind approval; changed amounts/targets cannot silently execute; failed retries remain bound.'
 'O-38'='Expired/restricted drivers lose new work; assigned-trip completion/interruption stays scoped; start revalidates required eligibility.'
 'O-40'='Ended/interrupted trip does not resolve assistance automatically. Assistance queue stays open with eligible staff ownership.'
 'X-01'='SafeArea, scrollable forms, semantics, focus/input preservation and 48dp controls exist. Full physical screen-reader/large-text/keyboard journey remains.'
 'X-02'='Fresh 390px customer/driver and 1280px staff browser journey passed. Signed APK is installed on Samsung and emulator; native evidence is separately recorded. iPhone/Safari coverage remains.'
 'X-03'='Safe controller values are retained on API errors; secret/PIN input is scoped; navigation must not clear a live journey on temporary permission grants.'
 'X-05'='Persisted scoped idempotency keys, original-operation lookup, transactional retries and immutable journal references exist.'
 'X-06'='Durable inbox/read state and routine offer preferences exist. Native foreground notification behavior and missed alerts need physical verification.'
 'X-07'='Bundled Bengali font and stable-copy translations exist, including the new correction/worker/template flows. Dynamic error inventory, RTL and native-language review remain incomplete.'
 'X-08'='Encrypted files, audited reveal and legal-hold-aware retention exist. Approved fixture dry-run/apply tests passed; physical purge uses a durable retry queue. Approved real retention basis and expanded lifecycle/device matrix remains.'
 'X-10'='Request correlation IDs, redacted exception logs, scoped private audit and incident records exist. Automated metrics/user-impact alerts and approved log-retention rules remain.'
 'X-11'='Unique active guards and actual concurrent driver acceptance have backend evidence. Identity/role/status navigation keys preserve temporary assignment transitions; connected journey passed.'
 'X-12'='Current source, web and signed APK are fingerprint-bound; staging rejects stale artifacts. Native walkthrough metadata must match the exact APK hash. Hosting remains local.'
 'C-02'='Passenger ride products only. Delivery mode is omitted because parcel operations are deferred.'
 'C-03'='Immediate Where to booking works. Later scheduling is omitted, not displayed as a disabled service.'
 'C-05'='Database Bike/Car/CNG/XL shortcuts are supported with genuine offer matching. Reserve is omitted.'
 'C-06'='Locally managed discovery content/fallback/expiry and feature flag exist.'
 'C-07'='Parcel discovery/send/receive extension is deferred and omitted.'
 'C-10'='Help, cash financial history, Safety and Inbox exist. No stored-value balance or top-up is implied.'
 'C-11'='Actual cash/fare/refund history exists. Stored-value wallet is deferred and no invented balance is displayed.'
 'C-12'='Cash is the supported payment method. bKash remains omitted without an actual enabled gateway.'
 'C-13'='Personal travel profiles exist; family/business entitlement or organization billing are not implied by profile labels.'
 'C-14'='Own eligible promotional codes and redemption checks exist; stored-value gift vouchers are not implemented.'
 'C-18'='Trusted emergency contact CRUD exists. Guest booking contacts do not authorize an unimplemented guest ride.'
 'C-19'='Linked-family shared billing extension is deferred and omitted.'
 'C-20'='Personal profile labels are supported; enterprise authorization/invoices/billing are deferred and omitted.'
 'C-22'='Persisted supported PIN, contacts, own-server sharing and safety response exist; no unsupported recording/biometric control.'
 'C-26'='Customer can apply as driver; this never grants driver access until evidence-based review.'
}
$partial=@('ID-03','ID-06','R-01','R-03','R-14','R-15','D-02','D-03','D-09','D-24','D-37','D-40','D-41','D-43','O-10','O-11','O-12','O-15','O-17','O-18','O-21','O-24','O-28','O-29','O-30','O-31','O-33','O-34','O-35','X-01','X-02','X-06','X-07','X-08','X-10','X-12')
$extensions=@('R-09','R-40','R-41','D-23','C-02','C-03','C-07','C-19','C-20')
function Evidence([string]$id){
 if($id -like 'ID-*'){return 'auth/account/requests; identity/extensions/operations/account_policy; rs_users, rs_sessions, rs_intakes, rs_requests, rs_consents'}
 if($id -like 'R-*'){return 'booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases'}
 if($id -like 'D-*'){return 'driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts'}
 if($id -like 'O-*'){return 'staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals'}
 if($id -like 'C-*'){return 'shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications'}
 return 'main/platform_store/theme/localized/common; core/endpoint/trips; rs_idempotency, rs_active, rs_audit, rs_settings'
}

$intro=@'
# RideShare: customer, driver and staff implementation plan

Revision: 11 October 2026, Asia/Dhaka. Target: `E:\Websites\Ride Share`. Client: Flutter/Dart Android and Flutter browser. Backend: own PHP/PDO with MySQL-compatible MariaDB. No external runtime APIs. Native iOS is deferred; an iPhone browser runs the web app. Hosting remains local at the user's request.

This revision supersedes the earlier synthetic showcase plan. The app now uses individual accounts and authoritative PHP/MySQL state. Refresh does not reset trips. There is no public role impersonation, fixed pickup PIN, customer driver-action button or portfolio page. The external portfolio website is a separate project.

Status words are deliberate: **Source implemented** means the current source contains the behavior, not that every acceptance clause has passed. **Partial** identifies outstanding software, device or operating-policy requirements. **Deferred extension** means omitted from the released interface. No row is declared fully accepted merely because a page exists.

## Product contract

- Customer owns booking, pickup/destination, quote acceptance, cancellation, proposed route changes, pickup PIN, receipt/rating/tip, own account and own support. Customer never accepts a driver offer, confirms arrival, starts, visits a stop or completes a ride.
- Assigned driver owns offer acceptance/decline, heading to pickup, proximity-validated arrival, PIN-validated start, ordered stop confirmation and completion/interruption. Identity/application checks and new-work eligibility remain server enforced. A restricted driver retains only safe recovery for an existing assignment.
- One active trip per customer, driver and vehicle. Distinct request keys cannot double-book. Availability, reachability and active assignment are separate. Going offline prevents new offers and preserves the passenger's trip.
- Own-server GraphHopper 11.1 computes road routes from imported OpenStreetMap data. Place search is database-backed. Maps/fonts/Flutter renderer are bundled or served from the same host. No public tiles, routing fallback, hosted identity, third-party analytics, SMS, push or payment gateways.
- Initial accepted price is locked upfront: road kilometers × database rate, seeded at BDT 100/km, rounded to whole BDT. No silent detour/waiting/cancellation/no-show charge. Authorized route changes require a new displayed price plus customer confirmation and assigned-driver acceptance.
- Driver remuneration is separately configured and journaled. Platform-funded promotions do not invent wallet money. Cash report, customer confirmation, outstanding receivable, reviewed adjustment, refund and actual manual payout are separate records. Approval is not payment. Failed/held manual executions produce no money journal.
- Immediate passenger Bike/Car/CNG/XL products only. Compatible, reviewed, reachable supply is required for each. No supply produces a genuine no-driver outcome. Electronic payments, stored-value wallet, automated cash-out, guest bookings, scheduled/Reserve rides, parcel, family billing, enterprise billing and native iOS are deferred and omitted from the interface.
- All displayed services must function. Do not show disabled unfinished cards, fake checks, invented drivers, made-up successful payment/delivery/screening, or a portfolio page inside the app.

## Permissions and sensitive data

| Context | Allowed scope | Boundaries |
|---|---|---|
| Customer | Own booking/trips/account/receipts/cases/requests | No driver or staff commands; only customer receives pickup PIN. |
| Driver applicant | Own application/vehicle documents/review status/help | No online offer eligibility until approved role and evidence. |
| Driver | Own approved work, assigned trip, earnings and cases | Cannot operate another driver's trip; ended customer identity/endpoints minimized. |
| Support | Routine cases and permitted case-linked trip context | Claim before reply; no safety evidence, arbitrary exact locations or unilateral money changes. |
| Safety | Restricted safety/appeals/exclusions/assistance | Evidence-purpose audit and separate serious-report route; no inherited finance/admin. |
| Dispatch | Matching, freshness, permitted intervention and assistance | Cannot impersonate driver start/completion; reason/version guards. |
| Onboarding | Driver/vehicle evidence and contact/identity review | Encrypted private files; clean scan and required evidence before eligibility. |
| Finance | Actual receivable/collection/earnings/refund/payout reports and reviewed proposals | Distinct requester/reviewer; exact hash/version; no routine precise-trip or safety-case access. |
| Supervisor | Eligible case assignment/workload and scoped reports | Cannot give staff unrestricted evidence merely by assigning a case. |
| Admin | Reviewed configuration/access, audit and scoped reports | No automatic finance, dispatch, safety or private trip privileges. |
| Compliance | Privacy/legal holds and purpose-limited audit/reports | Independently reviewed exports/deletion/holds; jurisdiction/authority/retention evidence. |
| On-call | Incident/release/implemented-feature cohort controls | No arbitrary customer evidence or money authority. |

Authorization is enforced by PHP on every read and mutation. Flutter visibility mirrors these permissions. Routine operational queues are masked; exact trip location requires a permitted, reasoned, audited five-minute reveal. Private intake content is decrypted only after role and purpose checks. Ordinary feedback is separate from urgent safety reports. Account appeals never implicitly restore booking or driver privileges.

## Implementation evidence and present limits

Active Flutter code is in `mobile/lib/features`, `mobile/lib/data` and `mobile/lib/ui`; active PHP code is `src/platform`, reached through `public/api.php` and `public/shared.php`. Schema is `database/platform.sql` plus additive `database/connected-upgrade.sql` and `tools/migrate_connected.php`. Legacy HTML/PWA and synthetic showcase code are not the active client.

Recorded current backend regressions passed 37 core, 20 extended, 23 completion, 17 post-trip/maintenance, 21 policy/support/retention, 15 settlement/reveal, five local backup/restore, three concurrent signup and five concurrent retention/hold checks: **146 checks**. Coverage includes real MySQL persistence, driver-only transitions/PIN privacy, concurrent accept race, scanning, specialist scope, exact approval binding, interrupted fare, partial cash/refund caps, failed manual execution/retry, lost-item consent, pending-tip correction, feedback editing, template audience/read state, restriction expiry, settlement holds and balanced journals. Test counts represent these scenarios, not all 172 acceptance stories.

Flutter analyzer is clean and **nine tests passed**, including navigation on temporary permission changes, revoked role cleanup, network/401 behavior, invalid money entry, 360px/simple/Bengali layout and keyboard-open place selection. The **10-check fresh connected browser journey passed** across independent Customer/Driver/Support accounts, real offers, assigned-driver arrival/PIN start/completion, both-party cash confirmation and local PDF download. No external runtime requests or browser exceptions were observed.

The latest signed **1.2.0+3** web/APK builds share the current source fingerprint. The APK is installed on Samsung SM_S938B and the Android emulator. Device journey/background/capture evidence is recorded separately under private `.local/verification` and `.local/capture-v3`; those exact records determine device acceptance. Release manifests and capture metadata bind actual hashes; previous artifacts are archived, never relabeled. Five native journey checks and five Samsung tracking checks passed, including background fresh GPS, network-loss exclusion and recovery. See [the verification report](Verification-Report.md) for exact scope. Five native journey checks and five Samsung tracking checks passed, including background fresh GPS, network-loss exclusion and recovery. See [the verification report](Verification-Report.md) for exact scope. Local tests use development fixtures and no real funds.

Automatic approval review is available again; the earlier allowance interruption no longer blocks verification. The user chose local testing and will provide HTTPS hosting later. This APK requires the computer backend and USB forwarding; it is not a remotely usable client release.

The local operations worker is running and fresh health probes are verified. Reviewed restriction/settlement lifecycle, feedback/tip edits, controlled replies, document crop and transactional retention were added. [Local operations and handoff](Local-Operations-and-Handoff.md) documents service startup, named staff provisioning, independent financial decisions, privacy/retention, backups and future hosting. Policies requiring human authority remain explicit prerequisites.

## Full story acceptance and traceability

All 172 original stories are preserved below, with Customer terminology and current implementation notes. Historical `R-` IDs remain stable for traceability; they are identifiers, not app role labels. Extension clauses describe future acceptance only and do not authorize visible unfinished services. Flutter paths below are relative to `mobile/lib/features`, PHP module names to `src/platform`. The listed tables identify persistence, not proof of passing every acceptance clause. Detailed remaining work takes precedence over broad source status.

'@
$builder=[System.Text.StringBuilder]::new($intro)
foreach($story in $stories){
 $id=[regex]::Match($story,'\*\*([A-Z]+-\d+[a-z]?)').Groups[1].Value
 if(!$id){throw 'Missing story ID.'}
 $status=if($id -eq 'O-19'){'Inapplicable: no ML model'}elseif($extensions -contains $id){'Deferred extension / implemented immediate subset'}elseif($partial -contains $id){'Partial'}else{'Source implemented; clause-level acceptance remains'}
 $text=$story -replace '\briders\b','customers' -replace '\brider\b','customer' -replace '\bRiders\b','Customers' -replace '\bRider\b','Customer'
 $text=$text.Replace('Disable the transfer control in standalone mode','Omit the transfer control in standalone mode')
 [void]$builder.AppendLine($text)
 [void]$builder.AppendLine()
 [void]$builder.AppendLine('  **Delivery status:** '+$status+'. **Implementation:** '+(Evidence $id)+'.')
 [void]$builder.AppendLine('  **Audit/fix:** '+$(if($notes.ContainsKey($id)){$notes[$id]}else{'Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.'}))
 [void]$builder.AppendLine()
}
$closing=@'
## Gap closure and remaining coordinated work

| Gap | Current fix | Remaining acceptance |
|---|---|---|
| G-01 hidden driver app | Native Android foreground service, local heartbeats, freshness-based offers | Samsung lock/background/battery saver/restart/permission loss and missed-alert matrix. |
| G-02 fare contract | Locked upfront road fare, independent earnings, immutable balanced journals, interrupted review | Targeted adjustment/snapshot checks passed; approved operating rates remain. |
| G-03 exclusivity/eligibility | Unique active guards, transaction race, canonical readiness, safe assigned-trip recovery | Final navigator/tracking and separate-device recovery tests. |
| G-04 debt/refund | Actual remaining balance, partial collection, caps, failure/hold/retry evidence | Targeted correction/settlement checks passed; finance operating owner remains. |
| G-05 pairing safety | Case-linked temporary exclusion and late-accept recheck | Approved duration/confidentiality rules and staffed review. |
| G-06 fatigue | Durable work/rest fields and new-offer readiness | Advance warning implemented; approved definitions/limits/reset/exception policy and device matrix remain. |
| G-07 identity | Manual recheck tasks/evidence and new-work restrictions | Documented actual local evidence procedure and reviewer coverage. |
| G-08 payout changes | Local step-up/review, security notice, snapshotted destination | Hold/release/pending ownership pause and snapshots tested; actual prior-channel verification procedure remains. |
| G-09 product safety | Capacity, helmets/equipment, genuine vehicle compatibility | Chosen local age/assistance/vehicle legal rules, routing legality checks. |
| G-10 breakdown | Interrupted trip, finance fare/earning review, vehicle hold, open assistance | Staffed response and consented feasible replacement scenario. |
| G-11 terms | Versioned display/acceptance and immutable accepted snapshot | Policy owner approves wording; optional consent remains separate. |
| G-12 restricted help | Protected signed-out/suspended intake/status and independent recovery | Actual identity verification and response procedure. |
| G-13 concurrency | Stale version rejection, hash-bound dual approval, single execution | Sensitive reveal expiry and lifecycle tests passed; five actual concurrent legal-hold/retention checks passed; broader lifecycle interleavings remain. |
| G-14 guest rides | Explicit deferred extension, omitted UI | Separate authorized implementation later. |
| G-15 scheduling | Explicit deferred extension, omitted UI | Separate authorized fulfillment model later. |

Foundation B-01–B-15 are now represented by owned history, driver career aggregates, journal earnings, real offers, unique active guards, private pickup PIN, working safety/share, actual cash records, specialist RBAC, reviewed driver evidence, restricted safety intake, driver-linked cases, local authentication/recovery, live eligibility and local runtime assets. This describes code remediation; it does not waive outstanding story clauses or claim every release gate passed.

### Coordinated acceptance and remaining work

1. Preserve the 146 backend/nine Flutter/10 connected browser records and the current source fingerprints. Five true concurrent legal-hold/retention checks passed with an observed blocked MySQL query; aggregate counts do not substitute for each story clause.
2. Preserve the five-check native customer/assigned-driver journey and five-check Samsung foreground/background/network tests, bound to this APK. Battery saver, lock, OS permission revocation, killed-process and screen-reader/large-text scenarios require actual device evidence; no blanket background guarantee.
3. Remaining software clauses: driver destination/area preferences, rule-backed incentives/progress, general polygon/time preview, scheduled terms/promotions, risk/stuck-trip queues, periodic access review/break-glass, complete dynamic/error localization and disclosure deadline/inventory. Implement these against explicit local contracts; never display fabricated or unfinished services.
4. Retention dry-run/apply and local backup restore passed on isolated fixtures. Obtain an approved real retention basis, off-device encrypted backup location and actual recovery objectives before real operations. Financial journals and lawful holds stay protected.
5. Keep exact-hash signed APK/browser artifacts and native video, captions and transcript together. Capture labels distinguish Samsung and emulator; exclude credentials, notifications and supplied reference footage. The separate portfolio website is outside this app.
6. Hosting remains local. When an owned HTTPS origin is supplied, deploy PHP/private code/database/router/scanner, rebuild Android with that URL and retest browser/device access. The local USB-dependent APK is not a working remote download.
7. Named owners must approve transport/equipment/routing legality, fatigue/contact/identity/cash policies, terms, privacy and staffed support/safety/on-call response. No test can manufacture those operating decisions.

### Acceptance scenario inventory

A-01 physical lock/navigation/restart/background; A-02 distinct-key concurrent booking/accept; A-03 offline or mid-trip restriction preserving current assignment; A-04 disabled product/incompatible vehicle/late exclusion; A-05 required wrong/missing PIN; A-06 accepted price under detour/GPS/router failure; A-07 breakdown/partial fare/open assistance; A-08 disputed/partial cash and repeated execution; A-09 refund approved but actual repayment fails; A-10 recovery then payout destination change; A-11 work limit/identity/equipment failure; A-12 concurrent staff edits/changed approved amount; A-13 signed-out/suspended appeal and urgent report; A-14 immutable historical snapshots despite later policy/profile/vehicle changes; A-15 standalone network/dependency failure; A-16 guest/schedule extension omitted or explicitly selected. A-16 does not silently activate deferred extensions. Add A-17 for data lifecycle/legal holds, A-18 for required terms revision and A-19 for transient permission changes preserving navigation.

### Corner cases that must remain explicit

Permission-denied/approximate/stale GPS uses manual pickup alternatives, never a silent location jump. Outside-market or unsnappable points and unavailable local routes fail clearly, never fetch an external fallback. Expired quotes or materially changed terms require fresh review. No eligible reachable driver yields no-match. Wrong PIN, competing accepts, stale versions and lost responses cannot advance unauthorized state. Changed stops need both-party agreement and cannot erase visited stops. Cancellation does not mean a driver has completed a trip. Interrupted fare remains under review rather than claiming zero payment. Financial confirmation is independent and evidenced; failed/held execution cannot appear paid. Safety/help never requires settling debt or rating. Deleted/restricted accounts do not erase lawful evidence or restore new work. Browser hidden timers are not a background-location guarantee. Role loss clears protected routes, while ordinary assignment permission changes retain current navigation.

## Real-use launch prerequisites

Development fixtures are isolated test data, not authentic passenger operations. `real_operations` remains false until named owners approve transport/product/equipment/routing legality, contact/identity checks, cash/driver remuneration and fatigue policies, terms, privacy/retention and support/safety/on-call response. Technical completion alone cannot supply human staffing or legal authority. No external integration is required to complete locally supported cash/manual-review workflows.

Release acceptance requires consistent source/migration/build/capture versions, approved scopes, no customer driver controls, server authorization and private data tests, verified local routing/scanning, balanced journals and concurrency, complete core UI journey, actual supported-device evidence, documented deferred features, own HTTPS delivery when publishing, backup/restore rehearsal and traceable results. Do not mark the whole plan complete until these conditions are met.

## Reference video and design evidence

The supplied `C:/Users/ASUS/Downloads/Screen_Recording_20261010_231328_Uber.mp4` is 343.65 seconds, 1080×2340; its full timeline was reviewed with frame sampling. It informs Customer UI patterns, not unobserved driver/admin functionality or a completed ride. Original RideShare mint/dark branding adapts four-tab navigation, editable pickup/destination, map and product sheet, clear request action, chronological Activity/Rebook, account/help/inbox/safety. SafeArea, keyboard insets, 48dp targets, larger simple-mode controls, reduced motion and explicit loading/empty/error states remain required. No Uber branding, private account data or reference footage is part of the public release.

Imported maps retain OpenStreetMap/ODbL attribution and provenance. Imported road topology is an input, not proof of every motorcycle/CNG legal route. Research references in the archived original plan are background evidence, not permission to add external APIs or copy another service's operating policy.
'@
[void]$builder.AppendLine($closing)
$builder.ToString() | Set-Content -LiteralPath (Join-Path $docs 'RideShare-User-Stories-and-Implementation-Plan.md') -Encoding UTF8

$gap=@'
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
'@
$gap | Set-Content -LiteralPath (Join-Path $docs 'Portal-Feature-Gap-Analysis.md') -Encoding UTF8

$delivery=@'
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
'@
$delivery | Set-Content -LiteralPath (Join-Path $docs 'Flutter-Mobile-and-Portfolio-Delivery.md') -Encoding UTF8

$readme=@'
# RideShare — Flutter/Dart with a connected PHP/MySQL backend

Android-first Customer, Driver and specialist staff app, plus the same Flutter browser client. Individual accounts and internal PHP/PDO endpoints use durable MySQL-compatible MariaDB state. Customer cannot accept, arrive, start or complete a driver's ride. Only the assigned driver controls those transitions. No external runtime APIs and no portfolio page are included.

Active client: `mobile/lib`. Active backend: `src/platform`, exposed through `public/api.php` and `public/shared.php`. Schema: `database/platform.sql` plus `connected-upgrade.sql` and additive `tools/migrate_connected.php`. Legacy synthetic showcase/HTML code is not the current client. Database refresh does not reset trips or produce invented earnings.

Own local test services are MariaDB 3317, PHP/static app 8098, GraphHopper 8989 and ClamAV 3320 on loopback. Open `http://127.0.0.1:8098/demo/` when all required services are running. A standalone static server on the former 8097 port is not the connected app. Flutter browser calls its own origin; Android has a build-time backend URL. Never connect Flutter directly to MySQL.

Build with `tools/build.ps1 -Target all -JavaHome E:\Java`, using the local Flutter/Android SDK and checked R-drive project alias. It runs analyzer/tests, builds web with bundled renderer assets and signs Android using the private release keystore, then stages hash-bound public artifacts. Keep `.local`, `.tools`, signing identity/passwords, test credentials, private documents and reference video outside the public web root.

Immediate cash passenger rides, genuine driver offers, private pickup PIN, route changes with both-party consent, safety/support/lost items, receipts/history/rebooking, documents, journal earnings and separately approved manual money/configuration/access workflows are implemented in source. Electronic payments, instant cash-out, stored-value wallet, guest/scheduled/parcel/family/enterprise extensions and native iOS are omitted. Android is installed natively; iPhone access is through its browser.

Current evidence: 146 backend checks, clean Flutter analyzer, nine Flutter tests and 10 connected browser journey checks. The navigator reset and keyboard-covered place list were fixed and regressed. Current signed 1.2.0+3 is installed on Samsung and emulator. Five native journey and five Samsung tracking checks passed on this exact APK. The 45-second actual Android walkthrough, captions and transcript are staged; story-level partial clauses remain in the plan.

The user chose local testing until a hosting URL is supplied. USB forwarding lets the Samsung reach the computer's backend; this localhost APK will not work independently for remote clients. Later deployment needs an owned HTTPS PHP host, private database/routing/scanner/storage and a rebuilt APK. The separate portfolio website will link the app, APK and actual Android walkthrough; this repository does not add that website.

The earlier approval-review allowance interruption is resolved. Local services and operations worker are running. Use `tools/start_local.ps1` to start or reuse only this project’s services; see the local operations runbook.

- [Full implementation plan and all 172 acceptance stories](docs/RideShare-User-Stories-and-Implementation-Plan.md)
- [Portal gap audit](docs/Portal-Feature-Gap-Analysis.md)
- [Mobile and external portfolio delivery](docs/Flutter-Mobile-and-Portfolio-Delivery.md)
- [Local operations and handoff](docs/Local-Operations-and-Handoff.md)
- [Verification report](docs/Verification-Report.md)
'@
$readme | Set-Content -LiteralPath (Join-Path $root 'README.md') -Encoding UTF8
Write-Output 'Updated four documents; preserved 172 acceptance stories and archived the prior plan privately.'



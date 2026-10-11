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
- **ID-01 — Create account:** As a guest, I want a local account with contact status that accurately reflects verification. Accept: validate/normalize contact; secure password signup; prevent duplicate creation without enumeration; disclose required data/terms; show field errors/accessibility; local/manual contact checks have evidence/actor/status and must satisfy chosen eligibility policy before required privileges; never treat password signup as phone verification. SMS/email one-time challenges are deferred integration behavior with expiry/reissue/rate-limit requirements if later enabled.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** auth/account/requests; identity/extensions/operations/account_policy; rs_users, rs_sessions, rs_intakes, rs_requests, rs_consents.
  **Audit/fix:** Canonical phone normalization, password hashing and non-enumerating signup exist. Two real concurrent processes returned identical results and produced exactly one customer account/grant/consent; three regression checks passed.

- **ID-02 — Sign in:** As a returning user, I want to sign in securely so that I can resume my account. Accept: support selected methods; rate-limit attempts; provide non-enumerating errors; allow password manager/paste where passwords exist; announce pending/success/error accessibly.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** auth/account/requests; identity/extensions/operations/account_policy; rs_users, rs_sessions, rs_intakes, rs_requests, rs_consents.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **ID-03 — Recover access:** As a user who lost access, I want a safe recovery path so that I regain control without exposing account existence. Accept: challenge old/new channel per risk policy; revoke suspicious sessions; show recovery status and support route.

  **Delivery status:** Partial. **Implementation:** auth/account/requests; identity/extensions/operations/account_policy; rs_users, rs_sessions, rs_intakes, rs_requests, rs_consents.
  **Audit/fix:** Protected manual recovery intake, independent review and revoked sessions exist. Old/new contact verification procedure requires an operating owner.

- **ID-04 — Session/device control:** As a user, I want to see/revoke sessions so that I can protect my account. Accept: show device/time; revoke individual/all other sessions; confirm high-impact action; notify on security events.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** auth/account/requests; identity/extensions/operations/account_policy; rs_users, rs_sessions, rs_intakes, rs_requests, rs_consents.
  **Audit/fix:** Other-session revocation requires confirmation, revokes immediately and writes a security notice; backend/session regressions passed.

- **ID-05 — Role profile:** As a user who is both customer and driver, I want to switch work context without confusing permissions. Accept: explicit role context; retain same identity; never expose another role’s restricted records.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** auth/account/requests; identity/extensions/operations/account_policy; rs_users, rs_sessions, rs_intakes, rs_requests, rs_consents.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **ID-06 — Account deletion/data request:** As a user, I want to request deletion or a copy of my data. Accept: explain dependencies/retention exceptions; verify identity; submit and track request; never promise deletion where legal retention applies.

  **Delivery status:** Partial. **Implementation:** auth/account/requests; identity/extensions/operations/account_policy; rs_users, rs_sessions, rs_intakes, rs_requests, rs_consents.
  **Audit/fix:** Reviewed export/deletion and legal-hold checks exist. Authority, deadlines and approved retention values remain policy prerequisites.

- **ID-07 — Versioned agreements and consent:** As a customer/driver, I want to review the terms and permissions that apply to my account and trip. Accept: locally stored version, locale, effective time and acceptance evidence; required reacceptance for applicable changes; trip references accepted fare/cancellation terms; optional marketing/contact/location-sharing/recording consent remains separate and revocable where applicable; no retroactive rewrite of an active trip's contract.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** auth/account/requests; identity/extensions/operations/account_policy; rs_users, rs_sessions, rs_intakes, rs_requests, rs_consents.
  **Audit/fix:** Quote terms are displayed and accepted with version evidence; changed required terms require requoting. Optional channels must stay separate.

- **ID-08 — Restricted recovery, appeal and urgent intake:** As a signed-out or suspended user, I want a verified way to regain access, appeal or report danger. Accept: locally operated staff-assisted intake and restricted case access; non-enumerating responses/rate limits; identity evidence appropriate to purpose; case reference/status; no normal booking/driver privilege restored by an appeal session; safety/help cannot depend on paying debt or submitting a rating; no SMS/email API dependency.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** auth/account/requests; identity/extensions/operations/account_policy; rs_users, rs_sessions, rs_intakes, rs_requests, rs_consents.
  **Audit/fix:** Signed-out urgent/recovery intake and restricted status link are implemented; reviewing an appeal never grants normal marketplace privileges.

- **R-01 — Set pickup by location:** As a customer, I want to use my current location so pickup starts near me. Accept: ask permission in context; show accuracy; offer manual fallback; handle denied, approximate, stale, and unavailable location; require confirmation before request.

  **Delivery status:** Partial. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Device location, accuracy, manual place/map/coordinate alternatives and explicit pickup confirmation exist; physical permission-denial/approximate-location testing remains.

- **R-02 — Search pickup:** As a customer, I want to search an address/place so I can choose an exact pickup. Accept: accessible suggestions; loading/empty/error states; disambiguate similar names; never silently replace a confirmed selection.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **R-03 — Move pickup pin:** As a customer, I want to move the pickup pin to a valid nearby point. Accept: snap/validate within service rules; show address and pickup notes; provide keyboard alternative to drag.

  **Delivery status:** Partial. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Pan/zoom and tap-to-select map with manual coordinates provide alternatives to dragging. A selected point must pass service boundary and road-snap validation.

- **R-04 — Search destination:** As a customer, I want suggestions and recent places so destination entry is quick. Accept: debounce/failure handling; select exact result; distinguish pickup from destination; support edit/clear.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **R-05 — Confirm route:** As a customer, I want to review pickup, destination, route and ETA. Accept: map and text route summary; handle missing route/provider outage; explain estimate status.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **R-06 — Compare ride products:** As a customer, I want to compare available ride types. Accept: only eligible products; capacity, ETA and price/estimate visible; accessibility options named; unavailability explained.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Database products/capacity/price are displayed. Each type still requires genuine approved compatible supply; no fake driver is assigned when supply is absent.

- **R-07 — View fare:** As a customer, I want to see applicable fare before requesting. Accept: currency, estimate/upfront semantics, known fees and policy; stale quote expires visibly; changed quote requires renewed confirmation.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Locked upfront road fare, terms, quote expiry and own-server pickup ETA are implemented; connected customer/driver booking passed.

- **R-07a — Database mileage pricing:** As a customer, I want the fare quote to show distance × the configured rate so that the amount is understandable. Accept: quote reads active per-product rule from MySQL; initial configured rate is ৳100/road-km; show route distance, rate, BDT total and rounding; persist the quote/rate/version; no hidden base/surge; any later fee is a disclosed DB line item.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Local GraphHopper route, database rate and deterministic whole-BDT rounding exist; accepted rates/routes are immutable snapshots.

- **R-08 — Select payment:** As a customer, I want to choose an available payment method/profile. Accept: show saved/eligible methods; explain cash/business restrictions; hide full card details; preserve method in quote.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Cash and personal travel profile are supported. Electronic payment credentials and business billing are outside the selected release.

- **R-09 — Add payment method [gateway extension]:** As a customer, I want to securely add an enabled electronic payment method. Accept if later enabled: tokenized provider UI; validation/provider errors; never store raw card security code; require usable method when policy requires. Standalone release exposes configured cash rules only; no card/bKash connection or charge is implied by a saved label.

  **Delivery status:** Deferred extension / implemented immediate subset. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Deferred external gateway extension. No card, bKash, top-up or electronic charge controls are shown.

- **R-10 — Apply credit/promo:** As a customer, I want to apply eligible credits. Accept: show eligibility, expiry, amount and remaining charge; remove/retry; prevent double redemption.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Eligible database promotions reduce the customer fare without silently reducing the configured driver remuneration. Stored-value credits are omitted.

- **R-11 — Submit ride request:** As a customer, I want one clear request action. Accept: server validates quote, account, location, payment precondition, eligibility and duplicate idempotency; button locks pending; success returns durable trip ID; failure gives recovery.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **R-12 — Match progress:** As a customer, I want to know matching is in progress. Accept: persistent status, elapsed time and cancel path; no fabricated driver/ETA; recover across refresh/reconnect.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **R-13 — No driver available:** As a customer, I want an honest no-match outcome and alternatives. Accept: preserve request details; offer retry/edit/later options; do not charge for unassigned request.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **R-14 — Driver assigned:** As a customer, I want verified driver and vehicle details. Accept: show permitted photo/name/rating/vehicle/license; announce state changes; never encourage entering a mismatched vehicle.

  **Delivery status:** Partial. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Immutable driver/vehicle make/model/color and optional clean approved JPEG/PNG profile-photo snapshots exist. Final optional-photo/native evidence coverage remains.

- **R-15 — Track approach:** As a customer, I want driver location and pickup ETA. Accept: timestamp/freshness; distinguish stale vs live; map failure retains text location/ETA; avoid unnecessary post-trip precision exposure.

  **Delivery status:** Partial. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Freshness/accuracy/reachability are shown; local road-based pickup ETA was added. Samsung foreground/background GPS freshness, disconnect exclusion, recovery and tracking stop passed five checks; lock/battery/permission/killed-process scenarios remain.

- **R-16 — Contact driver:** As a customer, I want private trip-scoped in-app messages and supported contact options. Accept: internal conversation, permission/availability feedback, canned text and accessible controls, durable failed-send/retry state; external masked calling stays disabled. Any selected direct device-dial contact requires explicit limited disclosure/consent and a support-mediated alternative; no personal number in post-trip history and no falsely claimed message delivery.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Private trip messages and canned pickup messages exist. No external call proxy, automatic SMS or delivery guarantee is claimed.

- **R-17 — Cancel request/trip:** As a customer, I want fee and consequence disclosed. Accept: show policy fee before final confirm; handle race if driver starts/arrives; single cancel outcome; review path.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **R-18 — Driver cancels:** As a customer, I want to know cancellation and whether rematching will occur. Accept: clear state, fresh ETA or choice to stop; no double charge; preserve quote or explain change.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **R-19 — Pickup wait/no-show:** As a customer, I want arrival/wait status clear. Accept: arrival evidence/status; timer and fee rules visible; contact/cancel/help actions; handle location mismatch.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Proximity-checked arrival, server waiting time, five-minute no-show threshold and no automatic waiting fee are implemented.

- **R-20 — Verify pickup/PIN:** As a customer, I want an optional PIN check. Accept: show PIN only to customer/authorized party; driver receives result not secret; wrong/expired code cannot start; accessible fallback per policy.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Per-trip encrypted PIN is exposed only to the customer and validated by the assigned driver start endpoint. Required PIN cannot be bypassed by customer UI.

- **R-21 — Share trip:** As a customer, I want to share a time-limited trip link. Accept: explicit share action; minimum trip information; link expires/revokes; recipient gets no account access.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Time-limited own-server share links and owner revocation are implemented; no external messaging API is required.

- **R-22 — Safety toolkit:** As a customer, I want safety and help controls during a trip. Accept: visible entry point; distinct urgent/nonurgent actions; emergency call labeled; explain location/trip disclosure; never block direct emergency calling.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Safety hub, urgent case intake and emergency calling/manual fallback exist; local anomaly checks have owned cases. Emergency staffing is an operating prerequisite.

- **R-23 — Emergency action:** As a customer in immediate danger, I want a clear way to contact local emergency services. Accept: configured local number, emergency context, required data only; no claim RideShare dispatches responders; preserve state after return.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Bundled local emergency information and native dialer/manual number fallback exist; no automatic dispatch or external emergency handoff is claimed.

- **R-24 — Add/edit stops:** As a customer, I want to manage allowed stops. Accept: enforce market limit; recalculate route/price/ETA; notify driver; confirm material price/policy change; reject invalid order/zone.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Ordered stops, road repricing and customer confirmation plus driver acceptance exist. Already-visited stops cannot be silently reordered.

- **R-25 — Change destination:** As a customer, I want to update destination during a trip. Accept: recalculate under market rules; confirm charge impact; handle unavailable route with support path.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Customer proposes a new destination; only assigned driver can accept the change; expired/stale changes fail.

- **R-26 — Trip status/reconnect:** As a customer, I want current trip state after lost connection or refresh. Accept: server is source of truth; replay safe state; never regress completed trip or duplicate request/payment.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Authoritative refresh/poll/resume and persisted operation keys exist. Latest navigator correction preserves active trip when temporary permission changes.

- **R-27 — Complete trip:** As a customer, I want a clear trip-complete summary. Accept: authorized completion transition; show final fare, payment and receipt; allow help if payment pending.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **R-28 — Rate/feedback:** As a customer, I want to rate and optionally explain. Accept: configured scale, skip path, structured tags/text limits, sensitive report routes separately from ordinary feedback.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Versioned 1–5 feedback, three validated optional tags and configured edit deadline are implemented. Ownership, stale edits and window checks passed.

- **R-29 — Tip:** As a customer, I want to add/edit an allowed tip. Accept: amount/payment source clear; bounded validation; receipt/correction rules; avoid accidental selection.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Pending tips can be corrected or cancelled through append-only journal deltas. Driver confirms the current amount; received tips require reviewed correction. Regression passed.

- **R-30 — Trip history, trip detail and receipt:** As a customer, I want to review each past ride, who drove me, where I traveled, and what I paid. Accept: paginated/searchable own-trip history; trip detail shows driver display name and trip-time vehicle identity (vehicle type/make/model/color and plate where policy permits), pickup, destination and authorized stops with route/map summary, product, local date/time, duration and distance; itemized calculation shows configured distance × rate plus any disclosed minimum, toll, fee, tax, promotion, tip or adjustment, then payment method/status and final total; canceled/no-match trips clearly show status and whether any fee was charged; receipt is printable/shareable without exposing another customer’s data; show missing-detail/report and fare-review paths; every dynamic field comes from the authenticated trip, quote, driver snapshot and ledger records in MySQL.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Owned paginated history, immutable receipt snapshots, rebook and bundled-font PDF exist. The fresh connected browser receipt downloaded successfully.

- **R-31 — Trip help:** As a customer, I want issue categories tied to a trip. Accept: trip preselected; branching form asks only needed data; attachment progress/privacy notice; case ID/status.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **R-32 — Fare review/refund:** As a customer, I want to dispute a fee/charge with context. Accept: category-specific evidence; dedupe; no guaranteed refund before review; outcome and adjustment ledger visible.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Fare reductions adjust actual debt/final fare without inventing wallet money; refund caps use actual collection. Independent approval and targeted regressions passed.

- **R-33 — Lost item:** As a customer, I want privacy-safe coordination about a lost item. Accept: masked contact where possible; consent before information sharing; trip context; no unsafe direct contact requirement.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Trip-linked lost-item report, driver finding, both-party consent and both return confirmations exist; no personal phone/home disclosure or invented return fee.

- **R-34 — Support conversation:** As a customer, I want to read/reply to support. Accept: timestamps/status; new-message notification; safe attachments; reopen/escalate by policy.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **R-35 — Outstanding fare recovery:** As a customer, I want to understand and settle or dispute an unpaid amount. Accept: show original trip, charge, collection/adjustment and remaining amount from ledger; no debt invented from one party's unreviewed cash assertion; disclose booking restriction and review route; standalone settlement uses approved cash/manual evidence and staff confirmation; electronic retry is disabled until a future gateway exists; safety/help remains accessible; collection and dispute outcomes are idempotent.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Outstanding actual receivable and partial manual collection are shown with dispute/help. No debt is silently attached to a future trip.

- **R-36 — Refund progress:** As a customer, I want to track an approved refund through actual repayment. Accept: requested/approved/awaiting execution/paid/failed states appropriate to manual standalone handling, amount/destination/reference and policy timing; payment requires verified cash-handoff/transfer evidence; failed or partial repayment has a finance owner and support path; provider-submitted/pending states are future extensions; approval alone never means funds received.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Manual repayment approval, held/failed attempts and evidenced execution are distinct; approval alone is never paid.

- **R-37 — Safety matching exclusion:** As a customer, I want a reviewed way to avoid a future pairing after a safety concern. Accept: trip-linked request, confidential scope/reason, immediate temporary exclusion when authorized, review/expiry/reversal, server enforcement on candidate selection/accept/rematch and honest no-eligible-driver result; do not expose the complainant's evidence or use this as an unapproved demographic preference.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Safety specialist case-linked exclusions are enforced in matching/late accept. Duration is a development policy value awaiting operating approval.

- **R-38 — Passenger needs and product safety:** As a customer, I want to know whether the chosen service can accommodate my party safely. Accept: passenger count, supported mobility aids/luggage/assistance and vehicle capabilities come from local configuration; truthful unavailable outcome; minimal relevant data only; age/unaccompanied-minor/child-seat and Bike passenger-equipment policies chosen before enabling the relevant product; refusal/equipment-missing fee treatment and discrimination complaint path are explicit.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Passenger capacity, helmets/luggage requirements and unsupported wheelchair supply checks exist. Local product/age/legal rules need an operating owner.

- **R-39 — Interrupted ride and assistance:** As a customer, I want a clear outcome after breakdown or an unsafe early ending. Accept: distinct interrupted/partially completed outcome with confirmed time/location/reason; reviewed charge/refund and linked driver earning; owned customer-assistance task remains open independently of trip termination; replacement offered only when safely feasible and explicitly accepted; original/replacement/incident linked, cost of each leg disclosed; no promise of automatic rescue or replacement.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Interrupted outcome, separately reviewed fare/earning, failed vehicle hold and open assistance case exist. A new consenting booking does not imply guaranteed replacement supply.

- **R-40 — Guest passenger booking [extension]:** As a booker, I want to request a ride for another permitted passenger. Accept only when enabled: distinct booker/passenger/payer; consented verified contact; cancellation/change/payment authority; driver-visible recognition and guest PIN/safety route; limited expiring internal trip link; in-app/link notification failure and manual handoff; no booker wallet/account access; concurrency exception explicitly configured, otherwise X-11 applies; SMS delivery remains disabled in standalone mode.

  **Delivery status:** Deferred extension / implemented immediate subset. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Deferred guest booking extension. No guest passenger controls or unverified guest contacts are shown.

- **R-41 — Scheduled fulfillment [extension]:** As a customer, I want a future ride with an honest service promise. Accept only when enabled: lead time/timezone, modification/cancel cutoff, price terms, assignment window, driver commitment/eligibility, in-app reminders, late changes/wait/no-show rules, no-driver outcome and recovery; a stored timestamp is not a guaranteed reservation; no external notifications or provider dependency silently introduced.

  **Delivery status:** Deferred extension / implemented immediate subset. **Implementation:** booking/trip/history/safety/support/requests; trips/extensions/cash/support/post_trip; rs_quotes, rs_trips, rs_active, rs_events, rs_journals, rs_cases.
  **Audit/fix:** Deferred scheduled rides extension. No Later/Reserve controls or guaranteed reservation claim are shown.

- **D-01 — Enroll as driver:** As a prospective driver, I want market requirements before applying. Accept: local age/license/vehicle/permit rules; no cross-market assumptions; save progress.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Applicant enrollment is separate from approved driver access; enrollment never grants dispatch privileges.

- **D-02 — Submit identity and vehicle:** As a driver, I want to enter data once. Accept: validation, privacy disclosure, review summary, duplicate identity handling.

  **Delivery status:** Partial. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Vehicle/application storage and latest make/model/color fields exist. Adding a new vehicle preserves the old approved selection pending review.

- **D-03 — Upload document:** As a driver, I want to upload each required document. Accept: format/size limits, crop/preview/retry, quality hints, progress, malware scanning and encryption.

  **Delivery status:** Partial. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Encrypted scanned private documents, image header/size checks and adjustable image crop exist. Native crop-output/upload and visual quality coverage remains.

- **D-04 — Document review state:** As a driver, I want status and actionable rejection reason. Accept: pending/approved/expired/rejected; reviewer reason; reupload; notification; no activation while incomplete.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **D-05 — Identity/screening check:** As a driver, I want an accurate status and appeal route for applicable checks. Accept: documented locally performed review/evidence, consent/jurisdiction, pending when a required result is unavailable, no unsupported screening promises, adverse action review path, sensitive details restricted. External screening providers remain deferred; continuing checks follow D-42.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Manual evidence-based identity status and appeal exist; no unperformed external background check or biometric verification is claimed.

- **D-06 — Vehicle eligibility:** As a driver, I want eligible vehicles and required evidence. Accept: market/product/date/capacity/equipment rules; expiry reminders; replace vehicle; block new assignments when eligibility lapses; current-trip handling follows O-38/R-39 and never silently strands the customer.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **D-07 — Driver readiness:** As a driver, I want permission/network/readiness checks. Accept: explain purpose; manual troubleshooting; no unjustified GPS tracking offline.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **D-08 — Go online/offline:** As a driver, I want to control availability. Accept: authoritative state; offline prevents new offers; active-trip exception; stale connectivity shown.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Desired availability is independent of active assignment; offline prevents new offers and preserves the current trip.

- **D-09 — Preferences:** As a driver, I want eligible trip preferences. Accept: effective settings visible; unavailable combinations validated; no unapproved demographic matching promises.

  **Delivery status:** Partial. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Product/equipment eligibility is enforced. Broader destination/area trip-preference controls require an explicit implemented matching contract.

- **D-10 — Offer details:** As a driver, I want permitted trip/earnings information to decide safely. Accept: market-controlled fields; time limit; no misleading earnings estimate; distinguish offer types.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **D-11 — Accept offer:** As a driver, I want an offer assigned once. Accept: atomic reservation, expiry/race handling, confirmation; reject duplicate; reconcile lost response by state lookup.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Transactional accept, unique customer/driver/vehicle guards and real concurrent race verification exist. Customer has no accept authority.

- **D-12 — Decline/timeout:** As a driver, I want to decline or let an offer expire. Accept: no accepted assignment or charge created by decline/timeout; the customer's durable request can continue matching or reach no-match; release offer lease safely; metrics follow disclosed policy; no hidden penalty claim.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **D-13 — Navigate to pickup:** As a driver, I want pickup navigation/contact. Accept: navigation fallback; preserve destination; safe targets; no complex in-motion interaction prompt.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **D-14 — Mark arrived/wait:** As a driver, I want arrival and timer. Accept: server timestamp, location confidence, policy timer/fee, state recovery.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Assigned driver arrival checks fresh nearby GPS; server waiting display exists and separate-device journey verifies arrival.

- **D-15 — customer no-show/cancel:** As a driver, I want documented no-show/cancel. Accept: policy conditions, reason, evidence, no false arrival; customer notification/dispute path.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **D-16 — Verify customer/start:** As a driver, I want trip/PIN verification. Accept: correct trip only; retry limit; no other-trip exposure; safe accessible fallback.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Only assigned eligible driver starts using customer PIN; server never returns the secret to driver. This is not a customer action.

- **D-17 — Active trip/stops:** As a driver, I want authorized route updates. Accept: server-authorized changes, fare/time effect visible, navigation refresh and audit.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **D-18 — Safety/crash report:** As a driver, I want emergency, crash, and nonurgent report paths. Accept: emergency separate from routine report; immediate guidance; no unsafe typing while moving.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **D-19 — Complete ride:** As a driver, I want a clear end-trip action and earnings. Accept: authorized completion; duplicate taps idempotent; ledger item once; cash status handled.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Assigned-driver-only completion, durable trip outcome, balanced journals and released active guards passed the connected journey.

- **D-20 — Driver rating/report:** As a driver, I want to rate/report after a trip. Accept: post-trip only; confidential reporting; safety categories restricted.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **D-21 — Earnings ledger:** As a driver, I want trip/period totals. Accept: gross/net, tips/fees/adjustments, timezone, pending/settled; reconcile to ledger.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **D-22 — Payout setup/status:** As a driver, I want eligible manual settlement destination and status. Accept: private, verified destination record under D-43; accrued/approved/awaiting execution/paid/failed/reversed/held as applicable; actual payment evidence/reconciliation; no duplicate payout; support route. Provider tokenization/transfers are deferred extensions and no raw credentials are stored.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Reviewed manual payout destinations are immutable execution snapshots. Pending ownership changes pause execution; independent holds/releases and failed attempts are tested.

- **D-23 — Cash-out [automated extension]:** As a driver, I want allowed automated cash-out if a future integration is enabled. Accept then: eligibility/fee/limit shown; confirmation; idempotency; pending/failed/reversed states. Omit the transfer control in standalone mode; a manual settlement request, if offered, follows D-22/O-27 and does not claim immediate funds movement.

  **Delivery status:** Deferred extension / implemented immediate subset. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Deferred automated cash-out extension. No instant transfer button is shown; manual settlement is a separate reviewed workflow.

- **D-24 — Promotions/opportunities:** As a driver, I want eligible conditions explained. Accept: dates/zones/rules/progress/exclusions/final amount; no hidden retroactive conditions.

  **Delivery status:** Partial. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Driver incentive/opportunity rules and a complete progress/eligibility UI are not configured. Do not show fabricated incentive cards; implement when real local rules are chosen.

- **D-25 — Driver inbox/support:** As a driver, I want messages in one inbox. Accept: accessible unread count; direct workflow links; conversation history; notification controls.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **D-26 — Account restriction/appeal:** As a driver, I want reason and review path. Accept: impact/effective time, appropriate disclosure, evidence, status/owner; high-impact decisions logged.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **D-27 — Shift/session control:** As a driver, I want to see whether I am offline, available, paused, or on an active trip and deliberately end a work session. Accept: server-authoritative state; ending a session never interrupts a trip; availability is distinct from login; status change confirms only after server acknowledgement.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Durable shift start/end and availability states exist. Duplicate online/offline actions must not reset accumulated work.

- **D-28 — Session wrap-up:** As a driver, I want a clear summary after going offline. Accept: online duration and offer/trip counts reconcile to events; canceled/no-show status is separated; fare, cash collected, tips, adjustments and payout-pending amounts are broken out; timezone and date range are explicit.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Durable shift times, work duration, offer/outcome counts, cash, tips, earnings and pending/net payable are implemented; duplicate availability does not reset work.

- **D-29 — Low-network recovery:** As a driver, I want trip controls to recover when mobile data drops. Accept: show last confirmed server state and timestamp; accept no new offer while disconnected; offer timers remain authoritative; queue safe, idempotent state requests only where designed; reconcile on reconnect; never show completion before acknowledgement.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **D-30 — Lost-item recovery:** As a driver, I want a safe, trip-linked way to report or return an item. Accept: use masked contact or support mediation; customer consent and location privacy; no personal number/address disclosure; return-fee policy is shown only if configured; item handoff and case closure are recorded.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Both-party lost-item flow is implemented with scoped history and a support mediation case.

- **D-31 — Breakdown/unsafe-trip interruption:** As a driver, I want immediate options if my vehicle fails or I feel unsafe. Accept: urgent emergency path separate from routine help; end/stop trip according to policy; notify customer/dispatch; record safe location and incident; prevent new offers until safe/eligible; preserve trip and fare evidence for later review.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Driver can interrupt for breakdown/unsafe ending; further offers stop, passenger assistance remains open, finance separately reviews the partial outcome.

- **D-32 — Cash collection:** As a driver, I want to know the exact cash due and record collection accurately. Accept: server fare/adjustment is authoritative; show collected/uncollected/disputed states; completion is idempotent; never ask for an amount absent from receipt; cash-settlement obligations and receipt are explicit.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **D-33 — Earnings statement and dispute:** As a driver, I want to trace each earning to its trip and ledger entry. Accept: gross fare, platform/service fee, taxes if configured, promotion, tip, cash, net payable, payout and adjustment are separate; statement totals reconcile to trip ledger; report discrepancy without editing balances.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Earnings statement reads journal entries and separates fare/earnings/cash/settlement. PDF is generated from bundled fonts.

- **D-34 — Readiness remediation:** As a driver, I want the precise reason I cannot go online and a path to fix it. Accept: enumerate only true blocking checks (approval/document expiry, vehicle eligibility, location, connectivity, market pause, account hold); link to the relevant step; distinguish warning from hard block; re-evaluate server-side after correction.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **D-35 — Approved vehicle switch:** As a driver with multiple vehicles, I want to select the active approved vehicle safely. Accept: switch while offline and outside an active trip; revalidate document expiry, product capacity, and market eligibility; show customer-visible vehicle before assignment; audit change.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Only own approved compatible vehicle can be selected while offline with no active trip; new vehicle approval is version guarded.

- **D-36 — Driver map reports/practice:** As a driver, I want optional onboarding practice and a safe way to report a road hazard. Accept: practice never creates a real trip or payout; map report type and location are confirmed; quick controls are glove/touch accessible; long text is deferred until stopped; reports show moderation/status if submitted.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Non-financial six-step practice plus stopped-driver road hazard intake exist; reports are moderated cases, not automatic road graph edits.

- **D-37 — Driver feedback and ratings:** As a driver, I want to understand feedback and report serious conduct separately. Accept: rating window and eligibility policy are clear; private safety report is not exposed as a public rating; abusive content has review; retaliation and matching preferences follow policy and privacy limits.

  **Delivery status:** Partial. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Own ordinary feedback and separate serious safety reporting exist. Aggregated structured feedback/category treatment is incomplete.

- **D-38 — Driver Safety Toolkit:** As a driver, I want urgent safety tools reachable before, during and after a trip. Accept: local verified emergency number/device dialer and readable trip context without automated emergency data handoff; internal trusted-contact link sharing is consented/time-bounded; optional recording requires applicable policy review, participant notice/consent, encryption/retention/restricted access and local capability; no external emergency/push/call API or unconfigured response service is claimed.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **D-39 — Career ride history and lifetime stats:** As a driver, I want to see how many rides I have completed and review the customers and trips I served over time. Accept: show lifetime and selectable-period completed-trip counts, with canceled, no-show and offered counts clearly separate; searchable/paginated completed-trip history; each detail links trip date/time, ride type, generalized pickup/dropoff, duration/distance, status and the corresponding earnings/receipt; show only the customer display/recognition label permitted after the trip by local privacy policy—never reveal private phone, exact home address, or other unnecessary customer data; records are scoped to the authenticated driver and survive device changes; totals reconcile to trip events; include a missing-trip report and privacy-safe statement export.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Driver history has paginated period/lifetime counts by actual outcomes. Ended customer endpoints and recognition fields are minimized.

- **D-40 — Reachability and background operation:** As a driver, I want honest availability and recoverable trip state when my phone locks or navigation opens. Accept: supported Android device/OS/native-service operating conditions documented and tested; browser demo capability limits disclosed; internal heartbeat/acknowledgement/location age/accuracy thresholds; stop new offers when unreachable, preserve active trip and show stale status to customer/dispatch; offer delivery/expiry/missed-alert recovery; Flutter Android native foreground-service integration and recoverable first-party transport for supported operating conditions; no assertion that Flutter timers, a browser cache or polling guarantee background GPS/killed-app offer delivery; no external push API prerequisite.

  **Delivery status:** Partial. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Android native foreground location service and first-party heartbeat exist; physical Samsung lock/background/battery/restart matrix has not passed. No killed-app/browser background guarantee.

- **D-41 — Work time and rest:** As a driver, I want accumulated time, rest warnings and next eligible time. Accept: market-approved definitions/limits/reset rules persisted across sessions/devices; no inappropriate new offer after a restriction; safe active-trip completion/recovery; no hidden reset on reinstall; staff exceptions narrowly permissioned/audited; platform time is not proof of work outside RideShare.

  **Delivery status:** Partial. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Durable work/rest limits and configurable advance warning exist; approved policy basis/owner and separate review are required. Device and production-policy matrix remains.

- **D-42 — Continuing identity checks:** As a driver, I want a safe way to satisfy a required identity recheck. Accept: approved triggers after recovery/material identity change/risk review; locally operated evidence/manual review, retry and accessible fallback; safe stopped/offline timing; timeout/reason/status/appeal; required incomplete check blocks new assignments under O-38; no unsupported automated screening or forced in-motion capture; biometrics remain disabled unless separately justified/configured.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Identity recheck makes new work ineligible without abandoning assigned passenger recovery; independently reviewed evidence restores eligibility.

- **D-43 — Secure payout destination changes:** As a driver, I want to change where an actual manual settlement is paid without risking earnings theft. Accept: reauthentication/local step-up and documented destination verification; effective/versioned old/new destination; local in-app security notice and reviewed fallback when old access is lost; chosen hold/review and release time; created payouts keep their authorized destination snapshot; unauthorized-change case; no external transfer initiated by a form submission.

  **Delivery status:** Partial. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Destination step-up/review, security notices, independent hold/release, pending-change pause and original snapshot execution are tested. Prior-channel verification remains an actual human procedure.

- **D-44 — Equipment and assistance readiness:** As a driver, I want the exact product requirements and limits before accepting. Accept: locally reviewed vehicle capacity, required safety equipment and offered assistance preparation; match R-38 requirements to actual capabilities; equipment-missing/unsupported-request refusal and fee rules; no unnecessary passenger medical data; status/remediation/review recorded; block new incompatible offers.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** driver/documents/navigation/history/hazard/practice; driver/trips/navigation; rs_drivers, rs_vehicles, rs_documents, rs_offers, rs_driver_shifts.
  **Audit/fix:** Vehicle capacity/equipment and product requirements are checked; specialized assistance certification must be chosen/verified before enabling those products.

- **O-01 — Staff authentication:** As staff, I want individual local authentication, self-contained privileged MFA and scoped roles. Accept: secure provisioning/recovery, local TOTP or approved equivalent, least privilege, short privileged sessions, timeout, audited denials; no hosted authentication API; SSO is a deferred/self-hosted option rather than a standalone prerequisite.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **O-02 — Marketplace overview:** As operator, I want health and queue counts. Accept: freshness, market scope, aggregation, thresholds, permissioned drill-down.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Independent 30-second worker probes actual MySQL/GraphHopper/ClamAV health and records scoped fresh status, reminders and on-call alerts. Functional probes/deduplication passed.

- **O-03 — Scoped trip lookup:** As support, I want permitted trip lookup. Accept: reason for sensitive data, no unrestricted bulk search, access log, PII masked by default.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Masked scoped lookup and reasoned session-bound five-minute sensitive reveal exist; expiry, role and target boundary regressions passed.

- **O-04 — Trip timeline:** As support/ops, I want ordered lifecycle events. Accept: source/time/request IDs, late/out-of-order flags, no silent manual mutation.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **O-05 — Case assignment/SLA:** As supervisor, I want queues, ownership and due times. Accept: priority, dedupe, reassignment history, escalation timer, workload visibility.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Versioned case ownership/status/due dates and independent overdue owner/supervisor reminders exist. Notification claims and delivery commit atomically.

- **O-06 — Customer communication:** As support, I want approved templates and free response. Accept: audience preview, redaction, send confirmation, delivery state and audit.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Claimed replies, localized approved templates, editable audience preview and send confirmation exist. Saved/read state changes only when the intended recipient opens case details. Scope/version tests passed.

- **O-07 — Refund/adjustment proposal:** As support, I want a reasoned adjustment proposal. Accept: policy caps; preview customer/driver/ledger effect; idempotency; approval above limit.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Finance-bound proposals, evidence, actual collection caps and reviewed fare reduction exist. Support does not gain unilateral money authority.

- **O-08 — Dual approval:** As finance/supervisor, I want separate approval for high-impact transactions. Accept: requester cannot self-approve; expiry; immutable decision; rejection reason.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Distinct requester/reviewer and exact proposal hash/version binding exist, with single execution and failed/held manual attempts.

- **O-09 — Safety case escalation:** As safety specialist, I want restricted evidence/escalation. Accept: priority routing, minimum access, evidence audit, retention controls, no routine-agent exposure.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **O-10 — Driver document decision:** As reviewer, I want to approve/reject with reason. Accept: market policy version; second review for exceptions; driver notification; review record.

  **Delivery status:** Partial. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Encrypted evidence, scan state, reviewer reason, version guard and driver/vehicle prerequisites exist. Latest physical vehicle metadata policy needs regression.

- **O-11 — Service zone controls:** As marketplace operator, I want area/time availability controls. Accept: geometry preview; effective time; validation; approval; rollback; active-trip safety.

  **Delivery status:** Partial. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Local Dhaka radius plus extracted road boundary, effective configuration and rollback exist. General polygon editor and time-window preview remain.

- **O-12 — Pricing/policy configuration:** As authorized operator, I want versioned market rules. Accept: effective-dated version, test fixtures, approval, quote audit, rollback, customer disclosure.

  **Delivery status:** Partial. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Reviewed effective pricing/product rules and immutable accepted fare contract exist. Terms/promotions currently publish immediately rather than scheduled promotion.

- **O-13 — Feature flag:** As release owner, I want controlled cohorts. Accept: market/account scope, owner/expiry, audit, kill switch and visible eligibility.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Implemented-feature cohorts, explicit owner/expiry, review and kill switch exist; flags cannot turn on unimplemented services.

- **O-14 — Access administration:** As admin, I want least-privilege role grants/revocation. Accept: requester/approver separation; expiry; periodic review; immediate revoke; exportable audit.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Role-specific reviewed time-limited grants/revocation exist. Global admin does not inherit finance, dispatch or safety privileges.

- **O-15 — Lawful/privacy request:** As privacy/compliance specialist, I want tracked requests. Accept: legal basis, jurisdiction, authority verification, minimization, approval, deadline and immutable log.

  **Delivery status:** Partial. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Compliance-scoped own-data/deletion/hold review exists. Lawful disclosure authority, jurisdiction/deadline/inventory workflow remains incomplete.

- **O-16 — Reconciliation:** As finance, I want ledger/payment/payout comparison. Accept: detect missing/duplicate/late events; repair proposal; no silent balance edits; before/after record.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **O-17 — Incident response:** As on-call, I want alerts/runbooks/shared timeline. Accept: severity/owner, user impact, dependency health, mitigation/rollback, communications, follow-up.

  **Delivery status:** Partial. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Incident records and automatic dependency-failure alerts exist. Real on-call staffing and response remain operating prerequisites.

- **O-18 — Release approval/rollback:** As release owner, I want staged rollout/rollback. Accept: version/owner, monitored gates, pause/rollback, compatible migrations, audit.

  **Delivery status:** Partial. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Manual release/cohort/gate/compatible migration/rollback records exist. Actual binary rollout automation and monitoring gates remain.

- **O-19 — Model governance:** As ML owner, I want versioned evaluation/monitoring. Accept: quality/fairness/drift, provenance, appeal for adverse outcome, limited release, rollback.

  **Delivery status:** Inapplicable: no ML model. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** No machine learning model is used. ML governance is inapplicable until a model is explicitly selected; no fictitious model console.

- **O-20 — Analytics/export:** As approved analyst, I want purpose-limited reports. Accept: purpose, minimum cohort, suppression/redaction, download audit, retention.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Purpose-limited finance/aggregate reports and minimum-cohort suppression exist. Export authority is distinct from private trip/case access.

- **O-21 — Dispatch queue:** As a dispatcher, I want a freshness-labeled live queue for requested, matching, assigned, delayed, canceled and stuck trips. Accept: market/zone filter, event chronology and source, safe list fallback, SLA age, no stale location shown as live, role-based PII reveal, queue updates without lost filters.

  **Delivery status:** Partial. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Freshness-labeled dispatch queue and canonical state lookup exist. Stuck-trip alert jobs are incomplete.

- **O-22 — Dispatch intervention:** As an authorized dispatcher, I want to contact parties, release an expired assignment, or request a rematch when policy allows. Accept: state precondition and driver lease checked atomically; reason and before/after state audited; active/in-progress trip cannot be silently reassigned; customer/driver receive appropriate notification; fare/ledger is unchanged.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Reasoned version-bound dispatch rematch/interruption/assistance exists. Dispatch cannot impersonate driver start/completion.

- **O-23 — Marketplace disruption control:** As marketplace control, I want to pause matching or a product/zone during unsafe or degraded conditions. Accept: scope, effective time, impact and active-trip behavior previewed; second approval for broad or high-impact pause; public notice option; kill switch/rollback and expiry owner recorded.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **O-24 — Trust/risk review:** As a risk investigator, I want an evidence-backed queue for suspicious activity. Accept: display signal provenance/confidence and linked cases; separate facts from model output; restrict evidence; record human decision/reason; automated score alone cannot impose permanent access loss.

  **Delivery status:** Partial. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Human restriction review with evidence exists. A dedicated provenance/confidence risk signal queue remains; no automated model imposes permanent loss.

- **O-25 — Adverse action and appeal:** As a reviewer, I want to apply, review, or reverse an account restriction. Accept: policy/version, duration/scope, user notice where safe/legal, appeal deadline, independent reviewer for high impact, evidence retention, expiry/reinstatement job and immutable decision history.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Independent restrictions include explicit scope, policy basis, duration and appeal deadline. Access-version guards prevent expiry from overwriting a later access decision; worker expiry/restoration tests passed.

- **O-26 — Payment exception queue:** As finance operations, I want to reconcile cash collection and evidenced manual refund/settlement attempts. Accept: execution reference/idempotency, duplicate/late detection, amount/currency match, owner/age/status, no raw credentials, reviewed auditable resolution. Signed webhooks/provider settlement/chargebacks apply only to a later enabled gateway extension.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Cash disputes, partial settlements, held/failed execution attempts and balanced ledgers exist. Actual money evidence remains mandatory.

- **O-27 — Driver payout/cash reconciliation:** As a payout operator, I want to reconcile driver payable, payout provider outcome, cash collected and adjustments. Accept: pending/paid/failed/reversed/held distinctions; no direct balance edit; maker-checker thresholds; retry safety; driver-facing explanation and trace ID.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Cash retention offsets actual payable; payout snapshots, independent hold/release, blocked ownership change and failed/held execution without money journals passed targeted checks.

- **O-28 — Staff workforce/queue coverage:** As a workforce supervisor, I want queue staffing and workload visibility. Accept: role-eligible assignment only; case ownership/transfer history; conflict checks; workload and SLA aging; personal performance data restricted to approved coaching purpose.

  **Delivery status:** Partial. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Role-aware workload, assignment and independent SLA owner/supervisor reminders exist. Approved coaching purpose and actual staffed coverage remain.

- **O-29 — Staff access governance:** As an administrator, I want time-bounded role grants and periodic review. Accept: named local individual accounts, self-contained privileged MFA, least privilege, requester/approver separation, purpose, market/data scope, expiry, immediate revocation, session inventory and reviewed break-glass access; no shared superuser login or hosted SSO requirement.

  **Delivery status:** Partial. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Named individual accounts, MFA, role expiry and immediate authorization refresh exist. Periodic review and reviewed break-glass workflow remain.

- **O-30 — Incident command:** As an incident commander, I want a shared operational timeline for a platform or safety-system outage. Accept: severity, owner/roles, affected markets/services, user impact, dependency and queue health, mitigation, decision log, approved updates, escalation and post-incident action owners.

  **Delivery status:** Partial. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Incident timeline, real dependency probes and on-call alerts exist. Named coverage and incident response are documented operating requirements.

- **O-31 — Release/rollback safety:** As a release owner, I want controlled feature/migration rollout during operations. Accept: version and cohort scope, health gates, migration compatibility, pause/rollback, no destructive rollback of trip/ledger records, change window and audit.

  **Delivery status:** Partial. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Configuration rollback preserves accepted contracts; a private local backup/restore rehearsal passed five checks. Binary rollout and off-device disaster recovery remain.

- **O-32 — Localized content/policy catalog:** As a market product operator, I want to manage help topics, service copy, notices and eligibility text. Accept: localized draft and fallback; product/provider-state validation; accessibility review; no invented price/legal promise; preview by role/device; author and version history.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Versioned localized help/discovery/notices with expiry/fallback exist. Complete translated error inventory still needs review.

- **O-33 — Configuration lifecycle:** As a policy owner, I want market settings and rules promoted safely. Accept: schema/rule validation, effective interval/timezone, impacted trip types, dry-run comparison, named approver, rollback target and audit; active trips keep their accepted terms unless policy explicitly permits otherwise.

  **Delivery status:** Partial. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Exact approved effective changes, overlap guard, conflict outcome and version-bound rollback exist. All policy types do not yet share scheduled lifecycle.

- **O-34 — Privacy request lifecycle:** As a privacy/compliance specialist, I want to verify and fulfill access, correction, export, deletion and retention requests. Accept: identity and authority verification, jurisdiction/deadline/legal basis, linked data inventory, legal hold checks, redacted delivery, completion evidence and restricted access.

  **Delivery status:** Partial. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Identity-checked privacy requests, holds and approved dry-run/apply retention exist. Transactional user/trip/case/document locks and durable physical-purge queue protect evidence; legal-hold tests passed. Jurisdictional deadline/inventory and actual operating policy approval remains.

- **O-35 — Operational data quality:** As an analyst/operator, I want dashboard numbers with lineage and freshness. Accept: metric owner/definition, event-time vs processing-time, missing/late feed warnings, timezone/scope, reconciled source, privacy threshold, report version, export purpose and expiring download.

  **Delivery status:** Partial. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Source MySQL aggregates and as_of exist; no seeded fake performance metrics. Additional report lineage documentation/operational freshness alerts remain.

- **O-36 — Concurrent case and decision handling:** As staff, I want to know when another agent has changed the record I am handling. Accept: versioned conditional writes and authoritative owner/claim where needed; conflict UI preserves safe input; no silent last-write overwrite; completed action cannot be repeated; reassignment/decision history and controlled partial-batch outcomes.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Version conflicts fail safely and private drafts remain. The transient assignment-permission navigator bug is fixed and the complete connected browser journey passed.

- **O-37 — Approval bound to proposal:** As an approver, I want my approval to authorize only the exact reviewed action. Accept: bind amount/currency/scope/policy/record version and expiry to immutable proposal; material edit invalidates approval; recheck authorization/state/version on execution; requester cannot self-approve; one financial effect with retry lookup; changed records return a conflict/review outcome.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Exact proposal hash and versions bind approval; changed amounts/targets cannot silently execute; failed retries remain bound.

- **O-38 — Safe live eligibility changes:** As onboarding/risk/dispatch staff, I want restrictions and expiries enforced without abandoning a current passenger. Accept: approval requires all applicable local document/check evidence; effective restriction blocks future offers; active-trip impact preview and approved safe finish/interruption/assistance workflow; no completion job silently reactivates a suspended/ineligible driver; notification and appeal follow policy.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Expired/restricted drivers lose new work; assigned-trip completion/interruption stays scoped; start revalidates required eligibility.

- **O-39 — Matching exclusion review:** As safety staff, I want to create/review/reverse a case-linked pairing exclusion. Accept: restricted evidence, immediate temporary action when authorized, scope/duration/owner, candidate and late-accept enforcement, confidentiality, expiry/reversal log and no-match fallback; rating alone does not silently create an unrestricted permanent sanction.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **O-40 — Interrupted-trip assistance desk:** As dispatch/support/safety staff, I want unresolved passenger assistance visible after trip termination. Accept: owner/priority/deadline/attempt log; original trip/incident/optional replacement linkage; customer consent and safe location privacy; charge/earning adjustment proposal separate from assistance closure; replacement vehicle revalidated; failed vehicle remains unavailable until cleared.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** staff/requests/support; operations/governance/configuration/cash/jobs/account_policy/settlement; rs_requests, rs_audit, rs_config_versions, rs_cases, rs_journals.
  **Audit/fix:** Ended/interrupted trip does not resolve assistance automatically. Assistance queue stays open with eligible staff ownership.

- **X-01 — Accessible controls:** As a keyboard, screen-reader, low-vision, or motor-impaired user, I want each workflow operable. Accept: semantic labels, focus order, visible focus, contrast, zoom/text scaling, status announcements, no color-only meaning, drag alternatives.

  **Delivery status:** Partial. **Implementation:** main/platform_store/theme/localized/common; core/endpoint/trips; rs_idempotency, rs_active, rs_audit, rs_settings.
  **Audit/fix:** SafeArea, scrollable forms, semantics, focus/input preservation and 48dp controls exist. Full physical screen-reader/large-text/keyboard journey remains.

- **X-02 — Responsive layout:** As a user, I want small/large screens supported. Accept: no horizontal overflow; safe-area/keyboard handling; responsive map/sheet; adequate targets.

  **Delivery status:** Partial. **Implementation:** main/platform_store/theme/localized/common; core/endpoint/trips; rs_idempotency, rs_active, rs_audit, rs_settings.
  **Audit/fix:** Fresh 390px customer/driver and 1280px staff browser journey passed. Signed APK is installed on Samsung and emulator; native evidence is separately recorded. iPhone/Safari coverage remains.

- **X-03 — Form recovery:** As a user, I want field errors and preserved safe input. Accept: inline recovery; preserve on transient failure; clear sensitive fields as needed.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** main/platform_store/theme/localized/common; core/endpoint/trips; rs_idempotency, rs_active, rs_audit, rs_settings.
  **Audit/fix:** Safe controller values are retained on API errors; secret/PIN input is scoped; navigation must not clear a live journey on temporary permission grants.

- **X-04 — Loading/empty/error:** As a user, I want clear states. Accept: no endless spinner; retry/back; preserve durable state; announce status.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** main/platform_store/theme/localized/common; core/endpoint/trips; rs_idempotency, rs_active, rs_audit, rs_settings.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **X-05 — Duplicate request protection:** As a user, I want retries not to duplicate trips/charges/messages/payouts. Accept: idempotency keys, server dedupe, durable outcome lookup, visible result.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** main/platform_store/theme/localized/common; core/endpoint/trips; rs_idempotency, rs_active, rs_audit, rs_settings.
  **Audit/fix:** Persisted scoped idempotency keys, original-operation lookup, transactional retries and immutable journal references exist.

- **X-06 — Notifications:** As a user, I want timely supported notifications respecting settings. Accept: durable internal in-app source of truth, unread/read state and foreground delivery/failed reachability; no external push/email/SMS enabled or implied. Future opt-in delivery channels require separate capability acceptance and privacy controls, including minimal lock-screen text.

  **Delivery status:** Partial. **Implementation:** main/platform_store/theme/localized/common; core/endpoint/trips; rs_idempotency, rs_active, rs_audit, rs_settings.
  **Audit/fix:** Durable inbox/read state and routine offer preferences exist. Native foreground notification behavior and missed alerts need physical verification.

- **X-07 — Localization:** As a user, I want locale-aware language/time/number/currency/address. Accept: translated errors, RTL-ready layout, no hardcoded currency assumptions.

  **Delivery status:** Partial. **Implementation:** main/platform_store/theme/localized/common; core/endpoint/trips; rs_idempotency, rs_active, rs_audit, rs_settings.
  **Audit/fix:** Bundled Bengali font and stable-copy translations exist, including the new correction/worker/template flows. Dynamic error inventory, RTL and native-language review remain incomplete.

- **X-08 — Data minimization:** As a user, I want location/contact/identity/payment data used for clear purposes. Accept: purpose-based collection, encryption, retention, access audit, deletion/legal hold handling.

  **Delivery status:** Partial. **Implementation:** main/platform_store/theme/localized/common; core/endpoint/trips; rs_idempotency, rs_active, rs_audit, rs_settings.
  **Audit/fix:** Encrypted files, audited reveal and legal-hold-aware retention exist. Approved fixture dry-run/apply tests passed; physical purge uses a durable retry queue. Approved real retention basis and expanded lifecycle/device matrix remains.

- **X-09 — State consistency:** As a participant, I want trip and money records to agree after retries/provider delays. Accept: state machine, outbox, reconciliation; no front-end-only authority.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** main/platform_store/theme/localized/common; core/endpoint/trips; rs_idempotency, rs_active, rs_audit, rs_settings.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **X-10 — Observability without leakage:** As on-call, I want diagnostic logs/metrics without secrets or excessive PII. Accept: correlation IDs, redaction, access controls and retention; user-impact alerts.

  **Delivery status:** Partial. **Implementation:** main/platform_store/theme/localized/common; core/endpoint/trips; rs_idempotency, rs_active, rs_audit, rs_settings.
  **Audit/fix:** Request correlation IDs, redacted exception logs, scoped private audit and incident records exist. Automated metrics/user-impact alerts and approved log-retention rules remain.

- **X-11 — Active-trip invariants and live eligibility:** As a participant, I want assignment and recovery consistent across tabs/devices. Accept: initial non-pooled product allows one active customer trip and one active driver/vehicle assignment, enforced transactionally for different request keys; availability intention/login/reachability/active-trip states separate; revalidate account/product/vehicle/document/zone/payment/exclusion eligibility at specified boundaries; explicit own-active-trip lookup on login/refresh/lost response; retries return durable outcome; illegal transitions reject; current-trip restrictions follow O-38.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** main/platform_store/theme/localized/common; core/endpoint/trips; rs_idempotency, rs_active, rs_audit, rs_settings.
  **Audit/fix:** Unique active guards and actual concurrent driver acceptance have backend evidence. Identity/role/status navigation keys preserve temporary assignment transitions; connected journey passed.

- **X-12 — Standalone capability and completion evidence:** As a user/release owner, I want only implemented, locally supported features presented as usable. Accept: server-evaluated feature/prerequisite state; internal APIs remain authoritative; no external API calls/remote runtime assets; false acceptance/payment/verification/safety claims removed; every enabled story has owner, policy, schema/API/permission/UI mapping and test evidence; unfinished extensions are omitted from the public interface; every displayed service works; numeric operational thresholds have approved owners/values; unresolved launch blockers prevent real-use enablement.

  **Delivery status:** Partial. **Implementation:** main/platform_store/theme/localized/common; core/endpoint/trips; rs_idempotency, rs_active, rs_audit, rs_settings.
  **Audit/fix:** Current source, web and signed APK are fingerprint-bound; staging rejects stale artifacts. Native walkthrough metadata must match the exact APK hash. Hosting remains local.

- **C-01 — Bottom navigation:** As a customer, I want Home, Services, Activity and Account navigation to remain predictable so I can reach major parts of the app. Accept: active tab is clear, keyboard/screen-reader labels are present, state survives refresh, and back behavior is consistent.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **C-02 — Home service switch:** As a customer, I want to switch between passenger rides and delivery without mixing the flows. Accept: the selected service is explicit; unfinished services are omitted from the public interface; separate state and APIs are used.

  **Delivery status:** Deferred extension / implemented immediate subset. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Passenger ride products only. Delivery mode is omitted because parcel operations are deferred.

- **C-03 — Home destination search and schedule:** As a customer, I want the “Where to?” and “Later” controls to start an immediate or eligible scheduled booking. Accept: immediate is default; Later remains disabled until R-41 fulfillment passes acceptance and DB availability enables it; enabled time/date entry rejects past times and follows the configured timezone/lead time/service promise.

  **Delivery status:** Deferred extension / implemented immediate subset. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Immediate Where to booking works. Later scheduling is omitted, not displayed as a disabled service.

- **C-04 — Home recent pickup card:** As a customer, I want my current/recent pickup presented so I can start a trip quickly. Accept: address label and freshness; tap opens the planner; manual edit/map selection always available.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **C-05 — Service shortcuts:** As a customer, I want configured ride products (such as Bike, car, CNG, Reserve) surfaced as shortcuts. Accept: products and sort order are database-driven; hidden/ineligible products do not render; shortcut enters the same validated quote flow.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Database Bike/Car/CNG/XL shortcuts are supported with genuine offer matching. Reserve is omitted.

- **C-06 — Discovery cards:** As a customer, I want local travel/service cards to show useful information without blocking booking. Accept: content, images, destination and starting-price copy are database-managed; availability/expiry is respected; cards have text alternatives and do not invent live prices.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Locally managed discovery content/fallback/expiry and feature flag exist.

- **C-07 — Parcel service discovery:** As a customer, I want send/receive item options separated from passenger rides. Accept: only render if delivery is enabled in DB; show permitted item types and service terms; never create a passenger trip for a parcel request.

  **Delivery status:** Deferred extension / implemented immediate subset. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Parcel discovery/send/receive extension is deferred and omitted.

- **C-08 — Activity history and ride detail:** As a customer, I want a chronological list and complete detail for every ride I took. Accept: entries come only from MySQL; list shows product, destination, date/time, final fare and status as observed in the recording; opening an entry shows driver display name and trip-time vehicle, pickup-to-dropoff route/stops, distance/duration, itemized configured fare and payment/receipt; canceled trips explain charges; own trips only; loading/empty/error/pagination; no personal records hardcoded in client.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **C-09 — Rebook:** As a customer, I want to reuse a past route. Accept: copies endpoints/stops into a fresh planner; revalidates zone, current price, product and availability; never silently resubmits or reuses an old payment authorization.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **C-10 — Account hub:** As a customer, I want account identity and shortcuts for Help, Wallet, Safety and Inbox. Accept: profile reads from DB; shortcuts open role-appropriate routes; unread/help/wallet values are live API values; no private data in route URLs.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Help, cash financial history, Safety and Inbox exist. No stored-value balance or top-up is implied.

- **C-11 — Wallet balance/history [stored-value extension]:** As a customer, I want supported money history and any actually enabled balance. Accept: standalone history reads genuine cash/manual transaction records; stored-value balance/top-up remains unavailable. If later enabled, balance comes from immutable ledger with currency/pending/posted state, pagination and audited adjustments only; never infer a balance from trip fares.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Actual cash/fare/refund history exists. Stored-value wallet is deferred and no invented balance is displayed.

- **C-12 — bKash/cash methods:** As a customer in Bangladesh, I want payment choices to reflect actual capability. Accept: standalone cash follows locally configured collection/settlement rules and persisted outcomes; bKash gateway and other electronic connections remain disabled as future extensions; saved labels never imply provider connection or money movement; future enablement requires a new integration scope and verified callbacks.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Cash is the supported payment method. bKash remains omitted without an actual enabled gateway.

- **C-13 — Trip profiles:** As a customer, I want to choose an eligible personal/family/business profile. Accept: profile and default payment are DB-backed; restrictions are validated server-side; personal payment responsibility is explicit.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Personal travel profiles exist; family/business entitlement or organization billing are not implied by profile labels.

- **C-14 — Voucher/promo management:** As a customer, I want to view and add vouchers/promo codes. Accept: validation and eligibility run server-side; expiry, limits, and result are shown; redemption is idempotent and ledgered.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Own eligible promotional codes and redemption checks exist; stored-value gift vouchers are not implemented.

- **C-15 — Saved places:** As a customer, I want to save/edit/remove Home, Work and named places. Accept: authenticated owner-scoped records in DB; labels/addresses/coordinates validate; deletion confirmation; shortcuts use current route/pricing.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **C-16 — Settings:** As a customer, I want to manage appearance, language, communication and trip preferences. Accept: persisted DB preferences; device permissions distinguished from account choices; changes show save state and can be reverted.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **C-17 — Simple/accessibility mode:** As a customer who prefers a simplified interface, I want larger, clearer controls and fewer choices. Accept: account preference persists; primary booking remains available; no capability is hidden without an alternate route; text scaling/reduced motion supported.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **C-18 — Contact and trusted contacts:** As a customer, I want to manage permitted guest/trusted contacts. Accept: contact data is consented and purpose-limited; sharing is revocable; avoid importing device contacts without explicit permission.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Trusted emergency contact CRUD exists. Guest booking contacts do not authorize an unimplemented guest ride.

- **C-19 — Family/shared group:** As an account owner, I want to manage linked family customers. Accept: invitations/roles/age rules are DB-backed; each member’s privacy and trip/payment permissions are explicit; revocation is immediate.

  **Delivery status:** Deferred extension / implemented immediate subset. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Linked-family shared billing extension is deferred and omitted.

- **C-20 — Business profile:** As a business traveler, I want a separate travel profile when enabled. Accept: policy/default payment/profile is DB-backed; receipts use selected profile; restricted changes are explained; no enterprise billing is simulated without setup.

  **Delivery status:** Deferred extension / implemented immediate subset. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Personal profile labels are supported; enterprise authorization/invoices/billing are deferred and omitted.

- **C-21 — Account security and privacy:** As a customer, I want personal info, security, privacy/data and communication pages. Accept: each page reads/writes authenticated DB records through server validation; verification/re-auth is required for sensitive changes; audit and data requests are available.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **C-22 — Safety hub preferences:** As a customer, I want supported PIN, emergency-contact, internal trip-sharing and anomaly-alert settings. Accept: server capability gates each control; preference alone does not enable verification/monitoring; implemented changes persist in DB and affect the next eligible trip; required PIN enforced on start; share link actually created/revocable; anomaly alerts require implemented detection/owned response; unfinished controls omitted from the public interface; emergency actions remain available.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Persisted supported PIN, contacts, own-server sharing and safety response exist; no unsupported recording/biometric control.

- **C-23 — Help entry and trip selection:** As a customer, I want to choose a past/current trip or browse help topics. Accept: trip list is DB-backed and account-scoped; topic catalog is DB-managed; issue routes carry a case ID, not exposed personal data.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **C-24 — Help chat/messages:** As a customer, I want to see ongoing support, send a message, or end a chat. Accept: messages/case status persist in MySQL; loading/failed-send/retry states; no falsely simulated human response; agent identity/type is clear.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **C-25 — Inbox filters:** As a customer, I want to filter messages such as offers, support, updates and priority. Accept: categories and messages come from DB; unread/read updates persist; empty states and refresh work; expired promotions cannot be booked.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Current role-scoped source provides this flow. Execute its full acceptance against separate accounts/devices; do not infer coverage from a page or aggregate test count.

- **C-26 — Earn as driver entry:** As a customer, I want a clear route to driver onboarding. Accept: entry opens the driver enrollment flow and does not silently grant driver role; eligibility and application status come from DB.

  **Delivery status:** Source implemented; clause-level acceptance remains. **Implementation:** shell/booking/account/history/inbox/safety/support; identity/support/governance; rs_saved_places, rs_contacts, rs_profiles, rs_content, rs_notifications.
  **Audit/fix:** Customer can apply as driver; this never grants driver access until evidence-based review.

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


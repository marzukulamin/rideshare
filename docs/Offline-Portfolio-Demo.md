# Offline portfolio demo — 1.3.0+5

Open RideShare and tap **Try Demo**. No account, demo credentials, USB tunnel, hosted backend or GPS permission is required. The Android APK bundles the places, road map and fonts. The browser version has the same server-free demo after its static assets load.

## Visitor journey

1. Choose sample pickup and destination places and a Bike, Car, CNG or XL.
2. Tap **Review demo fare**, then **Simulate booking**.
3. Use the labeled controls to simulate driver match, arrival, pickup and completion. A sample pickup PIN appears at arrival.
4. Open **Activity** to inspect the sample trip details and receipt. No payment is collected.
5. Use **Account → Reset demo** for a fresh session, or **Exit demo** to return to the welcome screen.

The user controls the simulation pace. The fare is an illustrative local calculation and the route line is an illustration, not live road routing or traffic. The driver, vehicle, prices, seeded history and payments are sample data. There are no actual bookings, calls, driver notifications, cash transactions or location tracking in demo mode.

`OfflineDemoSession` holds only in-memory state. The dedicated demo UI does not use `PlatformStore` APIs, session storage, native transport, geolocation or backend endpoints. Startup defers real account initialization until the visitor explicitly chooses **Sign in with an account**. Demo state is discarded when leaving or restarting; real saved sessions and pending operations are untouched.

Real account sign-in remains available separately and still requires the configured PHP/MySQL backend. v1.3.0's connected Android mode still targets the local USB testing endpoint; that requirement does not apply to Try Demo.

For your portfolio, label the optional APK action **Download Demo APK** and explain: "Install the app and tap Try Demo. Explore sample rides offline. Real account sign-in requires a connected backend." Keep Watch Usage Video primary and View Git Repository secondary. The existing video was recorded on 1.2.0 and does not show this new demo mode. The portfolio website itself has not been edited.

## Verification

Model and widget regressions cover complete/cancelled ride transitions, no duplicate history insertion, identical-place validation, preserving active rides, resetting/exiting, a full 360px-wide UI journey, no HTTP requests and no real-session changes. Browser release verification runs on a static HTTP server, aborting any backend or external request and recording browser errors. Native installation coverage is reported separately in the verification report.

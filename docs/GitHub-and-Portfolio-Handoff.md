# GitHub release and portfolio integration

Latest app: **1.3.0+5**. Repository: [marzukulamin/rideshare](https://github.com/marzukulamin/rideshare). Download the signed APK and portfolio package from [release v1.3.0](https://github.com/marzukulamin/rideshare/releases/tag/v1.3.0).

## Try Demo without a server

Install `rideshare-1.3.0.apk`, open RideShare and tap **Try Demo**. No login, USB connection, server or internet is needed. The demo includes sample places, four vehicle choices, illustrative fares, simulated driver match/arrival/pickup/completion, cancellation, trip history and sample receipts. All demo actions stay in memory and reset when you leave or restart the app. They never contact the backend, collect payments, access GPS or modify a real account.

Portfolio actions remain **Watch Usage Video** (primary), **View Git Repository** (secondary), and optionally **Download Demo APK**. Suggested APK description: "Install the Android app and tap Try Demo. Explore sample rides offline; real account sign-in requires a connected backend." No Live Demo button is required.

The existing 45-second walkthrough is included in the repository's `media/` folder and the release. It was recorded on **1.2.0+3**, using a Samsung Customer and emulator Driver with local test accounts. It illustrates the booking, fare, arrival, PIN and receipt flow. It is not footage of the startup recovery fixes added in 1.2.1. `media/walkthrough.json` preserves the recording version and checksums.

## Add the video to your separate portfolio

Copy `media/` into your portfolio's public/static directory. Serve the video, captions and transcript from your website's own origin. For a site that serves these at `/media/`:

```html
<video controls playsinline preload="metadata" aria-label="RideShare Android walkthrough">
  <source src="/media/rideshare-walkthrough.mp4" type="video/mp4">
  <track kind="captions" src="/media/rideshare-walkthrough.vtt"
         srclang="en" label="English" default>
</video>
<p>Recorded on RideShare 1.2.0 using local test accounts.</p>
<a href="/media/walkthrough-transcript.txt">Read the transcript</a>
```

The repository is private. An authorized deployment integration can clone it; anonymous visitors cannot use private GitHub file or release URLs as public media links. Keep GitHub credentials in the deployment service, never in browser code. Host the copied video on the portfolio for visitor playback.

## Add the latest APK and browser app

Extract `rideshare-1.3.0-portfolio-assets.zip`. Its `downloads/` directory contains the signed APK; `demo/` contains the Flutter browser build with the same offline demo; `media/` contains the video and captions. It also includes `release.json`, the handoff instructions and public font assets. The separate `SHA256SUMS.txt` verifies the downloadable release files.

**Real account mode** still uses the computer backend at `http://127.0.0.1:8098/` through USB forwarding. Demo mode works independently. In the browser, Try Demo works on static hosting at `/demo/` after its assets load; real sign-in calls `/api.php` and `/shared.php` on the same origin and requires the PHP backend.

Static hosting can serve the video and browser demo assets. It cannot run real account mode's PHP/MySQL backend. See [GitHub's Pages documentation](https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site).

To enable remote real account access, provision an owned HTTPS PHP host, a private MySQL-compatible database, routing/scanner services and private storage/configuration. Deploy the source backend and browser build together, then rebuild Android with `tools/build.ps1 -Target all -BackendUrl https://YOUR-APP-HOST/`. This is unnecessary for Try Demo. See [the local operations and deployment runbook](Local-Operations-and-Handoff.md).

This upload includes no runtime database dump, test passwords, signing key, private documents, raw phone recordings or supplied reference footage. GitHub publication itself does not deploy the database or create a live app URL.

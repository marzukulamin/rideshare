# GitHub release and portfolio integration

Latest app: **1.2.1+4**. Repository: [marzukulamin/rideshare](https://github.com/marzukulamin/rideshare). Download the signed APK and portfolio package from [release v1.2.1](https://github.com/marzukulamin/rideshare/releases/tag/v1.2.1).

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

Extract `rideshare-1.2.1-portfolio-assets.zip`. Its `downloads/` directory contains the signed APK; `demo/` contains the tested Flutter browser build; `media/` contains the video and captions. It also includes `release.json`, the handoff instructions and public font assets. The separate `SHA256SUMS.txt` verifies the downloadable release files.

The APK is a **local USB testing build**, using the computer backend at `http://127.0.0.1:8098/`. Installing it alone will not give distant clients access to the database. The browser build calls `/api.php` and `/shared.php` on its own origin. A portfolio link to the browser app must therefore point at an HTTPS deployment that also runs this app's PHP backend.

GitHub Pages and other static-only hosts can serve the video and public frontend files, but cannot run this PHP/MySQL backend. See [GitHub's Pages documentation](https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site).

To enable remote testing, provision an owned HTTPS PHP host, a private MySQL-compatible database, routing/scanner services and private storage/configuration. Deploy the source backend and the browser build together, then rebuild Android with `tools/build.ps1 -Target all -BackendUrl https://YOUR-APP-HOST/`. Verify the remote deployment before linking it as a live demo. See [the local operations and deployment runbook](Local-Operations-and-Handoff.md).

This upload includes no runtime database dump, test passwords, signing key, private documents, raw phone recordings or supplied reference footage. GitHub publication itself does not deploy the database or create a live app URL.

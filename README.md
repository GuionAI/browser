# GuionAI Browser

**A self-hosted Chromium server for Playwright clients, with Xvfb and CJK fonts.**

Run it on a trusted private network, then connect with a Playwright client:

```bash
docker run --rm -p 127.0.0.1:3000:3000 ghcr.io/guionai/browser:latest
```

```js
import { chromium } from 'rebrowser-playwright-core';

const browser = await chromium.connect('ws://127.0.0.1:3000/');
const page = await browser.newPage();
await page.goto('https://example.com');
console.log(await page.title());
await browser.close();
```

The image runs `rebrowser-playwright` 1.52.0 on Node 20. It starts a virtual X display and a Chromium Playwright server. The browser is headed by default; set `HEADLESS=true` to run it headless. `PORT` defaults to `3000`, and `BROWSER_LOCALE` defaults to `zh-CN`. Clients should use a compatible Playwright 1.52.x release.

The WebSocket endpoint has a fixed `/` path and no authentication. Bind the port to loopback for local use or expose it only inside a trusted private network. Anyone who can reach the endpoint can control the browser.

Pushing to `main` publishes `ghcr.io/guionai/browser:latest` and a commit SHA tag. A `v*` tag publishes the matching version tag. The image is built and published by GitHub Actions with the repository's `GITHUB_TOKEN`.

Licensed under the [Apache License 2.0](LICENSE). Browser automation patches come from [Rebrowser Playwright](https://github.com/rebrowser/rebrowser-patches).

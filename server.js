/**
 * Stealth Browser Server
 *
 * Exposes a Playwright browser server with:
 * - Patched binaries (no __pwInitScripts fingerprint)
 * - Chinese fonts for WeChat canvas fingerprinting
 * - Android Chrome fingerprint by default
 *
 * Health check: GET /json/version (built into Playwright/CDP)
 */

import { chromium } from 'rebrowser-playwright';

const PORT = parseInt(process.env.PORT || '3000', 10);
// Default to headed mode (false) for better anti-detection
// Canvas fingerprinting checks fail in headless mode due to SwiftShader
const HEADLESS = process.env.HEADLESS === 'true';
const LOCALE = process.env.BROWSER_LOCALE || 'zh-CN';

let browserServer = null;

async function startBrowserServer() {
  console.log('Starting Stealth Browser Server...');
  console.log(`  Port: ${PORT}`);
  console.log(`  Headless: ${HEADLESS}`);
  console.log(`  Locale: ${LOCALE}`);

  browserServer = await chromium.launchServer({
    port: PORT,
    headless: HEADLESS,
    // Fixed WebSocket path so clients can connect without knowing dynamic GUID
    // Default is random unguessable path for security, but we're internal-only
    wsPath: '/',
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-blink-features=AutomationControlled',
      '--disable-infobars',
      '--window-size=412,915',  // Mobile viewport (Android)
      `--lang=${LOCALE}`,
      // Disable various automation indicators
      '--disable-features=IsolateOrigins,site-per-process',
      '--disable-web-security',
      '--disable-features=TranslateUI',
      '--disable-features=BlinkGenPropertyTrees',
    ],
  });

  console.log(`Browser Server listening on ws://0.0.0.0:${PORT}`);
  console.log(`WS Endpoint: ${browserServer.wsEndpoint()}`);
  console.log(`Health Check: http://0.0.0.0:${PORT}/json/version`);

  return browserServer;
}

async function main() {
  try {
    await startBrowserServer();
    console.log('Stealth Browser Server is ready');

    // Keep process alive
    await new Promise(() => {});
  } catch (error) {
    console.error('Failed to start browser server:', error);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('Received SIGTERM, shutting down...');
  if (browserServer) {
    await browserServer.close();
  }
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('Received SIGINT, shutting down...');
  if (browserServer) {
    await browserServer.close();
  }
  process.exit(0);
});

main();

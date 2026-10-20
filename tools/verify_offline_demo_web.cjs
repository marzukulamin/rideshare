const path = require('path');
const fs = require('fs');
const {chromium} = require('C:/Users/ASUS/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const root = path.resolve(__dirname, '..');
const base = 'http://127.0.0.1:8099';
let browser;
(async () => {
  browser = await chromium.launch({headless: true, executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe'});
  const context = await browser.newContext({viewport: {width: 390, height: 844}});
  const page = await context.newPage();
  const errors = [], forbidden = [];
  page.on('pageerror', error => errors.push(error.message));
  await page.route('**/*', async route => {
    const url = route.request().url();
    if (/\/api\.php|\/shared\.php/.test(url) || (!url.startsWith(base + '/') && !/^(data:|blob:)/.test(url))) {
      forbidden.push(url.split('?')[0]);
      await route.abort();
    } else { await route.continue(); }
  });
  await page.goto(base + '/demo/');
  await page.locator('flt-semantics-placeholder').evaluate(element => element.click());
  const press = async name => {
    const button = page.getByRole('button', {name, exact: true});
    for (let i = 0; i < 12; i++) {
      if (await button.count() && await button.isVisible()) { await button.click(); return; }
      await page.mouse.move(382, 450);
      await page.mouse.wheel(0, 400);
      await page.waitForTimeout(150);
    }
    throw new Error('Demo control unavailable: ' + name);
  };
  await page.getByRole('button', {name: 'Try Demo', exact: true}).waitFor({timeout: 30000});
  await press('Try Demo');
  for (const name of ['Review demo fare', 'Simulate booking', 'Simulate driver match', 'Simulate arrival', 'Simulate pickup', 'Complete demo ride', 'View demo activity']) await press(name);
  const snapshot = await page.locator('body').ariaSnapshot();
  if (!snapshot.includes('This demo session')) throw new Error('Completed demo trip was not saved to Activity.');
  const output = path.join(root, '.local/verification');
  fs.mkdirSync(output, {recursive: true});
  await page.waitForTimeout(300);
  await page.screenshot({path: path.join(output, 'offline-demo-activity.png')});
  await press('Exit demo');
  await page.getByRole('button', {name: 'Try Demo', exact: true}).waitFor();
  if (errors.length || forbidden.length) throw new Error(JSON.stringify({errors, forbidden}));
  fs.writeFileSync(path.join(output, 'offline-demo-browser.json'), JSON.stringify({
    passed: ['Server-free entry', 'Booking and fare preview', 'Simulated driver and completed ride', 'Activity and exit'],
    backendRequests: forbidden.length, errors,
  }, null, 2));
  console.log('PASS: static-hosted demo journey, zero backend/external requests and no browser errors.');
  await browser.close();
})().catch(async error => {console.error(error.message); if (browser) await browser.close(); process.exitCode = 1;});

const u = require('./android_ui.cjs');
const fs = require('fs');
const path = require('path');
(async () => {
  u.command('shell', 'am', 'force-stop', u.pkg);
  u.command('shell', 'am', 'start', '-W', '-n', u.pkg + '/.MainActivity');
  await u.wait(2000);
  await u.click('Where to?');
  await u.click(/^Choose pickup/);
  await u.click(/^Farmgate/);
  await u.click('Choose destination');
  await u.click(/^Dhanmondi Lake/);
  await u.click(/^Car ·/);
  await u.click('Review price');
  let labels;
  for (let i = 0; i < 10; i++) {
    labels = u.summary();
    if (labels.some(label => /^৳\d+(?:\.\d+)?$/.test(label))) break;
    await u.wait(1000);
  }
  if (!labels.some(label => /^৳\d+(?:\.\d+)?$/.test(label))) {
    throw new Error('Fare quote did not become ready.');
  }
  const device = u.serial.replace(/[^a-zA-Z0-9_-]/g, '_');
  u.screenshot('booking-quote-' + device);
  fs.writeFileSync(path.join(u.root, '.local/verification/booking-smoke-' + device + '.json'), JSON.stringify({
    device: u.serial,
    passed: ['Pickup and destination selection', 'Server route and Car fare quote'],
    rideRequested: false,
  }, null, 2));
  u.command('shell', 'input', 'keyevent', '4');
  await u.wait(700);
  if (!u.summary().some(label => label === 'RideShare · customer')) throw new Error('Customer Home was not restored.');
  console.log('PASS: place selection, server fare quote, return to Customer Home. No ride requested.');
})().catch(error => {console.error(error.message); process.exitCode = 1;});

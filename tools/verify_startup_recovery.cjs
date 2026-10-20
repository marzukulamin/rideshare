// Exercise startup without altering accounts, trips or the database.
const fs = require('fs');
const path = require('path');
const ui = require('./android_ui.cjs');
const evidence = [];
const deviceLabel = ui.serial.replace(/[^a-zA-Z0-9_-]/g, '_');
async function waitFor(predicate, description) {
  for (let i = 0; i < 30; i++) {
    let labels;
    try {
      labels = ui.summary();
    } catch (error) {
      if (!error.message.startsWith('RideShare is not the foreground app')) throw error;
      await ui.wait(1000);
      continue;
    }
    if (predicate(labels)) return labels;
    await ui.wait(1000);
  }
  throw new Error(description);
}
(async () => {
  try {
    ui.command('shell', 'am', 'force-stop', ui.pkg);
    ui.command('reverse', '--remove', 'tcp:8098');
    ui.command('shell', 'monkey', '-p', ui.pkg, '-c', 'android.intent.category.LAUNCHER', '1');
    await waitFor(labels => labels.includes('Sign in with an account'), 'The welcome screen did not open.');
    await ui.click('Sign in with an account', {scroll: false});
    await waitFor(labels => labels.includes('Retry connection'), 'Offline startup did not expose recovery.');
    evidence.push('Offline startup ends loading and displays Retry connection.');
    ui.screenshot('startup-offline-' + deviceLabel);
    ui.command('reverse', 'tcp:8098', 'tcp:8098');
    await ui.click('Retry connection', {scroll: false});
    await waitFor(labels => !labels.includes('Retry connection') && labels.some(label => /Sign in|RideShare ·/.test(label)), 'Startup did not recover after restoring the backend tunnel.');
    evidence.push('Restoring the USB tunnel and retrying returns to login or the existing account.');
    ui.screenshot('startup-recovered-' + deviceLabel);
    fs.writeFileSync(path.join(ui.root, '.local/verification/startup-recovery-' + deviceLabel + '.json'), JSON.stringify({device: ui.serial, passed: evidence}, null, 2));
    console.log(JSON.stringify({passed: evidence}));
  } finally {
    ui.command('reverse', 'tcp:8098', 'tcp:8098');
  }
})().catch(error => {console.error(error.message); process.exitCode = 1;});

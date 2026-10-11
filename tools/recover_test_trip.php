<?php
require __DIR__.'/../src/platform/core.php';require __DIR__.'/../src/platform/trips.php';
putenv('APP_ENV=local');$id=row('SELECT id FROM rs_users WHERE phone=?',[decode(file_get_contents(__DIR__.'/../.local/backend/test-accounts.json'))['customer']['phone']])['id'];
foreach(rows('SELECT t.* FROM rs_trips t JOIN rs_active a ON a.trip_id=t.id WHERE a.actor_type="customer" AND a.actor_id=?',[$id]) as $trip)if(row('SELECT id FROM rs_events WHERE trip_id=? AND event_key="requested"',[$trip['id']]))transaction(function()use($trip){sql('UPDATE rs_trips SET status="cancelled",ended_at=UTC_TIMESTAMP(),version=version+1 WHERE id=? AND status IN ("matching","assigned","driver_arriving","arrived")',[$trip['id']]);if(trip_row($trip['id'])['status']==='cancelled')release_trip($trip);return [];});
echo "Local test booking cleanup checked.\n";

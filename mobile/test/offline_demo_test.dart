import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:rideshare_showcase/data/offline_demo.dart';
import 'package:rideshare_showcase/data/platform_store.dart';
import 'package:rideshare_showcase/main.dart';

void main() {
  test('demo booking completes once and resets independently of live data', () {
    final demo = OfflineDemoSession();
    expect(demo.reviewFare(), isTrue);
    expect(demo.preview!.fare, greaterThan(0));
    demo.book();
    final ride = demo.current!;
    for (var step = 0; step < 4; step++) {
      demo.advance();
    }
    demo.advance();
    expect(ride.step, 4);
    expect(demo.history.where((item) => identical(item, ride)), hasLength(1));
    demo.reset();
    expect(demo.current, isNull);
    expect(demo.history, hasLength(2));
    demo.dispose();
  });
  test('demo rejects identical places and keeps active booking intact', () {
    final demo = OfflineDemoSession();
    demo.select(to: demo.pickup);
    expect(demo.reviewFare(), isFalse);
    demo.select(to: OfflineDemoSession.places[1]);
    demo.reviewFare();
    demo.book();
    final ride = demo.current;
    demo.select(to: OfflineDemoSession.places[3]);
    demo.reviewFare();
    demo.book();
    expect(identical(demo.current, ride), isTrue);
    demo.cancel();
    demo.cancel();
    demo.advance();
    expect(ride!.step, 5);
    expect(demo.history, hasLength(3));
    demo.dispose();
  });
  testWidgets(
    'visitor completes a demo ride with no HTTP requests or live-session changes',
    (t) async {
      var requests = 0;
      final store = PlatformStore(
        client: MockClient((_) async {
          requests++;
          throw StateError('Demo must never contact a backend.');
        }),
      );
      store.token = 'existing-real-session';
      store.data = {
        'user': {
          'id': 99,
          'roles': ['customer'],
        },
      };
      t.view.physicalSize = const Size(360, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(RideShareApp(store: store, startAtWelcome: true));
      await t.pumpAndSettle();
      expect(find.text('Try Demo'), findsOneWidget);
      await t.tap(find.text('Try Demo'));
      await t.pumpAndSettle();
      expect(
        find.text('Offline demo · Sample data · No real rides'),
        findsOneWidget,
      );
      Future<void> press(String label) async {
        final button = find.text(label);
        await t.ensureVisible(button);
        await t.pumpAndSettle();
        await t.tap(button);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      }

      await press('Review demo fare');
      await press('Simulate booking');
      await press('Simulate driver match');
      await press('Simulate arrival');
      expect(find.text('Sample pickup PIN: 2468'), findsOneWidget);
      await press('Simulate pickup');
      await press('Complete demo ride');
      await press('View demo activity');
      expect(find.textContaining('This demo session'), findsOneWidget);
      await t.tap(find.text('Account'));
      await t.pumpAndSettle();
      await press('Reset demo');
      await t.tap(find.text('Exit demo').first);
      await t.pumpAndSettle();
      expect(find.text('Try Demo'), findsOneWidget);
      await t.tap(find.text('Try Demo'));
      await t.pumpAndSettle();
      await t.tap(find.text('Activity'));
      await t.pumpAndSettle();
      expect(find.textContaining('This demo session'), findsNothing);
      expect(requests, 0);
      expect(store.token, 'existing-real-session');
      expect(store.user['id'], 99);
      await t.pumpWidget(const SizedBox());
      store.dispose();
    },
  );
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rideshare_showcase/data/platform_store.dart';
import 'package:rideshare_showcase/features/trip.dart';
import 'package:rideshare_showcase/features/common.dart';
import 'package:rideshare_showcase/main.dart';
import 'package:rideshare_showcase/features/booking.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'offline startup finishes and reconnects without losing its session',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'rideshare_session': 'saved-session',
      });
      var offline = true;
      final s = PlatformStore(
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer saved-session');
          if (offline) throw Exception('offline');
          return http.Response(
            '{"user":{"id":1,"permissions":["customer"]}}',
            200,
          );
        }),
      );
      await s.initialize();
      expect(s.loading, isFalse);
      expect(s.error, contains('local test server'));
      expect(s.token, 'saved-session');
      offline = false;
      await s.initialize();
      expect(s.error, isNull);
      expect(s.signedIn, isTrue);
      s.dispose();
    },
  );
  testWidgets('startup connection failure is visible and offers retry', (
    t,
  ) async {
    final s = PlatformStore();
    s.loading = false;
    s.error = 'Cannot reach the local test server.';
    await t.pumpWidget(RideShareApp(store: s));
    await t.pumpAndSettle();
    expect(find.text('Cannot reach the local test server.'), findsOneWidget);
    expect(find.text('Retry connection'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    s.dispose();
  });
  test('an in-flight refresh can finish after the store is disposed', () async {
    final s = PlatformStore(
      client: MockClient((_) async => http.Response('{"user":{}}', 200)),
    );
    final refresh = s.refresh();
    s.dispose();
    await expectLater(refresh, completes);
  });
  test('money input rejects malformed, non-finite and negative amounts', () {
    expect(bdtMinor('7.50'), 750);
    expect(bdtMinor('0'), 0);
    for (final value in ['no', 'NaN', 'Infinity', '-1']) {
      expect(() => bdtMinor(value), throwsA(isA<ApiFailure>()));
    }
  });
  PlatformStore fixture(String role) {
    final s = PlatformStore(
      client: MockClient(
        (r) async => http.Response(
          jsonEncode({
            'trip': {
              'id': '12345678123456781234567812345678',
              'customer_id': 1,
              'driver_id': 2,
              'status': 'arrived',
              'payment_status': 'uncollected',
              'pin_required': 1,
              'pin': role == 'customer' ? '1234' : null,
              'fare_minor': 12000,
              'version': 3,
              'snapshot': {
                'product': {'name': 'Car'},
                'pickup': {'name': 'Pickup'},
                'destination': {'name': 'Destination'},
                'base_fare_minor': 12000,
              },
              'events': [],
              'messages': [],
            },
          }),
          200,
        ),
      ),
    );
    s.loading = false;
    s.data = {
      'user': {
        'id': role == 'customer' ? 1 : 2,
        'name': 'Test account',
        'phone': 'Test phone',
        'roles': [role],
        'permissions': [role],
        'preferences': {},
      },
      'products': [],
      'places': [],
    };
    return s;
  }

  testWidgets('place search remains usable above the phone keyboard', (
    t,
  ) async {
    final s = fixture('customer');
    s.data['places'] = [
      {
        'name': 'Dhanmondi Lake',
        'address': 'Dhaka',
        'lat': 23.7471,
        'lng': 90.3745,
      },
    ];
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    t.view.viewInsets = const FakeViewPadding(bottom: 330);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetViewInsets);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (c) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: c,
                isScrollControlled: true,
                builder: (_) => PlacePicker(store: s, title: 'Destination'),
              ),
              child: const Text('Open picker'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Open picker'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'Dhanmondi');
    await t.pump();
    await t.scrollUntilVisible(
      find.text('Dhanmondi Lake'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Dhanmondi Lake'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    s.dispose();
  });
  testWidgets(
    'customer cannot start, arrive, accept or complete a driver trip',
    (t) async {
      final s = fixture('customer');
      await t.pumpWidget(
        MaterialApp(
          home: TripPage(store: s, id: '12345678123456781234567812345678'),
        ),
      );
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text('Tell your driver this pickup PIN'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Tell your driver this pickup PIN'), findsOneWidget);
      expect(find.text('Start ride'), findsNothing);
      expect(find.text('Confirm arrival'), findsNothing);
      expect(find.text('Complete ride'), findsNothing);
      expect(find.text('Accept ride'), findsNothing);
      await t.pumpWidget(const SizedBox());
      s.dispose();
    },
  );
  testWidgets(
    'assigned driver can start but cannot view private customer PIN',
    (t) async {
      final s = fixture('driver');
      await t.pumpWidget(
        MaterialApp(
          home: TripPage(store: s, id: '12345678123456781234567812345678'),
        ),
      );
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text('Start ride'),
        300,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Start ride'), findsOneWidget);
      expect(find.text('Tell your driver this pickup PIN'), findsNothing);
      expect(find.text('1234'), findsNothing);
      await t.pumpWidget(const SizedBox());
      s.dispose();
    },
  );
  testWidgets(
    'active assignment permission keeps the driver route open, role changes clear it',
    (t) async {
      final s = fixture('driver');
      await t.pumpWidget(RideShareApp(store: s));
      await t.pumpAndSettle();
      final context = t.element(find.byType(Scaffold).first);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Assigned trip screen')),
        ),
      );
      await t.pumpAndSettle();
      s.data['user']['permissions'] = ['driver', 'active_driver'];
      s.notifyListeners();
      await t.pumpAndSettle();
      expect(find.text('Assigned trip screen'), findsOneWidget);
      s.data['user']['roles'] = [];
      s.data['user']['permissions'] = ['active_driver'];
      s.notifyListeners();
      await t.pumpAndSettle();
      expect(find.text('Assigned trip screen'), findsNothing);
      await t.pumpWidget(const SizedBox());
      s.dispose();
    },
  );
  testWidgets('Bengali account language translates booking navigation', (
    t,
  ) async {
    final s = fixture('customer');
    s.data['user']['locale'] = 'bn-BD';
    await t.pumpWidget(RideShareApp(store: s));
    await t.pumpAndSettle();
    expect(find.text('কোথায় যাবেন?'), findsOneWidget);
    expect(find.text('অ্যাকাউন্ট'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    s.dispose();
  });
  testWidgets(
    'customer navigation has no staff or driver role selector at enlarged text',
    (t) async {
      t.view.physicalSize = const Size(360, 780);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final s = fixture('customer');
      record(s.data['user']);
      s.data['user']['preferences'] = {'simple_mode': true};
      await t.pumpWidget(RideShareApp(store: s));
      await t.pumpAndSettle();
      expect(find.text('Where to?'), findsOneWidget);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
      expect(find.text('RideShare · customer'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.tap(find.text('Account'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      s.dispose();
    },
  );
  test('network failures preserve the last authoritative state', () async {
    final s = PlatformStore(
      client: MockClient((r) async => throw Exception('offline')),
    );
    s.data = {
      'user': {'id': 1},
      'active_trip': {'id': 'durable-trip'},
    };
    await expectLater(s.refresh(), throwsA(isA<ApiFailure>()));
    expect(s.active!['id'], 'durable-trip');
    s.dispose();
  });
  test('expired session clears role access', () async {
    final s = PlatformStore(
      client: MockClient(
        (r) async => http.Response('{"error":"expired"}', 401),
      ),
    );
    s.data = {
      'user': {
        'id': 1,
        'permissions': ['driver'],
      },
    };
    await expectLater(s.refresh(), throwsA(isA<ApiFailure>()));
    expect(s.can('driver'), isFalse);
    expect(s.signedIn, isFalse);
    s.dispose();
  });
}

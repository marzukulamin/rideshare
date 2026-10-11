import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:geolocator/geolocator.dart';

import 'client_native.dart' if (dart.library.js_interop) 'client_web.dart';

typedef Record = Map<String, dynamic>;
int number(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
String money(dynamic v) =>
    '৳${(number(v) / 100).toStringAsFixed(number(v) % 100 == 0 ? 0 : 2)}';
Record record(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : {};
List<Record> records(dynamic v) => v is List ? v.map(record).toList() : [];
String stage(dynamic v) => '$v'.replaceAll('_', ' ');

class ApiFailure implements Exception {
  final String message;
  final int status;
  ApiFailure(this.message, this.status);
  @override
  String toString() => message;
}

class PlatformStore extends ChangeNotifier {
  final http.Client client;
  final FlutterSecureStorage storage;
  final Uri base;
  String? token, csrf, error;
  Record data = {};
  Record emergency = {};
  bool loading = true, busy = false;
  DateTime? refreshedAt;
  final Map<String, String> pendingOperations = {};
  StreamSubscription<Position>? locationStream;
  bool tracking = false;
  DateTime? locationSent;
  Future<void> startDriverTracking() async {
    if (!can('driver') && !can('active_driver')) {
      throw ApiFailure('Only drivers can enable driver location.', 403);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw ApiFailure(
        'Location permission is unavailable. Keep tracking off.',
        422,
      );
    }
    await locationStream?.cancel();
    if (!kIsWeb) {
      if (token == null) {
        throw ApiFailure(
          'Sign in again before starting driver transport.',
          401,
        );
      }
      await const MethodChannel('rideshare/driver_transport')
          .invokeMethod('start', {'base': base.toString(), 'token': token});
      tracking = true;
      notifyListeners();
      return;
    }
    final LocationSettings settings = kIsWeb
        ? const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 15,
          )
        : AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 15,
            intervalDuration: const Duration(seconds: 10),
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'RideShare driver location',
              notificationText: 'Location is shared while you are available or on your assigned ride.',
              enableWakeLock: true,
            ),
          );
    tracking = true;
    notifyListeners();
    locationStream = Geolocator.getPositionStream(locationSettings: settings)
        .listen(
          (position) async {
            if (locationSent != null &&
                DateTime.now().difference(locationSent!) <
                    const Duration(seconds: 10)) {
              return;
            }
            locationSent = DateTime.now();
            try {
              await api(
                'driver-heartbeat',
                body: {
                  'lat': position.latitude,
                  'lng': position.longitude,
                  'accuracy': position.accuracy,
                },
              );
            } catch (e) {
              error = '$e';
              notifyListeners();
            }
          },
          onError: (Object e) {
            error = 'Location feed interrupted: $e';
            notifyListeners();
          },
        );
  }

  Future<void> stopDriverTracking() async {
    if (!kIsWeb && tracking) {
      await const MethodChannel('rideshare/driver_transport')
          .invokeMethod('stop');
    }
    await locationStream?.cancel();
    locationStream = null;
    tracking = false;
    notifyListeners();
  }

  PlatformStore({http.Client? client, FlutterSecureStorage? storage, Uri? base})
    : client = client ?? createClient(),
      storage = storage ?? const FlutterSecureStorage(),
      base =
          base ??
          (kIsWeb
              ? Uri.base.resolve('/')
              : Uri.parse(
                  const String.fromEnvironment(
                    'BACKEND_URL',
                    defaultValue: 'http://127.0.0.1:8098/',
                  ),
                ));
  Record get user => record(data['user']);
  Record? get active =>
      data['active_trip'] == null ? null : record(data['active_trip']);
  bool can(String permission) =>
      (user['permissions'] as List? ?? []).contains(permission);
  bool get signedIn => user.isNotEmpty;
  bool get staff => (user['roles'] as List? ?? []).any(
    (r) => r != 'customer' && r != 'driver' && r != 'driver_applicant',
  );
  String operationKey() => List.generate(
    24,
    (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  Future<Record> api(
    String action, {
    Record? body,
    Record query = const {},
    String? operation,
  }) async {
    final uri = base
        .resolve('api.php')
        .replace(
          queryParameters: {
            'action': action,
            ...query.map((k, v) => MapEntry(k, '$v')),
          },
        );
    final headers = <String, String>{
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      'X-CSRF-Token': ?csrf,
    };
    http.Response response;
    try {
      if (body == null) {
        response = await client
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 20));
      } else {
        headers.addAll({
          'Content-Type': 'application/json',
          'Idempotency-Key': operation ?? operationKey(),
        });
        response = await client
            .post(uri, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 20));
      }
    } catch (_) {
      throw ApiFailure(
        'Connection interrupted. Refresh to check whether your action was saved before retrying.',
        0,
      );
    }
    Record result;
    try {
      result = record(jsonDecode(response.body));
    } catch (_) {
      throw ApiFailure(
        'The server returned an unreadable response.',
        response.statusCode,
      );
    }
    if (response.statusCode >= 400) {
      if (response.statusCode == 401) {
        await stopDriverTracking();
        data = {};
        notifyListeners();
      }
      throw ApiFailure(
        '${result['error'] ?? 'Action failed.'}',
        response.statusCode,
      );
    }
    return result;
  }

  Future<void> initialize() async {
    emergency = record(
      jsonDecode(await rootBundle.loadString('assets/emergency.json')),
    );
    try {
      if (!kIsWeb) token = await storage.read(key: 'rideshare_session');
      final saved = await storage.read(key: 'rideshare_operations');
      if (saved != null) {
        pendingOperations.addAll(Map<String, String>.from(jsonDecode(saved)));
      }
      await refresh();
    } catch (e) {
      if (e is ApiFailure && e.status == 401) {
        error = null;
      } else {
        error = '$e';
      }
    }
    loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    data = await api('bootstrap');
    if (!kIsWeb && (can('driver') || can('active_driver'))) {
      try {
        final running = await const MethodChannel('rideshare/driver_transport')
            .invokeMethod<bool>('status');
        if (tracking && running != true) error = 'Driver tracking stopped. Check location permission and enable it again.';
        tracking = running == true;
      } catch (_) {}
    }

    csrf = user['csrf'];
    refreshedAt = DateTime.now();
    error = null;
    notifyListeners();
  }

  Future<void> login(String phone, String password, String code) async {
    final result = await api(
      'login',
      body: {
        'phone': phone,
        'password': password,
        'code': code,
        'client': kIsWeb ? 'web' : 'android',
        'device': kIsWeb ? 'Flutter browser' : 'Flutter Android',
      },
    );
    token = result['token'];
    csrf = result['csrf'];
    if (!kIsWeb && token != null) {
      await storage.write(key: 'rideshare_session', value: token);
    }
    await refresh();
  }

  Future<Record> act(String action, Record body, {bool refresh = true}) async {
    busy = true;
    error = null;
    notifyListeners();
    final digest = sha256
        .convert(utf8.encode('${user['id']}:$action:${jsonEncode(body)}'))
        .toString();
    final key = pendingOperations.putIfAbsent(digest, operationKey);
    try {
      await storage.write(
        key: 'rideshare_operations',
        value: jsonEncode(pendingOperations),
      );
      final result = await api(action, body: body, operation: key);
      pendingOperations.remove(digest);
      await storage.write(
        key: 'rideshare_operations',
        value: jsonEncode(pendingOperations),
      );
      if (refresh && signedIn) await this.refresh();
      if (!(can('driver') || can('active_driver')) ||
          (action == 'driver-availability' &&
              body['online'] == false &&
              active == null)) {
        await stopDriverTracking();
      }
      return result;
    } on ApiFailure catch (e) {
      if (e.status >= 400 && e.status < 500) {
        pendingOperations.remove(digest);
        await storage.write(
          key: 'rideshare_operations',
          value: jsonEncode(pendingOperations),
        );
      }
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await stopDriverTracking();
    await api('logout', body: {});
    token = null;
    csrf = null;
    data = {};
    if (!kIsWeb) await storage.delete(key: 'rideshare_session');
    notifyListeners();
  }

  @override
  void dispose() {
    locationStream?.cancel();
    client.close();
    super.dispose();
  }
}

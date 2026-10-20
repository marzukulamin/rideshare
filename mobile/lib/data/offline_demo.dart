import 'dart:math' as math;

import 'package:flutter/foundation.dart';

class DemoPlace {
  final String name;
  final double lat, lng;
  const DemoPlace(this.name, this.lat, this.lng);
  Map<String, dynamic> get pin => {'name': name, 'lat': lat, 'lng': lng};
}

class DemoRide {
  final DemoPlace pickup, destination;
  final String vehicle;
  final int fare;
  final double distanceKm;
  final bool example;
  int step;
  DemoRide({
    required this.pickup,
    required this.destination,
    required this.vehicle,
    required this.fare,
    required this.distanceKm,
    this.step = 0,
    this.example = false,
  });
  String get status => const [
    'Finding a demo driver',
    'Driver matched',
    'Driver at pickup',
    'Demo ride in progress',
    'Demo ride completed',
    'Demo ride cancelled',
  ][step];
  bool get ended => step >= 4;
}

/// In-memory portfolio sandbox. No HTTP, storage, GPS or platform services.
class OfflineDemoSession extends ChangeNotifier {
  static const places = [
    DemoPlace('Farmgate', 23.7581, 90.3897),
    DemoPlace('Dhanmondi Lake', 23.7471, 90.3745),
    DemoPlace('Shahbag', 23.7388, 90.3950),
    DemoPlace('Gulshan 2', 23.7947, 90.4144),
    DemoPlace('Dhaka University', 23.7335, 90.3928),
  ];
  static const vehicles = ['Bike', 'Car', 'CNG', 'XL'];
  DemoPlace pickup = places[0], destination = places[1];
  String vehicle = 'Car';
  DemoRide? preview, current;
  final List<DemoRide> history = [];
  int tab = 0;

  OfflineDemoSession() {
    _seedHistory();
  }

  void _seedHistory() {
    history.addAll([
      DemoRide(
        pickup: places[2],
        destination: places[3],
        vehicle: 'Car',
        fare: 380,
        distanceKm: 7.2,
        step: 4,
        example: true,
      ),
      DemoRide(
        pickup: places[4],
        destination: places[0],
        vehicle: 'Bike',
        fare: 140,
        distanceKm: 3.4,
        step: 4,
        example: true,
      ),
    ]);
  }

  void navigate(int value) {
    tab = value;
    notifyListeners();
  }

  void select({DemoPlace? from, DemoPlace? to, String? product}) {
    pickup = from ?? pickup;
    destination = to ?? destination;
    vehicle = product ?? vehicle;
    preview = null;
    notifyListeners();
  }

  /// Illustrative estimate, not live road routing or an actual service fare.
  bool reviewFare() {
    if (pickup == destination) return false;
    if (current != null && !current!.ended) {
      navigate(1);
      return true;
    }
    final lat = (destination.lat - pickup.lat) * math.pi / 180;
    final lng = (destination.lng - pickup.lng) * math.pi / 180;
    final a =
        math.pow(math.sin(lat / 2), 2) +
        math.cos(pickup.lat * math.pi / 180) *
            math.cos(destination.lat * math.pi / 180) *
            math.pow(math.sin(lng / 2), 2);
    final distance = 6371 * 2 * math.asin(math.sqrt(a).clamp(0, 1)) * 1.25;
    final rate = {'Bike': 35, 'Car': 85, 'CNG': 55, 'XL': 110}[vehicle]!;
    preview = DemoRide(
      pickup: pickup,
      destination: destination,
      vehicle: vehicle,
      fare: (60 + distance * rate).round(),
      distanceKm: distance,
    );
    current = null;
    navigate(1);
    return true;
  }

  void book() {
    if (preview == null || (current != null && !current!.ended)) return;
    current = preview;
    preview = null;
    notifyListeners();
  }

  void advance() {
    final ride = current;
    if (ride == null || ride.ended) return;
    ride.step++;
    if (ride.ended) history.insert(0, ride);
    notifyListeners();
  }

  void cancel() {
    final ride = current;
    if (ride == null || ride.ended) return;
    ride.step = 5;
    history.insert(0, ride);
    notifyListeners();
  }

  void reset() {
    pickup = places[0];
    destination = places[1];
    vehicle = 'Car';
    preview = null;
    current = null;
    tab = 0;
    history.clear();
    _seedHistory();
    notifyListeners();
  }
}

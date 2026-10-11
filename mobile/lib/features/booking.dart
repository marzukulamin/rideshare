import '../ui/localized.dart';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../data/platform_store.dart';
import '../ui/theme.dart';
import '../ui/road_map.dart';

import 'dart:convert';

import 'common.dart';
import 'trip.dart';

class BookingPage extends StatefulWidget {
  final PlatformStore store;
  final Record? destination, product, pickup;
  final List<Record> stops;
  const BookingPage({
    super.key,
    required this.store,
    this.destination,
    this.product,
    this.pickup,
    this.stops = const [],
  });
  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  Record? pickup, destination, product, quote, terms;
  bool termsAccepted = false;
  List<Record> stops = [];
  bool pending = false, helmet = true;
  int passengers = 1;
  String? error;
  final note = TextEditingController(), promo = TextEditingController();
  dynamic profile;
  @override
  void initState() {
    super.initState();
    destination = widget.destination;
    pickup = widget.pickup;
    stops = List.of(widget.stops);
    product = widget.product;
  }

  @override
  void dispose() {
    note.dispose();
    promo.dispose();
    super.dispose();
  }

  Future<Record?> choose(String label) async => showModalBottomSheet<Record>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (c) => PlacePicker(store: widget.store, title: label),
  );
  Future<void> price() async {
    if (pickup == null || destination == null || product == null) {
      setState(() => error = 'Choose pickup, destination and vehicle.');
      return;
    }
    setState(() {
      pending = true;
      error = null;
    });
    try {
      final r = await widget.store.act('quote', {
        'pickup': pickup,
        'destination': destination,
        'product_id': product!['id'],
        'stops': stops,
        'needs': {'passengers': passengers, 'helmet_confirmed': helmet},
        'promo': promo.text.trim(),
      }, refresh: false);
      if (mounted) {
        setState(() {
          quote = record(r['quote']);
          terms = record(r['terms']);
          termsAccepted = r['terms_accepted'] == true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => pending = false);
    }
  }

  void changed() {
    setState(() => quote = null);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const UiText('Where to?')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          RoadMap(
            height: 200,
            pins: [?pickup, ...stops, ?destination],
            route: quote == null
                ? const []
                : records(jsonDecode(quote!['route_json'])),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.my_location),
                  title: Text(pickup?['name'] ?? 'Choose pickup'),
                  subtitle: Text(
                    pickup?['address'] ?? 'Confirm your meeting point',
                  ),
                  onTap: () async {
                    final p = await choose('Pickup');
                    if (p != null) {
                      pickup = p;
                      changed();
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(destination?['name'] ?? 'Choose destination'),
                  onTap: () async {
                    final p = await choose('Destination');
                    if (p != null) {
                      destination = p;
                      changed();
                    }
                  },
                ),
              ],
            ),
          ),
          for (var i = 0; i < stops.length; i++)
            ListTile(
              leading: const Icon(Icons.trip_origin),
              title: Text(stops[i]['name']),
              trailing: IconButton(
                tooltip: tr(context, 'Remove stop'),
                icon: const Icon(Icons.close),
                onPressed: () {
                  stops.removeAt(i);
                  changed();
                },
              ),
            ),
          if (stops.length < 2)
            TextButton.icon(
              onPressed: () async {
                final p = await choose('Add stop');
                if (p != null) {
                  stops.add(p);
                  changed();
                }
              },
              icon: const Icon(Icons.add),
              label: const UiText('Add a stop'),
            ),
          section('Choose your ride'),
          for (final p in records(widget.store.data['products']))
            Card(
              child: ListTile(
                selected: '${p['id']}' == '${product?['id']}',
                onTap: () {
                  product = p;
                  passengers = 1;
                  changed();
                },
                title: Text('${p['name']} · up to ${p['capacity']}'),
                subtitle: Text(
                  '${p['description']}\n${money(p['rate_minor'])}/km',
                ),
                leading: Icon(productIcon('${p['name']}')),
                trailing: '${p['id']}' == '${product?['id']}'
                    ? const Icon(Icons.check_circle)
                    : const Icon(Icons.circle_outlined),
              ),
            ),
          DropdownButtonFormField<int>(
            initialValue: passengers,
            decoration: InputDecoration(labelText: tr(context, 'Passengers')),
            items: List.generate(
              number(product?['capacity']).clamp(1, 6),
              (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
            ),
            onChanged: (v) {
              passengers = v ?? 1;
              changed();
            },
          ),
          if (product?['product_key'] == 'bike')
            CheckboxListTile(
              value: helmet,
              onChanged: (v) {
                helmet = v ?? false;
                changed();
              },
              title: const UiText('Passenger helmet required'),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: note,
            maxLength: 240,
            decoration: InputDecoration(
              labelText: tr(context, 'Pickup note (optional)'),
            ),
          ),
          TextField(
            controller: promo,
            onChanged: (_) => changed(),
            decoration: InputDecoration(
              labelText: tr(context, 'Promo code (optional)'),
            ),
          ),
          if (records(widget.store.data['profiles']).isNotEmpty)
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: tr(context, 'Travel profile'),
              ),
              items: [
                const DropdownMenuItem(value: '', child: UiText('Personal')),
                for (final p in records(widget.store.data['profiles']))
                  DropdownMenuItem(
                    value: '${p['id']}',
                    child: Text('${p['name']}'),
                  ),
              ],
              onChanged: (v) => profile = v,
            ),
          section('Cash payment'),
          const UiText(
            'Pay the driver after the ride. Your accepted price is locked. A trip starts only when your assigned driver confirms your pickup PIN.',
          ),
          if (quote != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      money(quote!['fare_minor']),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(number(quote!['distance_m']) / 1000).toStringAsFixed(2)} km · road distance',
                    ),
                    Text(
                      'Estimated travel: ${(number(quote!['duration_seconds']) / 60).ceil()} minutes · road estimate; traffic can change it.',
                    ),
                    ExpansionTile(
                      title: Text('Service terms · ${terms?['version'] ?? ''}'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text('${terms?['body'] ?? ''}'),
                        ),
                      ],
                    ),
                    CheckboxListTile(
                      value: termsAccepted,
                      onChanged: (v) =>
                          setState(() => termsAccepted = v ?? false),
                      title: const UiText('I accept these service terms'),
                    ),
                    const UiText(
                      'Quote valid for five minutes. Review your pickup and accepted service terms.',
                    ),
                  ],
                ),
              ),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          FilledButton(
            onPressed: pending || (quote != null && !termsAccepted)
                ? null
                : quote == null
                ? price
                : () async {
                    setState(() {
                      pending = true;
                      error = null;
                    });
                    try {
                      final r = await widget.store.act('request-trip', {
                        'quote_id': quote!['id'],
                        'accept_terms': termsAccepted,
                        'terms_id': terms?['id'],
                        'note': note.text,
                        'profile_id': profile == null || profile == ''
                            ? null
                            : number(profile),
                      });
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TripPage(store: widget.store, id: r['trip_id']),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) setState(() => error = '$e');
                    } finally {
                      if (mounted) setState(() => pending = false);
                    }
                  },
            child: Text(
              pending
                  ? 'Please wait…'
                  : quote == null
                  ? 'Review price'
                  : 'Request ${product!['name']}',
            ),
          ),
        ],
      ),
    ),
  );
}

class PlacePicker extends StatefulWidget {
  final PlatformStore store;
  final String title;
  const PlacePicker({super.key, required this.store, required this.title});
  @override
  State<PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends State<PlacePicker> {
  late List<Record> list;
  String query = '';
  bool locating = false;
  String? error;
  @override
  void initState() {
    super.initState();
    list = records(widget.store.data['places']);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SizedBox(
      height:
          (MediaQuery.sizeOf(context).height * .85 -
                  MediaQuery.viewInsetsOf(context).bottom)
              .clamp(220.0, MediaQuery.sizeOf(context).height * .85)
              .toDouble(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              widget.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: tr(context, 'Search places'),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (q) => setState(() => query = q.toLowerCase()),
            ),
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                ListTile(
                  leading: const Icon(Icons.gps_fixed),
                  title: Text(
                    locating ? 'Finding location…' : 'Use device location',
                  ),
                  onTap: locating
                      ? null
                      : () async {
                          setState(() => locating = true);
                          try {
                            var permission = await Geolocator.checkPermission();
                            if (permission == LocationPermission.denied) {
                              permission = await Geolocator.requestPermission();
                            }
                            if (permission == LocationPermission.denied ||
                                permission ==
                                    LocationPermission.deniedForever) {
                              throw Exception(
                                'Location permission unavailable. Choose a place instead.',
                              );
                            }
                            final p = await Geolocator.getCurrentPosition(
                              locationSettings: const LocationSettings(
                                accuracy: LocationAccuracy.high,
                                timeLimit: Duration(seconds: 15),
                              ),
                            );
                            if (context.mounted) {
                              Navigator.pop(context, {
                                'name': 'Selected device location',
                                'address':
                                    'Confirm your meeting point · accuracy ${p.accuracy.round()} m',
                                'lat': p.latitude,
                                'lng': p.longitude,
                              });
                            }
                          } catch (e) {
                            if (mounted) setState(() => error = '$e');
                          } finally {
                            if (mounted) setState(() => locating = false);
                          }
                        },
                ),
                TextButton.icon(
                  onPressed: () async {
                    Record? selected;
                    final result = await showModalBottomSheet<Record>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (c) => StatefulBuilder(
                        builder: (c, update) => SizedBox(
                          height: MediaQuery.sizeOf(c).height * .8,
                          child: ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              const UiText('Choose exact map point'),
                              RoadMap(
                                height: 360,
                                pins: [if (selected != null) selected!],
                                onSelect: (p) => update(() => selected = p),
                              ),
                              if (selected != null)
                                Text(
                                  '${selected!['lat']}, ${selected!['lng']}',
                                ),
                              FilledButton(
                                onPressed: selected == null
                                    ? null
                                    : () => Navigator.pop(c, selected),
                                child: const UiText('Confirm map point'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                    if (result != null && context.mounted) {
                      Navigator.pop(context, result);
                    }
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const UiText('Choose a point on the map'),
                ),
                TextButton(
                  onPressed: () async {
                    Record? selected;
                    await openPage(
                      context,
                      ActionForm(
                        title: 'Exact coordinates',
                        fields: const [
                          FieldSpec('name', 'Meeting point name'),
                          FieldSpec('lat', 'Latitude'),
                          FieldSpec('lng', 'Longitude'),
                        ],
                        action: (b) async {
                          final lat = double.tryParse('${b['lat']}'),
                              lng = double.tryParse('${b['lng']}');
                          if (lat == null ||
                              lng == null ||
                              lat < 23.6 ||
                              lat > 24 ||
                              lng < 90.2 ||
                              lng > 90.6) {
                            throw Exception('Choose coordinates within Dhaka.');
                          }
                          selected = {
                            'name': b['name'],
                            'address': b['name'],
                            'lat': lat,
                            'lng': lng,
                          };
                        },
                      ),
                    );
                    if (selected != null && context.mounted) {
                      Navigator.pop(context, selected);
                    }
                  },
                  child: const UiText('Enter coordinates instead'),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(error!),
                  ),
                for (final p in records(widget.store.data['saved_places']))
                  if ('${p['label']}'.toLowerCase().contains(query))
                    ListTile(
                      leading: const Icon(Icons.bookmark_outline),
                      title: Text('${p['label']}'),
                      subtitle: Text('${record(p['place'])['name']}'),
                      onTap: () => Navigator.pop(context, record(p['place'])),
                    ),
                for (final p in list)
                  if ('${p['name']} ${p['address']}'.toLowerCase().contains(
                    query,
                  ))
                    ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text('${p['name']}'),
                      subtitle: Text('${p['address']}'),
                      onTap: () => Navigator.pop(context, p),
                    ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

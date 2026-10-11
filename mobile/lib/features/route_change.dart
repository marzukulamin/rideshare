import '../ui/localized.dart';

import 'package:flutter/material.dart';

import '../data/platform_store.dart';
import 'booking.dart';
import 'common.dart';

class RouteChangePage extends StatefulWidget {
  final PlatformStore store;
  final Record trip;
  const RouteChangePage({super.key, required this.store, required this.trip});
  @override
  State<RouteChangePage> createState() => _RouteChangePageState();
}

class _RouteChangePageState extends State<RouteChangePage> {
  late Record destination;
  late List<Record> stops;
  Record? quote;
  String? error;
  bool pending = false;
  @override
  void initState() {
    super.initState();
    final s = record(widget.trip['snapshot']);
    destination = record(s['destination']);
    stops = records(s['stops']);
  }

  Future<Record?> choose(String title) => showModalBottomSheet<Record>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => PlacePicker(store: widget.store, title: title),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const UiText('Update route')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const UiText(
            'Review the new itinerary and price. Your original route stays in place until your assigned driver accepts the confirmed change.',
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text('${destination['name']}'),
            subtitle: const UiText('Destination'),
            onTap: () async {
              final p = await choose('New destination');
              if (p != null) {
                setState(() {
                  destination = p;
                  quote = null;
                });
              }
            },
          ),
          for (var i = 0; i < stops.length; i++)
            ListTile(
              title: Text('${stops[i]['name']}'),
              subtitle: const UiText('Stop'),
              trailing: IconButton(
                tooltip: tr(context, 'Remove stop'),
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  stops.removeAt(i);
                  quote = null;
                }),
              ),
            ),
          if (stops.length < 2)
            TextButton.icon(
              onPressed: () async {
                final p = await choose('Add stop');
                if (p != null) {
                  setState(() {
                    stops.add(p);
                    quote = null;
                  });
                }
              },
              icon: const Icon(Icons.add),
              label: const UiText('Add stop'),
            ),
          if (quote != null) ...[
            section('Confirm price change'),
            info('Previous price', money(quote!['previous_fare_minor'])),
            info('New accepted price', money(quote!['fare_minor'])),
            Text('${quote!['policy']}'),
          ],
          if (error != null) Text(error!),
          FilledButton(
            onPressed: pending
                ? null
                : () async {
                    setState(() {
                      pending = true;
                      error = null;
                    });
                    try {
                      if (quote == null) {
                        final r = await widget.store.act('trip-change-quote', {
                          'trip_id': widget.trip['id'],
                          'version': widget.trip['version'],
                          'destination': destination,
                          'stops': stops,
                        }, refresh: false);
                        if (mounted) {
                          setState(() => quote = record(r['change']));
                        }
                      } else {
                        await widget.store.act('trip-change-confirm', {
                          'id': quote!['id'],
                        });
                        if (context.mounted) Navigator.pop(context, true);
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
                  ? 'Review new price'
                  : 'Confirm and ask driver',
            ),
          ),
        ],
      ),
    ),
  );
}

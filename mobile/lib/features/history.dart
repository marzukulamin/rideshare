import '../ui/localized.dart';

import 'package:flutter/material.dart';

import '../data/platform_store.dart';
import 'common.dart';
import 'trip.dart';
import 'receipt.dart';

class TripHistory extends StatefulWidget {
  final PlatformStore store;
  final String scope;
  const TripHistory({super.key, required this.store, this.scope = "customer"});
  @override
  State<TripHistory> createState() => _TripHistoryState();
}

class _TripHistoryState extends State<TripHistory> {
  List<Record> trips = [];
  String? error;
  dynamic next;
  bool loading = false;
  final search = TextEditingController();
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load({bool more = false}) async {
    if (loading) return;
    loading = true;
    try {
      final r = await widget.store.api(
        'history',
        query: {
          'scope': widget.scope,
          'q': search.text,
          'offset': more ? next ?? 0 : 0,
        },
      );
      if (mounted) {
        setState(() {
          trips = more
              ? [...trips, ...records(r['trips'])]
              : records(r['trips']);
          next = r['next_offset'];
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      loading = false;
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: load,
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        UiText('Activity', style: Theme.of(context).textTheme.headlineLarge),
        TextField(
          controller: search,
          decoration: InputDecoration(
            labelText: tr(context, 'Search destination or trip ID'),
            suffixIcon: IconButton(
              onPressed: load,
              icon: const Icon(Icons.search),
              tooltip: tr(context, 'Search trips'),
            ),
          ),
          onSubmitted: (_) => load(),
        ),
        if (error != null) Text(error!),
        if (trips.isEmpty) empty('Your trips appear here after booking.'),
        for (final t in trips)
          Card(
            child: ListTile(
              leading: const Icon(Icons.route),
              title: Text(
                '${record(record(t['snapshot'])['destination'])['name']} · ${money(t['fare_minor'])}',
              ),
              subtitle: Text(
                '${stage(t['status'])} · ${localTime(t['created_at'])}',
              ),
              onTap: () =>
                  openPage(context, TripPage(store: widget.store, id: t['id'])),
            ),
          ),
        if (next != null)
          TextButton(
            onPressed: () => load(more: true),
            child: const UiText('Load more'),
          ),
      ],
    ),
  );
}

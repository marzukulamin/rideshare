import '../ui/localized.dart';

import 'package:flutter/material.dart';

import '../data/platform_store.dart';
import '../ui/road_map.dart';

class NavigationPage extends StatefulWidget {
  final PlatformStore store;
  final String tripId;
  const NavigationPage({super.key, required this.store, required this.tripId});
  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  Record? data;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final r = await widget.store.api(
        'navigation',
        query: {'id': widget.tripId},
      );
      if (mounted) {
        setState(() {
          data = r;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e is ApiFailure && e.status == 403) data = null;
          error = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = record(data?['navigation']);
    return Scaffold(
      appBar: AppBar(
        title: Text('${data?['target'] ?? 'Route directions'}'),
        actions: [
          IconButton(
            onPressed: load,
            tooltip: tr(context, 'Refresh route'),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (error != null) Text(error!),
            if (data == null && error == null) const LinearProgressIndicator(),
            if (data != null) ...[
              RoadMap(height: 260, route: records(n['route'])),
              Text(
                '${(number(n['distance_m']) / 1000).toStringAsFixed(2)} km · approximately ${(number(n['duration_seconds']) / 60).ceil()} minutes',
              ),
              Text('${data!['policy']}'),
              for (final step in records(n['instructions']))
                ListTile(
                  leading: const Icon(Icons.turn_right),
                  title: Text('${step['text']}'),
                  subtitle: Text('${number(step['distance'])} m'),
                ),
            ],
            TextButton(
              onPressed: load,
              child: const UiText('Retry or refresh directions'),
            ),
          ],
        ),
      ),
    );
  }
}

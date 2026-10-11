import '../ui/localized.dart';

import 'package:flutter/material.dart';

import '../data/platform_store.dart';
import 'common.dart';
import 'booking.dart';
import 'support.dart';

class HazardPage extends StatefulWidget {
  final PlatformStore store;
  const HazardPage({super.key, required this.store});
  @override
  State<HazardPage> createState() => _HazardState();
}

class _HazardState extends State<HazardPage> {
  Record? place;
  bool stopped = false;
  String kind = 'road_closed';
  final message = TextEditingController();
  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const UiText('Road report')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const UiText(
            'Stop safely before using this form. Use Safety for immediate danger.',
          ),
          SwitchListTile(
            value: stopped,
            onChanged: (v) => setState(() => stopped = v),
            title: const UiText('I am safely stopped'),
          ),
          if (stopped) ...[
            ListTile(
              title: Text(place?['name'] ?? 'Confirm report location'),
              onTap: () async {
                final p = await showModalBottomSheet<Record>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (c) => PlacePicker(
                    store: widget.store,
                    title: 'Report location',
                  ),
                );
                if (p != null) setState(() => place = p);
              },
            ),
            DropdownButtonFormField<String>(
              initialValue: kind,
              decoration: InputDecoration(
                labelText: tr(context, 'Report type'),
              ),
              items: [
                for (final k in [
                  'road_closed',
                  'collision',
                  'flooding',
                  'obstruction',
                  'map_error',
                ])
                  DropdownMenuItem(value: k, child: Text(stage(k))),
              ],
              onChanged: (v) => kind = v ?? kind,
            ),
            TextField(
              controller: message,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: tr(context, 'Details (optional)'),
              ),
            ),
            FilledButton(
              onPressed: place == null
                  ? null
                  : () => perform(context, () async {
                      final result = await widget.store.act('hazard-report', {
                        'stopped': true,
                        'location': place,
                        'kind': kind,
                        'message': message.text,
                      });
                      if (context.mounted) {
                        await openPage(
                          context,
                          CasePage(store: widget.store, id: result['case_id']),
                        );
                      }
                    }),
              child: const UiText('Submit for moderation'),
            ),
          ],
        ],
      ),
    ),
  );
}

import '../ui/localized.dart';

import 'package:flutter/material.dart';

import '../data/platform_store.dart';
import 'common.dart';

class LostItemPage extends StatefulWidget {
  final PlatformStore store;
  final Record trip;
  const LostItemPage({super.key, required this.store, required this.trip});
  @override
  State<LostItemPage> createState() => _LostItemState();
}

class _LostItemState extends State<LostItemPage> {
  Record? data;
  String? error;
  final description = TextEditingController();
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    description.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final value = await widget.store.api(
        'lost-item',
        query: {'trip_id': widget.trip['id']},
      );
      if (mounted) {
        setState(() {
          data = value;
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

  Future<void> act(String next, [Record values = const {}]) =>
      perform(context, () async {
        await widget.store.act('lost-item-update', {
          'trip_id': widget.trip['id'],
          'version': record(data?['item'])['version'],
          'next': next,
          ...values,
        });
        await load();
      });
  @override
  Widget build(BuildContext context) {
    final item = record(data?['item']);
    final customer =
        number(widget.trip['customer_id']) == number(widget.store.user['id']);
    final consent =
        number(item[customer ? 'customer_consent' : 'driver_consent']) == 1;
    return Scaffold(
      appBar: AppBar(title: const UiText('Lost-item coordination')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (error != null) Text(error!),
            if (data == null)
              const LinearProgressIndicator()
            else ...[
              Text('${data!['policy']}'),
              if (item.isEmpty) ...[
                TextField(
                  controller: description,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    labelText: tr(context, 'Describe the lost item'),
                  ),
                ),
                FilledButton(
                  onPressed: () =>
                      act('report', {'description': description.text}),
                  child: const UiText('Report item'),
                ),
              ] else ...[
                info('Item', item['description']),
                info('Status', stage(item['status'])),
                info('Support case reference', item['case_id']),
                SwitchListTile(
                  value: consent,
                  onChanged: (v) => act('consent', {'consent': v}),
                  title: const UiText(
                    'I consent to support coordinating a safe return',
                  ),
                ),
                if (!customer && item['status'] == 'reported')
                  FilledButton(
                    onPressed: () => act('found'),
                    child: const UiText('I found the item'),
                  ),
                if (consent &&
                    number(item['customer_consent']) == 1 &&
                    number(item['driver_consent']) == 1 &&
                    item['status'] != 'returned')
                  FilledButton(
                    onPressed: () => act('handoff'),
                    child: Text(
                      customer
                          ? 'Confirm I received my item'
                          : 'Confirm I handed over the item',
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

import '../ui/localized.dart';

import 'package:flutter/material.dart';

import '../data/platform_store.dart';
import 'common.dart';
import 'trip.dart';
import 'support.dart';
import 'requests.dart';
import 'driver.dart';

class InboxPage extends StatefulWidget {
  final PlatformStore store;
  const InboxPage({super.key, required this.store});
  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  List<Record> messages = [];
  List<String> categories = [];
  String category = '';
  bool unread = false, loading = false;
  int? next;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load({bool more = false}) async {
    if (loading) return;
    loading = true;
    try {
      final r = await widget.store.api(
        'notifications',
        query: {
          'category': category,
          'unread': unread ? 1 : 0,
          'offset': more ? next ?? 0 : 0,
        },
      );
      if (mounted) {
        setState(() {
          messages = [if (more) ...messages, ...records(r['notifications'])];
          categories = (r['categories'] as List).cast<String>();
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

  Future<void> open(Record message) async {
    await perform(context, () async {
      await widget.store.act('read-notification', {'id': message['id']});
      final target = await widget.store.api(
        'notification-target',
        query: {'id': message['id']},
      );
      if (!mounted) return;
      final id = '${target['id']}';
      switch (target['type']) {
        case 'trip':
          await openPage(context, TripPage(store: widget.store, id: id));
        case 'case':
          await openPage(context, CasePage(store: widget.store, id: id));
        case 'request':
          final result = await widget.store.api('request', query: {'id': id});
          if (!mounted) return;
          await openPage(
            context,
            RequestPage(store: widget.store, data: record(result['request'])),
          );
        case 'offer':
          await openPage(
            context,
            Scaffold(
              appBar: AppBar(title: const UiText('Driver offers')),
              body: DriverPage(store: widget.store),
            ),
          );
      }
      await load();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const UiText('Inbox'),
      actions: [
        IconButton(
          onPressed: () => load(),
          tooltip: tr(context, 'Refresh'),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: category,
            decoration: InputDecoration(
              labelText: tr(context, 'Message category'),
            ),
            items: [
              const DropdownMenuItem(value: '', child: UiText('All messages')),
              for (final c in categories)
                DropdownMenuItem(value: c, child: Text(stage(c))),
            ],
            onChanged: (v) {
              setState(() => category = v ?? '');
              load();
            },
          ),
          SwitchListTile(
            title: const UiText('Unread only'),
            value: unread,
            onChanged: (v) {
              setState(() => unread = v);
              load();
            },
          ),
          if (error != null) Text(error!),
          if (messages.isEmpty) empty('No messages in this filter.'),
          for (final m in messages)
            Card(
              child: ListTile(
                leading: Icon(
                  m['read_at'] == null
                      ? Icons.mark_email_unread
                      : Icons.mark_email_read_outlined,
                ),
                title: Text('${m['title']}'),
                subtitle: Text(
                  '${m['body']}\n${stage(m['category'])} · ${m['created_at']} UTC',
                ),
                onTap: () => open(m),
              ),
            ),
          if (next != null)
            TextButton(
              onPressed: () => load(more: true),
              child: const UiText('Load more'),
            ),
        ],
      ),
    ),
  );
}

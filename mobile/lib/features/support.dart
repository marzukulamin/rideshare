import '../ui/localized.dart';

import 'package:flutter/material.dart';

import '../data/platform_store.dart';
import 'common.dart';
import 'documents.dart';
import 'reply.dart';

import 'dart:convert';

import 'package:file_picker/file_picker.dart';

class NewCasePage extends StatelessWidget {
  final PlatformStore store;
  final String? tripId;
  const NewCasePage({super.key, required this.store, this.tripId});
  @override
  Widget build(BuildContext context) => ActionForm(
    title: 'Get help',
    description: 'Your case and messages are saved for staff review. Urgent safety cases have a restricted queue. This does not dispatch emergency services.',
    fields: const [
      FieldSpec(
        'category',
        'Issue',
        options: [
          'fare',
          'cash_dispute',
          'lost_item',
          'vehicle',
          'safety',
          'assistance',
          'account',
          'appeal',
          'map',
          'other',
        ],
      ),
      FieldSpec('subject', 'Short description'),
      FieldSpec('message', 'Details', multiline: true),
    ],
    submit: 'Submit case',
    action: (b) async {
      final r = await store.act('create-case', {'trip_id': tripId, ...b});
      if (context.mounted) {
        await openPage(context, CasePage(store: store, id: r['case_id']));
      }
      return r;
    },
  );
}

class CasePage extends StatefulWidget {
  final PlatformStore store;
  final String id;
  const CasePage({super.key, required this.store, required this.id});
  @override
  State<CasePage> createState() => _CasePageState();
}

class _CasePageState extends State<CasePage> {
  Record? data;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final r = await widget.store.api('case', query: {'id': widget.id});
      if (mounted) {
        setState(() {
          data = record(r['case']);
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

  Future<void> form(
    String title,
    String action,
    List<FieldSpec> fields,
    Record extra,
  ) async {
    await openPage(
      context,
      ActionForm(
        title: title,
        fields: fields,
        action: (b) => widget.store.act(action, {
          'id': widget.id,
          'version': data!['version'],
          ...extra,
          ...b,
        }),
      ),
    );
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final own = number(data?['user_id']) == number(widget.store.user['id']);
    return Scaffold(
      appBar: AppBar(
        title: const UiText('Help conversation'),
        actions: [
          IconButton(
            onPressed: load,
            icon: const Icon(Icons.refresh),
            tooltip: tr(context, 'Refresh'),
          ),
        ],
      ),
      body: SafeArea(
        child: data == null
            ? Center(
                child: error == null
                    ? const CircularProgressIndicator()
                    : Text(error!),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    '${data!['subject']}',
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  info(
                    'Status',
                    '${stage(data!['status'])} · ${stage(data!['priority'])}',
                  ),
                  info('Review due', '${data!['due_at']} UTC'),
                  if (error != null) Text(error!),
                  for (final file in records(data!['attachments']))
                    ListTile(
                      title: Text(
                        'Private attachment · ${stage(file['mime'])}',
                      ),
                      subtitle: Text('Scan: ${stage(file['scan_status'])}'),
                      onTap: () => openPage(
                        context,
                        DocumentPage(
                          store: widget.store,
                          id: file['id'],
                          attachment: true,
                        ),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () => perform(context, () async {
                      final files = await FilePicker.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                      );
                      if (files.isEmpty) return;
                      final f = files.single;
                      if ((await f.length() ?? 5000001) > 5000000) {
                        throw Exception('Use a file up to 5 MB.');
                      }
                      final bytes = await f.readAsBytes();
                      if (!context.mounted) return;
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const UiText('Submit private evidence?'),
                          content: Text(
                            '${f.name}\nOnly the permitted case participants and staff can review this file after local malware scanning.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const UiText('Back'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: const UiText('Submit'),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true) return;
                      await widget.store.act('case-attachment', {
                        'id': widget.id,
                        'version': data!['version'],
                        'data': base64Encode(bytes),
                      });
                      await load();
                    }),
                    icon: const Icon(Icons.attach_file),
                    label: const UiText('Attach private evidence (up to 5 MB)'),
                  ),

                  for (final m in records(data!['messages']))
                    Card(
                      child: ListTile(
                        title: Text('${m['body']}'),
                        subtitle: Text(
                          '${m['name']} · ${m['created_at']}${number(m['internal_note']) == 1 ? ' · internal note' : ''}${m['delivery'] == null ? '' : ' · ${stage(m['delivery'])}'}',
                        ),
                      ),
                    ),
                  if (own ||
                      number(data!['owner_id']) ==
                          number(widget.store.user['id']))
                    FilledButton(
                      onPressed: () => openPage(
                        context,
                        CaseReplyPage(store: widget.store, data: data!),
                      ).then((_) => load()),
                      child: const UiText('Send reply'),
                    ),
                  if (own &&
                      number(data!['restricted']) != 1 &&
                      data!['category'] != 'assistance')
                    TextButton(
                      onPressed: () => perform(context, () async {
                        await widget.store.act('case-close', {
                          'id': widget.id,
                          'version': data!['version'],
                          'reopen': data!['status'] == 'resolved',
                        });
                        await load();
                      }),
                      child: Text(
                        data!['status'] == 'resolved'
                            ? 'Reopen conversation'
                            : 'Close conversation',
                      ),
                    ),
                  if (!own) ...[
                    TextButton(
                      onPressed: () =>
                          form('Case action', 'case-update', const [
                            FieldSpec(
                              'status',
                              'Action',
                              options: [
                                'claim',
                                'in_progress',
                                'waiting_for_customer',
                                'resolved',
                                'escalate',
                              ],
                            ),
                            FieldSpec('reason', 'Reason', multiline: true),
                          ], {}),
                      child: const UiText('Claim or update case'),
                    ),
                    TextButton(
                      onPressed: () => form(
                        'Internal staff note',
                        'case-message',
                        const [FieldSpec('message', 'Note', multiline: true)],
                        {'internal_note': true},
                      ),
                      child: const UiText('Add internal note'),
                    ),
                    if (widget.store.can('supervisor'))
                      TextButton(
                        onPressed: () => form(
                          'Reassign case',
                          'case-update',
                          const [
                            FieldSpec(
                              'owner_id',
                              'New eligible staff account ID',
                            ),
                            FieldSpec('reason', 'Reason', multiline: true),
                          ],
                          {'status': 'reassign'},
                        ),
                        child: const UiText('Reassign case'),
                      ),
                    if (widget.store.can('exclusions') &&
                        number(data!['restricted']) == 1 &&
                        data!['trip_id'] != null)
                      TextButton(
                        onPressed: () => form(
                          'Prevent this pairing',
                          'pairing-exclusion',
                          const [
                            FieldSpec(
                              'reason',
                              'Reviewed safety reason',
                              multiline: true,
                            ),
                          ],
                          {'case_id': widget.id},
                        ),
                        child: const UiText(
                          'Apply confidential pairing exclusion',
                        ),
                      ),
                  ],
                ],
              ),
      ),
    );
  }
}

Widget caseTile(PlatformStore store, Record c) => Card(
  child: ListTile(
    leading: Icon(
      number(c['restricted']) == 1 ? Icons.shield : Icons.support_agent,
    ),
    title: Text('${c['subject']}'),
    subtitle: Text(
      '${stage(c['status'])} · ${stage(c['priority'])}\nReview due ${c['due_at']} UTC',
    ),
    isThreeLine: true,
    onTap: null,
  ),
);
Widget casesPage(PlatformStore store, {bool staff = false}) => DataPage(
  store: store,
  title: staff ? 'Staff case queue' : 'Your help cases',
  action: 'cases',
  query: {'scope': staff ? 'staff' : 'own'},
  keyName: 'cases',
  item: (context, c, reload) => Card(
    child: ListTile(
      leading: Icon(
        number(c['restricted']) == 1 ? Icons.shield : Icons.support_agent,
      ),
      title: Text('${c['subject']}'),
      subtitle: Text('${stage(c['status'])} · due ${c['due_at']} UTC'),
      onTap: () => openPage(
        context,
        CasePage(store: store, id: c['id']),
      ).then((_) => reload()),
    ),
  ),
);

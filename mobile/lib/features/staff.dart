import '../ui/localized.dart';

import 'package:flutter/material.dart';

import '../data/platform_store.dart';
import 'common.dart';
import 'documents.dart';
import 'requests.dart';
import 'support.dart';
import 'trip.dart';

class StaffPage extends StatefulWidget {
  final PlatformStore store;
  const StaffPage({super.key, required this.store});
  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  Record? data;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final r = await widget.store.api('staff-overview');
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

  Future<void> review(
    String title,
    String action,
    Record r,
    List<String> statuses,
  ) async {
    await openPage(
      context,
      ActionForm(
        title: title,
        fields: [
          FieldSpec('status', 'Decision', options: statuses),
          const FieldSpec(
            'reason',
            'Review evidence and reason',
            multiline: true,
          ),
        ],
        action: (b) => widget.store.act(action, {
          'id': r['id'] ?? r['user_id'],
          'version': r['version'],
          ...b,
        }),
      ),
    );
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          UiText(
            'Staff workspace',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          Text((store.user['roles'] as List).map(stage).join(' · ')),
          if (error != null) Text(error!),
          if (data == null)
            const LinearProgressIndicator()
          else ...[
            Text('Updated ${data!['as_of']}'),
            if (data!['operations_health'] != null) ...[
              section('Operations health'),
              info(
                'Last service check',
                record(data!['operations_health'])['as_of'] ??
                    'No check recorded',
              ),
              info(
                'Freshness',
                record(data!['operations_health'])['fresh'] == true
                    ? 'Current'
                    : 'Service check is overdue',
              ),
              for (final dependency in record(
                record(data!['operations_health'])['health'],
              ).entries)
                info(
                  stage(dependency.key),
                  dependency.value == true ? 'Healthy' : 'Needs attention',
                ),
              info(
                'Overdue cases',
                record(data!['operations_health'])['overdue_cases'] ??
                    'Not checked',
              ),
              info(
                'Online drivers without recent acknowledgement',
                record(data!['operations_health'])['stale_online_drivers'] ??
                    'Not checked',
              ),
            ],
            if (data!['intakes'] != null) ...[
              section('Restricted intake'),
              for (final i in records(data!['intakes']))
                Card(
                  child: ListTile(
                    title: Text('${stage(i['kind'])} · ${stage(i['status'])}'),
                    subtitle: Text(
                      'Reference ${i['id']} · ${i['created_at']} UTC',
                    ),
                    onTap: () => openPage(
                      context,
                      ActionForm(
                        title: 'Restricted intake review',
                        description: 'Verify identity using independently checked evidence before approving recovery. A verified status alone cannot restore account access.',
                        fields: const [
                          FieldSpec(
                            'purpose',
                            'Purpose for private contact and message access',
                            multiline: true,
                          ),
                          FieldSpec(
                            'status',
                            'Review state',
                            options: [
                              'in_review',
                              'verified',
                              'rejected',
                              'completed',
                            ],
                          ),
                          FieldSpec(
                            'reason',
                            'Private verification evidence and reason',
                            multiline: true,
                          ),
                          FieldSpec(
                            'reply',
                            'Public reply to the requester',
                            multiline: true,
                          ),
                        ],
                        action: (b) async {
                          final detail = await store.act('intake-detail', {
                            'id': i['id'],
                            'purpose': b['purpose'],
                          }, refresh: false);
                          if (!context.mounted) {
                            throw Exception('Review closed.');
                          }
                          final item = record(detail['intake']);
                          final proceed = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const UiText('Private intake review'),
                              content: SingleChildScrollView(
                                child: Text(
                                  '${item['contact']}\n\n${item['message']}',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: const UiText('Back'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  child: const UiText(
                                    'Confirm reviewed decision',
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (proceed != true) {
                            throw Exception('Review was not submitted.');
                          }
                          return store.act('intake-update', {
                            'id': i['id'],
                            'version': i['version'],
                            ...b,
                          });
                        },
                      ),
                    ).then((_) => load()),
                  ),
                ),
            ],
            if (data!['metrics'] != null) ...[
              section('Market overview'),
              for (final e in record(data!['metrics']).entries)
                info(
                  stage(e.key),
                  e.key.endsWith('minor') ? money(e.value) : e.value,
                ),
            ],
            if (store.can('cases') || store.can('assistance'))
              ListTile(
                leading: const Icon(Icons.support_agent),
                title: const UiText('Case queue and conversations'),
                onTap: () => openPage(context, casesPage(store, staff: true)),
              ),
            ListTile(
              leading: const Icon(Icons.fact_check),
              title: const UiText('Proposals and approvals'),
              onTap: () =>
                  openPage(context, requestsPage(store)).then((_) => load()),
            ),
            if (store.can('trips')) ...[
              section('Trips'),
              for (final t in records(data!['trips']))
                Card(
                  child: ListTile(
                    title: Text(
                      '${record(record(t['snapshot'])['pickup'])['name']} → ${record(record(t['snapshot'])['destination'])['name']}',
                    ),
                    subtitle: Text(
                      '${stage(t['status'])} · ${money(t['fare_minor'])}',
                    ),
                    onTap: () =>
                        openPage(context, TripPage(store: store, id: t['id'])),
                    trailing: store.can('dispatch') && t['status'] == 'matching'
                        ? IconButton(
                            tooltip: tr(context, 'Request rematching'),
                            icon: const Icon(Icons.refresh),
                            onPressed: () => openPage(
                              context,
                              ActionForm(
                                title: 'Rematch pending trip',
                                fields: const [
                                  FieldSpec('reason', 'Operational reason'),
                                ],
                                action: (b) => store.act('dispatch-rematch', {
                                  'trip_id': t['id'],
                                  'version': t['version'],
                                  ...b,
                                }),
                              ),
                            ).then((_) => load()),
                          )
                        : null,
                  ),
                ),
            ],
            if (store.can('onboarding')) ...[
              section('Driver reviews'),
              for (final d in records(data!['drivers']))
                ListTile(
                  title: Text('${d['name']}'),
                  subtitle: Text(
                    '${stage(d['status'])} · identity ${stage(d['identity_status'])}\n${d['reason'] ?? ''}',
                  ),
                  onTap: () => review('Driver decision', 'driver-decision', d, [
                    'approved',
                    'review',
                    'rejected',
                    'suspended',
                  ]),
                ),
              section('Document reviews'),
              for (final d in records(data!['documents']))
                ListTile(
                  title: Text('${d['name']} · ${stage(d['kind'])}'),
                  trailing: IconButton(
                    tooltip: tr(context, 'Review private file'),
                    icon: const Icon(Icons.visibility_outlined),
                    onPressed: () => openPage(
                      context,
                      DocumentPage(store: store, id: number(d['id'])),
                    ),
                  ),
                  subtitle: Text(
                    '${stage(d['status'])} · expiry ${d['expires_at'] ?? 'not provided'}',
                  ),
                  onTap: () => review(
                    'Document decision',
                    'document-decision',
                    d,
                    ['approved', 'rejected'],
                  ),
                ),
              section('Vehicle reviews'),
              for (final v in records(data!['vehicles']))
                ListTile(
                  title: Text('${v['driver_name']} · ${v['label']}'),
                  subtitle: Text('${v['plate']} · ${stage(v['status'])}'),
                  onTap: () => review(
                    'Vehicle decision',
                    'vehicle-decision',
                    v,
                    ['approved', 'review', 'rejected'],
                  ),
                ),
            ],
            if (store.can('configuration')) ...[
              section('Service catalog'),
              for (final p in records(data!['products']))
                ListTile(
                  title: Text('${p['name']} · ${money(p['rate_minor'])}/km'),
                  subtitle: Text(
                    'ID ${p['id']} · version ${p['version']} · ${number(p['active']) == 1 ? 'available' : 'not offered'}',
                  ),
                  onTap: () => openPage(
                    context,
                    NewRequestPage(
                      store: store,
                      kind: 'pricing',
                      initial: {
                        'product_id': p['id'],
                        'version': p['version'],
                        'rate_minor': p['rate_minor'],
                        'driver_share_bps': p['driver_share_bps'],
                      },
                    ),
                  ),
                ),
            ],
            if (store.can('access')) ...[
              section('Account access'),
              for (final u in records(data!['users']))
                ListTile(
                  title: Text('${u['name']} · ID ${u['id']}'),
                  subtitle: Text(
                    '${u['roles'].join(', ')} · ${stage(u['status'])}',
                  ),
                  onTap: () => openPage(
                    context,
                    NewRequestPage(
                      store: store,
                      kind: 'role_grant',
                      initial: {'user_id': u['id']},
                    ),
                  ),
                ),
            ],
            if (store.can('finance')) ...[
              section('Reconciliation'),
              info(
                'Unbalanced journals',
                records(data!['reconciliation']).length,
              ),
              for (final t in records(data!['cash_exceptions']))
                info(
                  'Trip ${t['id']}',
                  '${money(t['fare_minor'])} · ${stage(t['payment_status'])}',
                ),
              section('Financial journals'),
              for (final j in records(data!['journals']))
                info(
                  stage(j['kind']),
                  '${j['trip_id'] ?? 'Settlement'}\n${j['evidence'] ?? 'Recorded trip event'}',
                ),
            ],
            if (data!['workforce'] != null) ...[
              section('Case workload'),
              for (final a in records(data!['workforce']))
                info(
                  '${a['name']} · ${a['role_key']}',
                  '${a['open_cases']} open cases · ID ${a['id']}',
                ),
            ],
            if (data!['audit'] != null) ...[
              section('Audit trail'),
              for (final a in records(data!['audit']))
                info(
                  '${a['action_key']} · actor ${a['actor_id']}',
                  '${a['reason']}\n${a['created_at']} UTC',
                ),
            ],
            for (final kind in [
              'content',
              'incidents',
              'releases',
              'legal_holds',
            ])
              if (data![kind] != null) ...[
                section(stage(kind)),
                for (final item in records(data![kind]))
                  ListTile(
                    title: Text(
                      '${item['title'] ?? item['summary'] ?? item['build_version'] ?? item['legal_basis']}',
                    ),
                    subtitle: Text(
                      '${item['status'] ?? item['locale'] ?? item['jurisdiction']} · version ${item['version'] ?? 1}',
                    ),
                    onTap: () => openPage(
                      context,
                      NewRequestPage(
                        store: store,
                        kind: switch (kind) {
                          'incidents' => 'incident',
                          'releases' => 'release',
                          'legal_holds' => 'legal_hold',
                          _ => 'content',
                        },
                        initial: {
                          ...item,
                          if (kind == 'content') 'key': item['content_key'],
                          if (kind == 'content') 'text': item['body'],
                          if (kind == 'releases')
                            'health_gates': item['health_gates'],
                        },
                      ),
                    ),
                  ),
              ],
            section('Create reviewed proposal'),
            for (final e in requestPermissions.entries)
              if (store.can(e.value) &&
                  !{
                    'refund',
                    'fare_adjustment',
                    'payout',
                    'payout_destination',
                    'data_export',
                    'account_deletion',
                    'contact_verification',
                    'identity_recheck',
                    'appeal',
                  }.contains(e.key))
                ListTile(
                  leading: const Icon(Icons.add_task),
                  title: Text(stage(e.key)),
                  onTap: () => openPage(
                    context,
                    NewRequestPage(store: store, kind: e.key),
                  ),
                ),
            if (store.can('reports'))
              TextButton(
                onPressed: () => openPage(
                  context,
                  ActionForm(
                    title: 'Aggregate report export',
                    description: 'Small cohorts are suppressed. Export requests and purposes are audited.',
                    fields: const [FieldSpec('purpose', 'Purpose')],
                    action: (b) async {
                      final r = await store.act('report-export', b);
                      if (!context.mounted) throw Exception('Review closed.');
                      await showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const UiText('Aggregate report'),
                          content: SelectableText('${r['report']}'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c),
                              child: const UiText('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                child: const UiText('Generate aggregate report'),
              ),
          ],
        ],
      ),
    );
  }
}

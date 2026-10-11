import '../ui/localized.dart';

import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/platform_store.dart';
import 'common.dart';

const requestPermissions = {
  'payout_hold': 'finance',
  'feedback_policy': 'configuration',
  'operating_rules': 'configuration',
  'feature_flag': 'incidents',
  'retention_policy': 'privacy',
  'interrupted_fare': 'finance',
  'configuration_rollback': 'configuration',
  'cash_resolution': 'finance',
  'manual_collection': 'finance',
  'refund': 'finance',
  'fare_adjustment': 'finance',
  'payout': 'finance',
  'payout_destination': 'finance',
  'legal_hold': 'privacy',
  'data_export': 'privacy',
  'account_deletion': 'privacy',
  'contact_verification': 'onboarding',
  'identity_recheck': 'onboarding',
  'pricing': 'configuration',
  'product': 'configuration',
  'market': 'configuration',
  'terms': 'configuration',
  'promotion': 'configuration',
  'content': 'configuration',
  'role_grant': 'access',
  'role_revoke': 'access',
  'restriction': 'safety',
  'reinstatement': 'safety',
  'matching_pause': 'dispatch',
  'incident': 'incidents',
  'release': 'incidents',
  'appeal': 'safety',
  'recovery': 'access',
};
List<FieldSpec> proposalFields(String kind) => switch (kind) {
  'feedback_policy' => const [
    FieldSpec('rating_window_seconds', 'Feedback window in seconds'),
    FieldSpec('version', 'Current feedback settings version'),
    FieldSpec('policy_basis', 'Policy basis and scope', multiline: true),
  ],
  'operating_rules' => const [
    FieldSpec('work_limit_seconds', 'Platform work limit in seconds'),
    FieldSpec('rest_seconds', 'Required rest in seconds'),
    FieldSpec('work_warning_seconds', 'Advance warning in seconds'),
    FieldSpec('document_warning_days', 'Document expiry warning days'),
    FieldSpec('version', 'Current operations settings version'),
    FieldSpec(
      'policy_basis',
      'Verified operating policy basis',
      multiline: true,
    ),
  ],
  'feature_flag' => const [
    FieldSpec(
      'key',
      'Optional implemented feature',
      options: ['driver_practice', 'discovery_cards', 'promotions'],
    ),
    FieldSpec('enabled', 'Enabled', options: ['false', 'true']),
    FieldSpec('scope', 'Scope', options: ['market', 'accounts']),
    FieldSpec('account_ids', 'Account IDs JSON array', initial: '[]'),
    FieldSpec('expires_at', 'Expiry YYYY-MM-DD'),
    FieldSpec('version', 'Current flag version', optional: true),
  ],
  'retention_policy' => const [
    FieldSpec('trip_location_days', 'Ended-trip location retention days'),
    FieldSpec('closed_case_days', 'Closed case content retention days'),
    FieldSpec(
      'deleted_document_days',
      'Deleted account document retention days',
    ),
    FieldSpec('session_days', 'Expired session retention days'),
    FieldSpec('legal_basis', 'Verified retention basis', multiline: true),
    FieldSpec('jurisdiction', 'Jurisdiction'),
    FieldSpec(
      'version',
      'Current retention configuration version',
      optional: true,
    ),
  ],
  'configuration_rollback' => const [
    FieldSpec('change_id', 'Applied configuration reference to restore'),
    FieldSpec('version', 'Current target version'),
  ],
  'interrupted_fare' => const [
    FieldSpec('trip_id', 'Interrupted trip ID'),
    FieldSpec('amount', 'Reviewed customer fare in BDT (zero allowed)'),
    FieldSpec('earning_minor', 'Reviewed driver earning in paisa'),
    FieldSpec('billable_distance_m', 'Verified billable distance in metres'),
    FieldSpec(
      'review_evidence',
      'Independent distance and fare evidence',
      multiline: true,
    ),
  ],
  'cash_resolution' => const [
    FieldSpec('trip_id', 'Trip ID'),
    FieldSpec(
      'decision',
      'Reviewed collection outcome',
      options: ['confirmed', 'reversed'],
    ),
  ],
  'manual_collection' => const [
    FieldSpec('trip_id', 'Trip ID'),
    FieldSpec('amount', 'Verified settlement amount in BDT'),
  ],
  'data_export' || 'account_deletion' => const [
    FieldSpec('password', 'Confirm your current password', secret: true),
  ],
  'recovery' => const [
    FieldSpec('intake_id', 'Verified intake reference'),
    FieldSpec('user_id', 'Manually matched account ID'),
    FieldSpec(
      'identity_evidence',
      'Identity verification evidence',
      multiline: true,
    ),
  ],
  'refund' || 'fare_adjustment' => const [
    FieldSpec('trip_id', 'Trip ID'),
    FieldSpec('amount', 'Amount in BDT'),
  ],
  'payout_hold' => const [
    FieldSpec('user_id', 'Driver account ID'),
    FieldSpec('held', 'Hold settlement', options: ['true', 'false']),
    FieldSpec('version', 'Current hold version (0 for first)', initial: '0'),
  ],
  'payout' => const [FieldSpec('amount', 'Amount in BDT')],
  'payout_destination' => const [
    FieldSpec('destination', 'Settlement destination'),
    FieldSpec('evidence', 'Destination ownership evidence'),
    FieldSpec('password', 'Your current password', secret: true),
  ],
  'pricing' => const [
    FieldSpec('product_id', 'Product ID'),
    FieldSpec('version', 'Current product version'),
    FieldSpec('rate_minor', 'Rate per km in paisa'),
    FieldSpec('driver_share_bps', 'Driver share basis points (10000 = 100%)'),
  ],
  'product' => const [
    FieldSpec('product_id', 'Product ID'),
    FieldSpec('version', 'Current product version'),
    FieldSpec('active', 'Available', options: ['true', 'false']),
  ],
  'role_grant' || 'role_revoke' => const [
    FieldSpec('user_id', 'Target user ID'),
    FieldSpec(
      'role',
      'Role',
      options: [
        'customer',
        'driver',
        'support',
        'safety',
        'dispatch',
        'onboarding',
        'finance',
        'supervisor',
        'admin',
        'compliance',
        'oncall',
      ],
    ),
  ],
  'restriction' => const [
    FieldSpec('user_id', 'Target user ID'),
    FieldSpec(
      'policy_basis',
      'Verified restriction policy and scope',
      multiline: true,
    ),
    FieldSpec(
      'duration_seconds',
      'Duration in seconds (0 = independent review required)',
    ),
    FieldSpec('appeal_window_days', 'Reviewed appeal window in days'),
  ],
  'reinstatement' => const [FieldSpec('user_id', 'Target user ID')],
  'matching_pause' => const [
    FieldSpec('paused', 'Pause matching', options: ['true', 'false']),
  ],
  'market' => const [FieldSpec('radius_km', 'Service radius in km')],
  'terms' => const [
    FieldSpec('version', 'New version name'),
    FieldSpec('title', 'Title'),
    FieldSpec('body', 'Full terms', multiline: true),
  ],
  'promotion' => const [
    FieldSpec('code', 'Promotion code'),
    FieldSpec('description', 'Description'),
    FieldSpec('discount_minor', 'Discount in paisa'),
    FieldSpec('maximum_uses', 'Maximum total uses'),
  ],
  'legal_hold' => const [
    FieldSpec('user_id', 'Account ID'),
    FieldSpec('legal_reason', 'Scope and reason', multiline: true),
    FieldSpec('legal_basis', 'Verified legal basis'),
    FieldSpec('jurisdiction', 'Jurisdiction'),
    FieldSpec('expires_at', 'Hold expiry YYYY-MM-DD'),
    FieldSpec('release_id', 'Existing hold ID to release', optional: true),
  ],
  'content' => const [
    FieldSpec(
      'key',
      'Key (help.topic / discovery.place / notice.name / template.reply)',
    ),
    FieldSpec('locale', 'Locale', options: ['en-BD', 'bn-BD']),
    FieldSpec('title', 'Title'),
    FieldSpec('text', 'Content', multiline: true),
    FieldSpec('version', 'Existing version (0 for new)', initial: '0'),
    FieldSpec('active', 'Visible', options: ['true', 'false']),
    FieldSpec('expires_at', 'Optional expiry YYYY-MM-DD', optional: true),
  ],
  'incident' => const [
    FieldSpec('id', 'Existing incident ID (blank for new)', optional: true),
    FieldSpec('version', 'Existing version (0 for new)', initial: '0'),
    FieldSpec('summary', 'Summary'),
    FieldSpec(
      'severity',
      'Severity',
      options: ['critical', 'high', 'medium', 'low'],
    ),
    FieldSpec(
      'status',
      'Stage',
      options: ['open', 'mitigating', 'monitoring', 'resolved'],
    ),
    FieldSpec('user_impact', 'User impact', multiline: true),
    FieldSpec('runbook', 'Runbook and dependency health', multiline: true),
    FieldSpec(
      'mitigation',
      'Mitigation evidence',
      multiline: true,
      optional: true,
    ),
    FieldSpec(
      'follow_up',
      'Follow-up owners/actions',
      multiline: true,
      optional: true,
    ),
  ],
  'release' => const [
    FieldSpec('id', 'Existing release ID (blank for new)', optional: true),
    FieldSpec('version', 'Existing record version', initial: '0'),
    FieldSpec('build_version', 'Build version'),
    FieldSpec(
      'status',
      'Stage',
      options: [
        'staged',
        'approved',
        'rolling_out',
        'paused',
        'rolled_back',
        'completed',
      ],
    ),
    FieldSpec('cohort', 'Account/market cohort'),
    FieldSpec(
      'health_gates',
      'Verified gates JSON',
      initial: '{"roles_passed":false,"journals_balanced":false,"rollback_checked":false}',
      multiline: true,
    ),
    FieldSpec(
      'migration_compatible',
      'Additive migration compatibility verified',
      options: ['false', 'true'],
    ),
    FieldSpec('rollback_target', 'Previous compatible build version'),
  ],
  _ => const [],
};

class NewRequestPage extends StatelessWidget {
  final PlatformStore store;
  final String kind;
  final Record initial;
  const NewRequestPage({
    super.key,
    required this.store,
    required this.kind,
    this.initial = const {},
  });
  @override
  Widget build(BuildContext context) => ActionForm(
    title: stage(kind),
    description: 'This saves a proposal for a separate permitted reviewer. Financial execution requires evidence of the actual cash handoff or independently performed transfer.',
    fields: [
      for (final f in proposalFields(kind))
        FieldSpec(
          f.key,
          f.label,
          initial: '${initial[f.key] ?? f.initial}',
          secret: f.secret,
          multiline: f.multiline,
          optional: f.optional,
          options: f.options,
        ),
      if ({'pricing', 'product', 'market', 'matching_pause'}.contains(kind))
        const FieldSpec(
          'effective_at',
          'Effective ISO date/time with offset (blank for now)',
          optional: true,
        ),
      const FieldSpec('reason', 'Reason for review', multiline: true),
    ],
    submit: 'Submit for review',
    action: (b) {
      final payload = <String, dynamic>{...b}
        ..remove('reason')
        ..remove('trip_id')
        ..remove('password');
      if (payload.containsKey('amount')) {
        final amount = double.tryParse('${payload.remove('amount')}');
        if (amount == null || !amount.isFinite) {
          throw ApiFailure('Enter a valid amount in BDT.', 422);
        }
        payload['amount_minor'] = (amount * 100).round();
      }
      for (final key in [
        'user_id',
        'product_id',
        'version',
        'rate_minor',
        'driver_share_bps',
        'amount_minor',
        'trip_location_days',
        'closed_case_days',
        'deleted_document_days',
        'session_days',
        'earning_minor',
        'billable_distance_m',
        'maximum_uses',
        'discount_minor',
        'rating_window_seconds',
        'work_limit_seconds',
        'rest_seconds',
        'work_warning_seconds',
        'document_warning_days',
        'duration_seconds',
        'appeal_window_days',
      ]) {
        if (payload.containsKey(key)) payload[key] = number(payload[key]);
      }
      if (payload.containsKey('account_ids')) {
        payload['account_ids'] = jsonDecode('${payload['account_ids']}');
      }
      for (final key in [
        'held',
        'enabled',
        'paused',
        'active',
        'migration_compatible',
      ]) {
        if (payload.containsKey(key)) payload[key] = payload[key] == 'true';
      }
      return store.act('create-request', {
        'kind': kind,
        'reason': b['reason'],
        'trip_id': b['trip_id'] ?? initial['trip_id'],
        'payload': payload,
        'password': b['password'],
      });
    },
  );
}

Widget requestsPage(PlatformStore store) => DataPage(
  store: store,
  title: 'Requests and approvals',
  action: 'requests',
  keyName: 'requests',
  item: (c, r, reload) => Card(
    child: ListTile(
      leading: const Icon(Icons.fact_check_outlined),
      title: Text(stage(r['kind'])),
      subtitle: Text('${stage(r['status'])} · ${r['reason']}'),
      onTap: () =>
          openPage(c, RequestPage(store: store, data: r)).then((_) => reload()),
    ),
  ),
);

class RequestPage extends StatefulWidget {
  final PlatformStore store;
  final Record data;
  const RequestPage({super.key, required this.store, required this.data});
  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  late Record r;
  @override
  void initState() {
    super.initState();
    r = widget.data;
    widget.store
        .api('request', query: {'id': r['id']})
        .then((value) {
          if (mounted) setState(() => r = record(value['request']));
        })
        .catchError((Object e) {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('$e')));
          }
        });
  }

  Future<void> action(String a, List<FieldSpec> fields, Record extra) async {
    final done = await openPage<bool>(
      context,
      ActionForm(
        title: a == 'request-execute'
            ? 'Execute approved proposal'
            : 'Review exact proposal',
        fields: fields,
        action: (b) => widget.store.act(a, {
          'id': r['id'],
          'version': r['version'],
          'proposal_hash': r['proposal_hash'],
          ...extra,
          ...b,
        }),
      ),
    );
    if (done == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final reviewer =
        number(r['user_id']) != number(widget.store.user['id']) &&
        widget.store.can(requestPermissions[r['kind']] ?? 'unavailable');
    return Scaffold(
      appBar: AppBar(title: Text(stage(r['kind']))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            info('Status', stage(r['status'])),
            info('Reason', r['reason']),
            info('Expires', '${r['expires_at']} UTC'),
            info('Proposal version', r['version']),
            section('Exact proposed changes'),
            if (r['kind'] == 'data_export' && r['status'] == 'executed')
              TextButton(
                onPressed: () => perform(context, () async {
                  final data = await widget.store.api(
                    'request-result',
                    query: {'id': r['id']},
                  );
                  if (!context.mounted) return;
                  await showDialog(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const UiText('Your exported data'),
                      content: SingleChildScrollView(
                        child: SelectableText(
                          const JsonEncoder.withIndent('  ')
                              .convert(data['result']),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c),
                          child: const UiText('Close'),
                        ),
                      ],
                    ),
                  );
                }),
                child: const UiText('View my data export'),
              ),
            for (final e in record(r['payload']).entries)
              info(
                stage(e.key),
                e.value is Map || e.value is List
                    ? const JsonEncoder.withIndent('  ').convert(e.value)
                    : e.value,
              ),
            if (number(r['user_id']) == number(widget.store.user['id']) &&
                r['status'] == 'pending')
              TextButton(
                onPressed: () => action('request-withdraw', const [
                  FieldSpec('reason', 'Withdrawal reason', multiline: true),
                ], {}),
                child: const UiText('Withdraw pending request'),
              ),
            if (reviewer && r['status'] == 'pending')
              FilledButton(
                onPressed: () => action('request-decision', const [
                  FieldSpec(
                    'decision',
                    'Decision',
                    options: ['approved', 'rejected'],
                  ),
                  FieldSpec('reason', 'Review reason', multiline: true),
                ], {}),
                child: const UiText('Review proposal'),
              ),
            if (reviewer &&
                ['approved', 'execution_failed', 'held'].contains(r['status']))
              FilledButton(
                onPressed: () => action('request-execute', [
                  if ([
                    'refund',
                    'payout',
                    'manual_collection',
                  ].contains(r['kind']))
                    const FieldSpec(
                      'execution_outcome',
                      'Actual money movement outcome',
                      options: ['succeeded', 'failed', 'held'],
                    ),
                  FieldSpec('evidence', 'Execution evidence', multiline: true),
                ], {}),
                child: const UiText('Execute approved action'),
              ),
            for (final attempt in records(r['attempts']))
              info(
                'Execution ${stage(attempt['outcome'])}',
                '${attempt['evidence']} · ${attempt['created_at']} UTC',
              ),
            if (!reviewer)
              const UiText('The requester cannot approve their own proposal.'),
          ],
        ),
      ),
    );
  }
}

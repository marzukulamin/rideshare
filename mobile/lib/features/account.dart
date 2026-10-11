import '../ui/localized.dart';

import 'package:flutter/material.dart';

import '../data/platform_store.dart';
import 'common.dart';
import 'booking.dart';
import 'requests.dart';
import 'support.dart';
import 'safety.dart';
import 'receipt.dart';

class AccountPage extends StatelessWidget {
  final PlatformStore store;
  const AccountPage({super.key, required this.store});
  @override
  Widget build(BuildContext context) {
    final preferences = record(store.user['preferences']);
    final restriction = record(store.data['restriction']);
    Widget tile(String title, IconData icon, Widget page) => ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => openPage(context, page),
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '${store.user['name']}',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        Text('${store.user['phone']} · ${store.user['roles'].join(', ')}'),
        section('Account'),
        if (restriction.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account restriction',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${restriction['reason']}\nPolicy: ${restriction['policy_basis']}\n${restriction['expires_at'] == null ? 'Independent review required' : 'Reviewed expiry: ${localTime(restriction['expires_at'])}'}\nAppeal review date: ${localTime(restriction['appeal_until'])}',
                  ),
                  TextButton(
                    onPressed: () => openPage(
                      context,
                      NewRequestPage(store: store, kind: 'appeal'),
                    ),
                    child: const UiText('Submit appeal'),
                  ),
                ],
              ),
            ),
          ),
        SwitchListTile(
          value: preferences['notifications'] != false,
          title: const UiText('Routine ride offer notifications'),
          subtitle: const UiText(
            'Safety updates remain in your inbox. Location tracking keeps its visible device notification.',
          ),
          onChanged: (v) => perform(
            context,
            () => store.act('preferences', {'notifications': v}),
          ),
        ),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: '${preferences['theme'] ?? 'dark'}',
          decoration: InputDecoration(labelText: tr(context, 'Appearance')),
          items: const [
            DropdownMenuItem(value: 'dark', child: UiText('Dark')),
            DropdownMenuItem(value: 'light', child: UiText('Light')),
            DropdownMenuItem(value: 'system', child: UiText('Device setting')),
          ],
          onChanged: (v) =>
              perform(context, () => store.act('preferences', {'theme': v})),
        ),
        TextButton(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const UiText('Sign out all other devices?'),
                content: const UiText(
                  'Other devices must sign in again. This device stays signed in.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const UiText('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const UiText('Sign out other devices'),
                  ),
                ],
              ),
            );
            if (confirmed == true && context.mounted) {
              await perform(
                context,
                () => store.act('revoke-other-sessions', {}),
              );
            }
          },
          child: const UiText('Sign out all other devices'),
        ),

        tile(
          'Profile',
          Icons.person_outline,
          ActionForm(
            title: 'Profile',
            fields: [
              FieldSpec('name', 'Full name', initial: '${store.user['name']}'),
              FieldSpec(
                'locale',
                'Language',
                initial: '${store.user['locale']}',
                options: const ['en-BD', 'bn-BD'],
              ),
            ],
            action: (b) => store.act('profile', b),
          ),
        ),
        tile(
          'Password and security',
          Icons.lock_outline,
          ActionForm(
            title: 'Change password',
            fields: const [
              FieldSpec('current_password', 'Current password', secret: true),
              FieldSpec(
                'new_password',
                'New password (12+ characters)',
                secret: true,
              ),
            ],
            description: 'Changing your password revokes your other sessions.',
            action: (b) => store.act('password', b),
          ),
        ),
        tile(
          'Signed-in devices',
          Icons.devices,
          DataPage(
            store: store,
            title: 'Your sessions',
            action: 'sessions',
            keyName: 'sessions',
            item: (c, s, reload) => ListTile(
              title: Text('${s['device_label']}'),
              subtitle: Text('Last seen ${s['seen_at']} UTC'),
              trailing: TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: c,
                    builder: (dialog) => AlertDialog(
                      title: const UiText('Sign out this device?'),
                      content: UiText(
                        number(s['current_session']) == 1
                            ? 'This device will return to sign in.'
                            : 'That device must sign in again.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialog, false),
                          child: const UiText('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialog, true),
                          child: const UiText('Sign out device'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && c.mounted) {
                    await perform(c, () async {
                      await store.act('revoke-session', {'id': s['id']});
                      reload();
                    });
                  }
                },
                child: UiText(
                  number(s['current_session']) == 1
                      ? 'Sign out here'
                      : 'Revoke',
                ),
              ),
            ),
          ),
        ),
        SwitchListTile(
          title: const UiText('Pickup PIN'),
          subtitle: const UiText('Driver enters your PIN to start your ride.'),
          value: preferences['pin_enabled'] == true,
          onChanged: (v) => perform(
            context,
            () => store.act('preferences', {'pin_enabled': v}),
          ),
        ),
        SwitchListTile(
          title: const UiText('Simple mode'),
          subtitle: const UiText('Larger text and clear primary actions.'),
          value: preferences['simple_mode'] == true,
          onChanged: (v) => perform(
            context,
            () => store.act('preferences', {'simple_mode': v}),
          ),
        ),
        SwitchListTile(
          title: const UiText('Reduce motion'),
          value: preferences['reduced_motion'] == true,
          onChanged: (v) => perform(
            context,
            () => store.act('preferences', {'reduced_motion': v}),
          ),
        ),
        section('Places and profiles'),
        for (final p in records(store.data['saved_places']))
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: Text('${p['label']}'),
            subtitle: Text('${record(p['place'])['name']}'),
            onTap: () async {
              final place = await showModalBottomSheet<Record>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) =>
                    PlacePicker(store: store, title: 'Edit saved place'),
              );
              if (place != null && context.mounted) {
                await openPage(
                  context,
                  ActionForm(
                    title: 'Edit saved place',
                    fields: [
                      FieldSpec(
                        'label',
                        'Place label',
                        initial: '${p['label']}',
                      ),
                    ],
                    action: (b) => store.act('saved-place', {
                      'id': p['id'],
                      'place': place,
                      ...b,
                    }),
                  ),
                );
              }
            },
            trailing: IconButton(
              tooltip: tr(context, 'Delete saved place'),
              onPressed: () => perform(context, () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const UiText('Delete saved place?'),
                    content: Text('${p['label']}'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const UiText('Back'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const UiText('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await store.act('saved-place', {'delete_id': p['id']});
                }
              }),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        ListTile(
          leading: const Icon(Icons.add_location_alt_outlined),
          title: const UiText('Save a place'),
          onTap: () async {
            final place = await showModalBottomSheet<Record>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => PlacePicker(store: store, title: 'Save a place'),
            );
            if (place != null && context.mounted) {
              await openPage(
                context,
                ActionForm(
                  title: 'Place label',
                  fields: const [
                    FieldSpec('label', 'Label, such as Home or Work'),
                  ],
                  action: (b) =>
                      store.act('saved-place', {'place': place, ...b}),
                ),
              );
            }
          },
        ),
        for (final p in records(store.data['profiles']))
          info('${p['name']}', stage(p['kind'])),
        tile(
          'Add travel profile',
          Icons.business_center_outlined,
          ActionForm(
            title: 'Travel profile',
            description: 'Personal and business labels use your own cash payment. Corporate invoicing requires a separate approved billing workflow.',
            fields: const [
              FieldSpec('name', 'Profile name'),
              FieldSpec('kind', 'Type', options: ['personal', 'business']),
            ],
            action: (b) => store.act('travel-profile', b),
          ),
        ),
        section('Trusted contacts'),
        for (final p in records(store.data['contacts']))
          ListTile(
            title: Text('${p['name']}'),
            subtitle: Text('${p['phone']}'),
            trailing: IconButton(
              tooltip: tr(context, 'Remove contact'),
              icon: const Icon(Icons.delete_outline),
              onPressed: () => perform(
                context,
                () => store.act('contact', {'delete_id': p['id']}),
              ),
            ),
          ),
        tile(
          'Add consenting contact',
          Icons.contact_emergency_outlined,
          ActionForm(
            title: 'Trusted contact',
            description: 'Confirm the person agreed to have their details stored. Share your trip link with them yourself.',
            fields: const [
              FieldSpec('name', 'Name'),
              FieldSpec('phone', 'Phone'),
            ],
            submit: 'Confirm consent and save',
            action: (b) => store.act('contact', {'consent': true, ...b}),
          ),
        ),
        section('Money and requests'),
        tile(
          'Cash history',
          Icons.payments_outlined,
          DataPage(
            store: store,
            title: 'Your financial records',
            action: 'finance-history',
            keyName: 'entries',
            item: (c, e, r) => info(
              '${stage(e['kind'])} · ${stage(e['account_key'])}',
              '${money(e['amount_minor'])} · ${e['created_at']}',
            ),
          ),
        ),
        tile(
          'Requests and outcomes',
          Icons.fact_check_outlined,
          requestsPage(store),
        ),
        if (store.can('driver')) ...[
          tile(
            'Review settlement destination',
            Icons.account_balance_outlined,
            NewRequestPage(store: store, kind: 'payout_destination'),
          ),
          tile(
            'Request manual payout',
            Icons.outbox_outlined,
            NewRequestPage(store: store, kind: 'payout'),
          ),
          tile(
            'Request identity recheck',
            Icons.badge_outlined,
            NewRequestPage(store: store, kind: 'identity_recheck'),
          ),
        ],
        if (!store.can('driver') && !store.can('driver_application'))
          tile(
            'Become a driver',
            Icons.drive_eta,
            ActionForm(
              title: 'Driver enrollment',
              description: 'Documents, identity and vehicle review are required before you can receive offers.',
              fields: [
                FieldSpec(
                  'product_name',
                  'Vehicle type',
                  options: records(store.data['products'])
                      .map((p) => '${p['name']}')
                      .toList(),
                ),
                const FieldSpec('vehicle', 'Vehicle display name'),
                const FieldSpec('make', 'Vehicle make'),
                const FieldSpec('model', 'Vehicle model'),
                const FieldSpec('color', 'Vehicle color'),
                const FieldSpec('plate', 'Registration plate'),
                const FieldSpec('capacity', 'Passenger capacity'),
                const FieldSpec(
                  'helmets',
                  'Passenger helmet equipment',
                  options: ['false', 'true'],
                ),
                const FieldSpec(
                  'luggage',
                  'Luggage capability',
                  options: ['true', 'false'],
                ),
              ],
              action: (b) => store.act('driver-apply', {
                ...b,
                'product_id': records(store.data['products'])
                    .firstWhere((p) => p['name'] == b['product_name'])['id'],
                'equipment': {
                  'helmets': b['helmets'] == 'true',
                  'luggage': b['luggage'] == 'true',
                },
              }),
            ),
          ),
        section('Help and privacy'),
        tile(
          'Help topics',
          Icons.menu_book_outlined,
          DataPage(
            store: store,
            title: 'Help topics',
            action: 'catalog',
            keyName: 'content',
            item: (c, t, reload) => '${t['content_key']}'.startsWith('help.')
                ? ExpansionTile(
                    title: Text('${t['title']}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('${t['body']}'),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),
        if (store.can('customer'))
          tile(
            'Available promotions',
            Icons.local_offer_outlined,
            DataPage(
              store: store,
              title: 'Available promotions',
              action: 'catalog',
              keyName: 'promotions',
              item: (c, p, reload) => ListTile(
                title: Text('${p['code']} · ${money(p['discount_minor'])}'),
                subtitle: Text(
                  '${p['description']}\nExpires ${p['expires_at']} UTC',
                ),
                onTap: () => openPage(c, BookingPage(store: store)),
              ),
            ),
          ),
        if (store.can('driver_application'))
          tile(
            'Request identity review',
            Icons.badge_outlined,
            NewRequestPage(store: store, kind: 'identity_recheck'),
          ),
        tile('Safety', Icons.shield_outlined, SafetyPage(store: store)),
        tile('Your help cases', Icons.support_agent, casesPage(store)),
        tile(
          'Get help or appeal',
          Icons.help_outline,
          NewCasePage(store: store),
        ),
        tile(
          'Contact verification review',
          Icons.verified_user_outlined,
          NewRequestPage(store: store, kind: 'contact_verification'),
        ),
        tile(
          'Request my data',
          Icons.download_outlined,
          NewRequestPage(store: store, kind: 'data_export'),
        ),
        tile(
          'Request account deletion',
          Icons.person_remove_outlined,
          NewRequestPage(store: store, kind: 'account_deletion'),
        ),
        tile(
          'Service terms',
          Icons.article_outlined,
          DataPage(
            store: store,
            title: 'Terms and consent',
            action: 'terms',
            keyName: 'terms',
            item: (c, t, reload) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${t['title']} · ${t['version']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('${t['body']}'),
                    Text(
                      t['accepted_at'] == null
                          ? 'Acceptance pending'
                          : 'Accepted ${t['accepted_at']} UTC',
                    ),
                    TextButton(
                      onPressed: () => perform(c, () async {
                        await store.act('accept-terms', {'id': t['id']});
                        reload();
                      }),
                      child: const UiText('Accept this version'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => perform(context, store.logout),
          child: const UiText('Sign out'),
        ),
      ],
    );
  }
}

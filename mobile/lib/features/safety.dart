import '../ui/localized.dart';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/platform_store.dart';
import 'common.dart';
import 'support.dart';

class SafetyPage extends StatelessWidget {
  final PlatformStore store;
  final String? tripId;
  const SafetyPage({super.key, required this.store, this.tripId});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const UiText('Safety')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.shield_outlined, size: 56),
          section('Immediate danger'),
          Text('${store.emergency['label'] ?? 'Local emergency services'}'),
          SelectableText(
            '${store.emergency['number'] ?? 'Use your phone’s emergency dialer'}',
            style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
          ),
          const UiText(
            'This opens your device dialer. RideShare does not dispatch responders or automatically send your trip or location. Explain your location directly to the emergency operator.',
          ),
          if (store.emergency['number'] != null)
            FilledButton.icon(
              onPressed: () => perform(context, () async {
                if (!await launchUrl(
                  Uri(scheme: 'tel', path: '${store.emergency['number']}'),
                )) {
                  throw Exception(
                    'Open your phone dialer and use the number shown above.',
                  );
                }
              }),
              icon: const Icon(Icons.phone_outlined),
              label: Text('Open dialer · ${store.emergency['number']}'),
            ),
          if (tripId != null) info('Trip reference', tripId),
          section('Report a safety concern'),
          const UiText(
            'A restricted case is saved for review. Submit details when it is safe to do so.',
          ),
          FilledButton(
            onPressed: () => openPage(
              context,
              ActionForm(
                title: 'Safety report',
                fields: [
                  if (store.signedIn) FieldSpec('subject', 'Short description'),
                  if (!store.signedIn) FieldSpec('contact', 'Contact details'),
                  FieldSpec('message', 'Details', multiline: true),
                ],
                action: (b) async {
                  if (store.signedIn) {
                    return store.act('create-case', {
                      'category': 'safety',
                      'trip_id': tripId,
                      ...b,
                    });
                  }
                  final result = await store.api(
                    'recovery-intake',
                    body: {'kind': 'urgent', ...b},
                  );
                  if (context.mounted) {
                    await showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const UiText('Private report reference'),
                        content: SelectableText(
                          'Reference: ${result['reference']}\nPrivate access key: ${result['access_key']}\nKeep both to check the report status from sign-in.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c),
                            child: const UiText('Saved reference'),
                          ),
                        ],
                      ),
                    );
                  }
                  return result;
                },
              ),
            ),
            child: const UiText('Submit restricted safety report'),
          ),
          if (store.signedIn)
            TextButton(
              onPressed: () =>
                  openPage(context, NewCasePage(store: store, tripId: tripId)),
              child: const UiText('Routine trip help'),
            ),
          if (store.emergency['verified_on'] != null)
            info(
              'Emergency number verification',
              store.emergency['verified_on'],
            ),
        ],
      ),
    ),
  );
}

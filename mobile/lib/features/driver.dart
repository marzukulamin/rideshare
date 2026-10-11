import '../ui/localized.dart';
import 'image_crop.dart';

import 'dart:typed_data';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';

import '../data/platform_store.dart';
import 'common.dart';
import 'documents.dart';
import 'practice.dart';
import 'hazard.dart';
import 'trip.dart';
import 'history.dart';
import 'receipt.dart';

class DriverPage extends StatefulWidget {
  final PlatformStore store;
  const DriverPage({super.key, required this.store});
  @override
  State<DriverPage> createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> {
  int period = 0;
  Record? data;
  String? error;
  bool loading = false;
  @override
  void initState() {
    super.initState();
    widget.store.addListener(changed);
    load();
  }

  void changed() {
    load();
  }

  @override
  void dispose() {
    widget.store.removeListener(changed);
    super.dispose();
  }

  Future<void> load() async {
    if (loading) return;
    loading = true;
    try {
      final r = await widget.store.api(
        'driver-overview',
        query: {'period': period},
      );
      if (mounted) {
        setState(() {
          data = r;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      loading = false;
    }
  }

  Future<void> act(String action, Record b) async {
    await perform(context, () async {
      await widget.store.act(action, b);
      await load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = record(data?['profile']);
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          UiText('Driver', style: Theme.of(context).textTheme.headlineLarge),
          if (error != null) Text(error!),
          if (data == null)
            const LinearProgressIndicator()
          else ...[
            if (widget.store.can('driver') &&
                number(data!['work_limit_seconds']) > 0 &&
                number(d['desired_online']) == 1 &&
                number(data!['work_limit_seconds']) -
                        number(data!['work_seconds']) <=
                    number(data!['work_warning_seconds']))
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Work-time limit: ${(number(data!['work_limit_seconds']) - number(data!['work_seconds'])).clamp(0, 999999) ~/ 60} minutes remaining. New offers stop at the limit. Finish your current trip safely and go offline for the required rest.',
                  ),
                ),
              ),
            if (widget.store.can('driver'))
              SwitchListTile(
                title: Text(
                  number(d['desired_online']) == 1
                      ? (data!['receiving_offers'] == true
                            ? 'Available for offers'
                            : 'Online · checking location and reachability')
                      : 'Offline',
                ),
                subtitle: const UiText(
                  'Going offline preserves your current trip.',
                ),
                value: number(d['desired_online']) == 1,
                onChanged: widget.store.busy
                    ? null
                    : (v) => perform(context, () async {
                        final result = await widget.store.act(
                          'driver-availability',
                          {'online': v},
                        );
                        await load();
                        if (!v && context.mounted) {
                          final wrap = record(result['wrap_up']);
                          await showDialog<void>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const UiText('Session wrap-up'),
                              content: Text(
                                '${localTime(wrap['since'])} to ${localTime(wrap['ended_at'])}\n${(number(wrap['online_seconds']) / 3600).toStringAsFixed(2)} hours online\n${number(wrap['offers'])} offers · ${number(wrap['completed'])} completed\n${number(wrap['cancelled'])} cancelled · ${number(wrap['no_show'])} no-shows\nFare: ${money(wrap['fare_minor'])}\nRecorded earnings: ${money(wrap['earning_minor'])}\nCash received: ${money(wrap['cash_received_minor'])}\nTips received: ${money(wrap['tips_received_minor'])}\nPayout awaiting review/execution: ${money(wrap['payout_pending_minor'])}\nNet payable: ${money(wrap['net_payable_minor'])}\nYour existing trip stays available.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c),
                                  child: const UiText('Done'),
                                ),
                              ],
                            ),
                          );
                        }
                      }),
              ),
            if (widget.store.can('driver') || widget.store.can('active_driver'))
              SwitchListTile(
                title: const UiText('Share driver location'),
                subtitle: const UiText(
                  'Android shows a persistent notification while tracking. Turn this on after going online. Browser tracking works while the page is open.',
                ),
                value: widget.store.tracking,
                onChanged: (v) => perform(
                  context,
                  () => v
                      ? widget.store.startDriverTracking()
                      : widget.store.stopDriverTracking(),
                ),
              ),
            if (data!['ready'] != true)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const UiText('Readiness checks'),
                      for (final r in data!['reasons'] as List? ?? [])
                        Text('• $r'),
                    ],
                  ),
                ),
              ),
            info(
              'Selected vehicle',
              '${record(data!['vehicle'])['label'] ?? 'Choose a reviewed vehicle'}',
            ),
            info(
              'Work this session',
              '${(number(data!['work_seconds']) / 3600).toStringAsFixed(1)} hours',
            ),
            if (widget.store.can('driver') || widget.store.can('active_driver'))
              TextButton.icon(
                onPressed: () => perform(context, () async {
                  var p = await Geolocator.checkPermission();
                  if (p == LocationPermission.denied) {
                    p = await Geolocator.requestPermission();
                  }
                  if (p == LocationPermission.denied ||
                      p == LocationPermission.deniedForever) {
                    throw Exception(
                      'Allow location permission or stay offline.',
                    );
                  }
                  final location = await Geolocator.getCurrentPosition(
                    locationSettings: const LocationSettings(
                      timeLimit: Duration(seconds: 15),
                    ),
                  );
                  await widget.store.act('driver-heartbeat', {
                    'lat': location.latitude,
                    'lng': location.longitude,
                    'accuracy': location.accuracy,
                  });
                  await load();
                }),
                icon: const Icon(Icons.gps_fixed),
                label: const UiText('Update device location'),
              ),
            if (widget.store.active != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.route),
                  title: const UiText('Open current trip'),
                  subtitle: Text(stage(widget.store.active!['status'])),
                  onTap: () => openPage(
                    context,
                    TripPage(
                      store: widget.store,
                      id: widget.store.active!['id'],
                    ),
                  ).then((_) => load()),
                ),
              ),
            section('Ride offers'),
            if (records(data!['offers']).isEmpty)
              empty('No pending offers. Keep the app open while available.'),
            for (final o in records(data!['offers']))
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${record(jsonDecode(o['snapshot']))['customer_label']}',
                      ),
                      Text(
                        '${record(record(jsonDecode(o['snapshot']))['pickup'])['name']} → ${record(record(jsonDecode(o['snapshot']))['destination'])['name']}',
                      ),
                      Text(
                        '${money(o['fare_minor'])} · expires ${o['expires_at']} UTC',
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: widget.store.busy
                            ? null
                            : () async {
                                await perform(context, () async {
                                  final r = await widget.store.act('offer', {
                                    'id': o['id'],
                                    'decision': 'accept',
                                  });
                                  if (context.mounted) {
                                    await openPage(
                                      context,
                                      TripPage(
                                        store: widget.store,
                                        id: r['trip_id'],
                                      ),
                                    );
                                  }
                                  await load();
                                });
                              },
                        child: const UiText('Accept ride'),
                      ),
                      TextButton(
                        onPressed: () => act('offer', {
                          'id': o['id'],
                          'decision': 'decline',
                        }),
                        child: const UiText('Decline'),
                      ),
                    ],
                  ),
                ),
              ),
            section('Your work'),
            DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: period,
              decoration: InputDecoration(
                labelText: tr(context, 'Statistics period'),
              ),
              items: const [
                DropdownMenuItem(value: 0, child: UiText('Lifetime')),
                DropdownMenuItem(value: 7, child: UiText('Last 7 days')),
                DropdownMenuItem(value: 30, child: UiText('Last 30 days')),
              ],
              onChanged: (v) {
                setState(() => period = v ?? 0);
                load();
              },
            ),
            info(
              'Offers (separate from trips)',
              record(data!['stats'])['offers'],
            ),
            info('No-shows', record(data!['stats'])['no_show']),
            info(
              'Net payable after retained cash',
              money(data!['net_payable_minor']),
            ),
            if (record(widget.store.data['features'])['driver_practice'] !=
                false)
              ListTile(
                leading: const Icon(Icons.school_outlined),
                title: const UiText('Driver practice'),
                onTap: () => openPage(context, const DriverPracticePage()),
              ),
            ListTile(
              leading: const Icon(Icons.warning_amber_outlined),
              title: const UiText('Report road hazard when stopped'),
              onTap: () => openPage(context, HazardPage(store: widget.store)),
            ),

            if (record(data!['settlement'])['held'] == true ||
                record(data!['settlement'])['pending_destination_review'] ==
                    true)
              info(
                'Settlement review',
                '${record(data!['settlement'])['held'] == true ? record(data!['settlement'])['reason'] : 'Destination ownership review is pending. Open your requests to review or withdraw it.'}',
              ),
            info('Completed trips', record(data!['stats'])['completed']),
            info(
              'Recorded earnings',
              money(record(data!['stats'])['earning_minor']),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const UiText('Driver trip history'),
              onTap: () => openPage(
                context,
                Scaffold(
                  appBar: AppBar(title: const UiText('Driver history')),
                  body: SafeArea(
                    child: TripHistory(store: widget.store, scope: 'driver'),
                  ),
                ),
              ),
            ),
            section('Vehicles and documents'),
            TextButton(
              onPressed: () => openPage(
                context,
                ActionForm(
                  title: 'Add vehicle for review',
                  description: 'Your existing approved vehicle remains selected while the new vehicle and documents await review.',
                  fields: [
                    FieldSpec(
                      'product_name',
                      'Vehicle type',
                      options: records(widget.store.data['products'])
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
                  action: (b) => widget.store.act('driver-apply', {
                    ...b,
                    'product_id': records(
                      widget.store.data['products'],
                    ).firstWhere((p) => p['name'] == b['product_name'])['id'],
                    'equipment': {
                      'helmets': b['helmets'] == 'true',
                      'luggage': b['luggage'] == 'true',
                    },
                  }),
                ),
              ).then((_) => load()),
              child: const UiText('Add vehicle for review'),
            ),
            for (final v in records(data!['vehicles']))
              ListTile(
                title: Text('${v['label']} · ${v['plate']}'),
                subtitle: Text(stage(v['status'])),
                trailing: number(v['id']) == number(d['active_vehicle_id'])
                    ? const Icon(Icons.check_circle)
                    : null,
                onTap: widget.store.can('driver') && v['status'] == 'approved'
                    ? () => act('switch-vehicle', {'id': v['id']})
                    : null,
              ),
            TextButton(
              onPressed: () => openPage(
                context,
                ActionForm(
                  title: 'Upload document',
                  fields: [
                    const FieldSpec(
                      'kind',
                      'Document type',
                      options: [
                        'license',
                        'registration',
                        'insurance',
                        'identity',
                        'profile_photo',
                      ],
                    ),
                    FieldSpec(
                      'vehicle_id',
                      'Choose your vehicle (identity may use any listed vehicle)',
                      options: records(data!['vehicles'])
                          .map(
                            (v) => '${v['id']} · ${v['label']} · ${v['plate']}',
                          )
                          .toList(),
                      initial:
                          records(data!['vehicles'])
                              .where(
                                (v) =>
                                    number(v['id']) ==
                                    number(record(data!['vehicle'])['id']),
                              )
                              .map(
                                (v) =>
                                    '${v['id']} · ${v['label']} · ${v['plate']}',
                              )
                              .firstOrNull ??
                          '',
                      optional: true,
                    ),
                    const FieldSpec(
                      'expires_at',
                      'Expiry date YYYY-MM-DD',
                      optional: true,
                    ),
                  ],
                  description: 'Choose a JPEG, PNG or plain PDF up to 5 MB. Documents remain private and require staff review.',
                  submit: 'Choose file and submit',
                  action: (b) async {
                    final result = await FilePicker.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                    );
                    if (result.isEmpty) throw Exception('No file selected.');
                    final file = result.single;
                    if ((await file.length() ?? 5000001) > 5000000) {
                      throw Exception('Use a file up to 5 MB.');
                    }
                    var bytes = await file.readAsBytes();
                    if (!context.mounted) throw Exception('Upload closed.');
                    if (!file.name.toLowerCase().endsWith('.pdf')) {
                      final cropped = await openPage<Uint8List>(
                        context,
                        ImageCropPage(bytes: bytes),
                      );
                      if (cropped == null) {
                        throw Exception('No file submitted.');
                      }
                      bytes = cropped;
                    }
                    if (!context.mounted) throw Exception('Upload closed.');
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const UiText('Review private document'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(file.name),
                            if (!file.name.toLowerCase().endsWith('.pdf'))
                              Flexible(child: Image.memory(bytes)),
                            const UiText(
                              'Check all details are readable before submitting.',
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const UiText('Choose another file'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const UiText('Submit for review'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) {
                      throw Exception('No file submitted.');
                    }
                    await widget.store.act('document-upload', {
                      'kind': b['kind'],
                      'vehicle_id':
                          int.tryParse(
                            '${b['vehicle_id']}'.split(' · ').first,
                          ) ??
                          0,
                      'expires_at': b['expires_at'],
                      'data': base64Encode(bytes),
                    });
                  },
                ),
              ).then((_) => load()),
              child: const UiText('Upload private document'),
            ),
            for (final doc in records(data!['documents']))
              InkWell(
                onTap: () => openPage(
                  context,
                  DocumentPage(store: widget.store, id: number(doc['id'])),
                ),
                child: info(
                  '${stage(doc['kind'])} · ${stage(doc['status'])}',
                  '${doc['reason'] ?? 'Awaiting review'}\nExpiry: ${doc['expires_at'] ?? 'Not provided'}',
                ),
              ),
            TextButton.icon(
              onPressed: () => shareEarnings(context, data!),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const UiText('Download earnings statement'),
            ),
            section('Earnings ledger'),
            for (final e in records(data!['ledger']))
              info(
                '${stage(e['kind'])} · ${stage(e['account_key'])}',
                '${money(e['amount_minor'])} · ${e['created_at']}',
              ),
          ],
        ],
      ),
    );
  }
}

import 'dart:convert';

import '../ui/localized.dart';
import 'lost_item.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/platform_store.dart';
import '../ui/road_map.dart';
import 'common.dart';
import 'support.dart';
import 'route_change.dart';
import 'requests.dart';
import 'booking.dart';
import 'safety.dart';
import 'receipt.dart';
import 'navigation.dart';

const endedStages = {
  'completed',
  'cancelled',
  'no_driver',
  'interrupted',
  'no_show',
};

class TripPage extends StatefulWidget {
  final PlatformStore store;
  final String id;
  const TripPage({super.key, required this.store, required this.id});
  @override
  State<TripPage> createState() => _TripPageState();
}

class _TripPageState extends State<TripPage> with WidgetsBindingObserver {
  Record? trip;
  Future<Record>? profilePhoto;
  int? profilePhotoId;
  String? error;
  bool loading = false, foreground = true;
  Timer? timer;
  final pin = TextEditingController(), message = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    load();
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (foreground) load();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    foreground = s == AppLifecycleState.resumed;
    if (foreground) load();
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    pin.dispose();
    message.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (loading) return;
    loading = true;
    try {
      final r = await widget.store.api('trip', query: {'id': widget.id});
      if (mounted) {
        setState(() {
          trip = record(r['trip']);
          final driver = record(record(trip!['snapshot'])['driver']);
          final id = driver['photo_document_id'];
          final participant =
              trip!['customer_id'] == widget.store.user['id'] ||
              trip!['driver_id'] == widget.store.user['id'];
          if (participant && id != null && id != profilePhotoId) {
            profilePhotoId = number(id);
            profilePhoto = widget.store.api(
              'trip-photo',
              query: {'trip_id': widget.id},
            );
          }
          if (!participant || id == null) {
            profilePhoto = null;
            profilePhotoId = null;
          }
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e is ApiFailure && e.status == 403) trip = null;
          error = '$e';
        });
      }
    } finally {
      loading = false;
    }
  }

  Future<bool> act(String action, Record body) async {
    try {
      await widget.store.act(action, {
        'trip_id': widget.id,
        'version': trip!['version'],
        ...body,
      });
      await load();
      return true;
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e is ApiFailure && e.status == 403) trip = null;
          error = '$e';
        });
      }
      return false;
    }
  }

  Future<void> reason(
    String action,
    String title, {
    Record extra = const {},
  }) async {
    await openPage(
      context,
      ActionForm(
        title: title,
        fields: const [FieldSpec('reason', 'Reason', multiline: true)],
        action: (b) => widget.store.act(action, {
          'trip_id': widget.id,
          'version': trip!['version'],
          ...extra,
          ...b,
        }),
      ),
    );
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final t = trip, s = record(t?['snapshot']);
    final ownCustomer =
        t != null &&
        number(t['customer_id']) == number(widget.store.user['id']);
    final ownDriver =
        t != null &&
        number(t['driver_id']) == number(widget.store.user['id']) &&
        (widget.store.can('driver') || widget.store.can('active_driver'));
    final feedbackOpen =
        DateTime.tryParse('${t?['feedback_edit_until']}')
            ?.isAfter(DateTime.now()) ==
        true;
    final rating = record(t?['rating']);
    final ratingTags = (rating['tags'] as List?) ?? const [];
    final done = endedStages.contains(t?['status']);
    return Scaffold(
      appBar: AppBar(
        title: Text(done ? 'Trip details' : 'Your trip'),
        actions: [
          IconButton(
            onPressed: load,
            icon: const Icon(Icons.refresh),
            tooltip: tr(context, 'Refresh trip'),
          ),
        ],
      ),
      body: SafeArea(
        child: t == null
            ? Center(
                child: error == null
                    ? const CircularProgressIndicator()
                    : Text(error!),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (error != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(error!),
                      ),
                    ),
                  Text(
                    stage(t['status']),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Trip ${widget.id.substring(0, 8)} · ${stage(t['payment_status'])}',
                  ),
                  const SizedBox(height: 16),
                  RoadMap(
                    height: 230,
                    route: records(s['route']),
                    pins: [
                      record(s['pickup']),
                      ...records(s['stops']),
                      record(s['destination']),
                    ],
                    driver: done ? null : record(t['driver_location']),
                  ),
                  if (!ownCustomer && !ownDriver && widget.store.can('trips'))
                    TextButton(
                      onPressed: () => openPage(
                        context,
                        ActionForm(
                          title: 'Review sensitive trip location',
                          description: 'This reveals the permitted location for five minutes in this session. Access and its purpose are logged.',
                          fields: const [
                            FieldSpec(
                              'purpose',
                              'Case or operational purpose',
                              multiline: true,
                            ),
                          ],
                          action: (b) async {
                            await widget.store.act('trip-reveal', {
                              'trip_id': widget.id,
                              ...b,
                            }, refresh: false);
                            await load();
                          },
                        ),
                      ),
                      child: const UiText('Review sensitive trip location'),
                    ),
                  info('Pickup', record(s['pickup'])['name']),
                  for (final stop in records(s['stops']))
                    info('Stop', stop['name']),
                  info('Destination', record(s['destination'])['name']),
                  if (!done &&
                      ownCustomer &&
                      ['assigned', 'driver_arriving'].contains(t['status']))
                    info(
                      'Estimated pickup arrival',
                      t['pickup_eta_seconds'] == null
                          ? 'Unavailable · keep the app open for confirmed updates'
                          : '${(number(t['pickup_eta_seconds']) / 60).ceil()} minutes · road estimate, traffic may change it',
                    ),
                  if (!done && t['driver_id'] != null)
                    info(
                      'Driver connection',
                      t['driver_reachable'] == true
                          ? 'Recently acknowledged by server'
                          : 'No recent acknowledgement · messages may be delayed',
                    ),
                  if (!done && t['driver_location'] != null)
                    info(
                      t['location_fresh'] == true
                          ? 'Latest device location'
                          : 'Stale device location',
                      '${record(t['driver_location'])['lat']}, ${record(t['driver_location'])['lng']}\nAccuracy ${record(t['driver_location'])['accuracy']} m · ${record(t['driver_location'])['observed_at']}',
                    ),
                  if (t['status'] == 'matching')
                    info(
                      'Matching started',
                      '${t['created_at']} UTC · no driver has accepted yet',
                    ),
                  if (t['status'] == 'arrived')
                    info(
                      'Pickup waiting',
                      'Arrived ${t['arrived_at']} UTC · five-minute no-show threshold · no waiting fee',
                    ),
                  if (ownCustomer &&
                      !done &&
                      {
                        'assigned',
                        'driver_arriving',
                        'arrived',
                        'in_progress',
                      }.contains(t['status']))
                    TextButton.icon(
                      onPressed: () => openPage(
                        context,
                        RouteChangePage(store: widget.store, trip: t),
                      ).then((_) => load()),
                      icon: const Icon(Icons.edit_location_alt_outlined),
                      label: const UiText('Change destination or stops'),
                    ),
                  if (t['pending_change'] != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const UiText('Requested route change'),
                            Text(
                              'New destination: ${record(record(record(t['pending_change'])['snapshot'])['destination'])['name']}',
                            ),
                            Text(
                              'New price: ${money(record(t['pending_change'])['fare_minor'])}',
                            ),
                            if (ownDriver) ...[
                              FilledButton(
                                onPressed: () => act('trip-change-decision', {
                                  'id': record(t['pending_change'])['id'],
                                  'decision': 'accept',
                                }),
                                child: const UiText('Accept route change'),
                              ),
                              TextButton(
                                onPressed: () => act('trip-change-decision', {
                                  'id': record(t['pending_change'])['id'],
                                  'decision': 'decline',
                                }),
                                child: const UiText('Keep original route'),
                              ),
                            ] else
                              const UiText('Awaiting driver acceptance'),
                          ],
                        ),
                      ),
                    ),
                  info(
                    '${record(s['product'])['name']} · cash',
                    money(t['fare_minor']),
                  ),
                  info('Last confirmed update', localTime(t['as_of'])),
                  if (t['status'] == 'arrived')
                    info(
                      'Confirmed waiting time',
                      '${number(t['waiting_seconds']) ~/ 60} minutes · no waiting fee',
                    ),
                  if (s['driver'] != null)
                    Card(
                      child: ListTile(
                        leading: profilePhoto == null
                            ? const Icon(Icons.directions_car)
                            : FutureBuilder<Record>(
                                future: profilePhoto,
                                builder: (c, p) => p.hasData
                                    ? CircleAvatar(
                                        backgroundImage: MemoryImage(
                                          base64Decode('${p.data!['data']}'),
                                        ),
                                      )
                                    : const Icon(Icons.person_outline),
                              ),
                        title: Text('${record(s['driver'])['name']}'),
                        subtitle: Text(
                          '${record(s['driver'])['vehicle']} · ${record(s['driver'])['plate']}${record(s['driver'])['color'] == null || record(s['driver'])['color'] == '' ? '' : ' · ${record(s['driver'])['color']}'}',
                        ),
                      ),
                    ),
                  if (ownCustomer && t['pin'] != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const UiText('Tell your driver this pickup PIN'),
                            Text(
                              '${t['pin']}',
                              style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                              ),
                            ),
                            const UiText(
                              'Your driver starts the ride after checking the PIN.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!done && ownCustomer)
                    UiText(
                      'The driver controls arrival, start and completion. You’ll see each confirmed update here.',
                    ),
                  if (ownDriver && !done) ...[
                    TextButton.icon(
                      onPressed: () => openPage(
                        context,
                        NavigationPage(store: widget.store, tripId: widget.id),
                      ),
                      icon: const Icon(Icons.navigation_outlined),
                      label: Text(
                        t['status'] == 'in_progress'
                            ? 'Directions for remaining route'
                            : 'Directions to pickup',
                      ),
                    ),
                    if (t['status'] == 'in_progress' &&
                        number(t['completed_stops']) <
                            records(s['stops']).length)
                      FilledButton(
                        onPressed: () => act('driver-stop', {
                          'index': number(t['completed_stops']),
                        }),
                        child: Text(
                          'Confirm stop · ${records(s['stops'])[number(t['completed_stops'])]['name']}',
                        ),
                      ),

                    if (t['status'] == 'assigned')
                      FilledButton(
                        onPressed: widget.store.busy
                            ? null
                            : () => act('driver-trip', {'next': 'head'}),
                        child: const UiText('Head to pickup'),
                      ),
                    if (t['status'] == 'driver_arriving')
                      FilledButton(
                        onPressed: widget.store.busy
                            ? null
                            : () => act('driver-trip', {'next': 'arrive'}),
                        child: const UiText('Confirm arrival'),
                      ),
                    if (t['status'] == 'arrived' &&
                        widget.store.can('driver')) ...[
                      if (number(t['pin_required']) == 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: TextField(
                            controller: pin,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            decoration: InputDecoration(
                              labelText: tr(
                                context,
                                'Ask customer for pickup PIN',
                              ),
                            ),
                          ),
                        ),
                      FilledButton(
                        onPressed: widget.store.busy
                            ? null
                            : () => act('driver-trip', {
                                'next': 'start',
                                'pin': pin.text,
                              }),
                        child: const UiText('Start ride'),
                      ),
                      TextButton(
                        onPressed: () => openPage(
                          context,
                          ActionForm(
                            title: 'Customer did not arrive',
                            description: 'Available after five minutes at pickup. Record your actual contact attempts. No fee is charged under the current rules.',
                            fields: const [
                              FieldSpec(
                                'contact_attempt',
                                'Contact attempts',
                                multiline: true,
                              ),
                            ],
                            action: (b) => widget.store.act('no-show', {
                              'trip_id': widget.id,
                              'version': t['version'],
                              ...b,
                            }),
                          ),
                        ).then((_) => load()),
                        child: const UiText('Record no-show'),
                      ),
                    ],
                    if (t['status'] == 'in_progress') ...[
                      FilledButton(
                        onPressed: widget.store.busy
                            ? null
                            : () => act('driver-trip', {'next': 'complete'}),
                        child: const UiText('Complete ride'),
                      ),
                      TextButton(
                        onPressed: () => reason(
                          'interrupt-trip',
                          'Vehicle issue or interrupted ride',
                        ),
                        child: const UiText(
                          'Interrupt ride and request assistance',
                        ),
                      ),
                    ],
                    if ({
                      'assigned',
                      'driver_arriving',
                      'arrived',
                    }.contains(t['status']))
                      TextButton(
                        onPressed: () =>
                            reason('driver-cancel', 'Cancel pickup'),
                        child: const UiText('Cancel this pickup'),
                      ),
                  ],
                  if (ownCustomer && !done && t['status'] != 'in_progress')
                    TextButton(
                      onPressed: () => reason('cancel-trip', 'Cancel ride'),
                      child: const UiText('Cancel ride · no fee'),
                    ),
                  if (done) ...[
                    if (t['driver_id'] != null && (ownCustomer || ownDriver))
                      TextButton(
                        onPressed: () => openPage(
                          context,
                          LostItemPage(store: widget.store, trip: t),
                        ),
                        child: const UiText('Lost-item coordination'),
                      ),
                    section('Receipt'),
                    info('Trip date', localTime(t['created_at'])),
                    if (ownCustomer || ownDriver)
                      TextButton.icon(
                        onPressed: () => shareReceipt(context, t),
                        icon: const Icon(Icons.receipt_long),
                        label: const UiText(
                          'Download or share printable receipt',
                        ),
                      ),
                    for (final e in records(t['adjustments']))
                      info(
                        '${stage(e['kind'])} · executed',
                        money(e['amount_minor']),
                      ),
                    for (final item in records(t['fare_items']))
                      info('${item['label']}', money(item['amount_minor'])),
                    info('Accepted total', money(s['fare_minor'])),
                    info(
                      'Final fare',
                      t['payment_status'] == 'under_review'
                          ? 'Pending independent fare review'
                          : money(
                              ['completed', 'interrupted'].contains(t['status'])
                                  ? t['fare_minor']
                                  : 0,
                            ),
                    ),
                    info('Payment', stage(t['payment_status'])),
                    if (['completed', 'interrupted'].contains(t['status']) &&
                        t['payment_status'] != 'under_review' &&
                        t['payment_status'] != 'collection_reported' &&
                        t['payment_status'] != 'disputed')
                      info(
                        'Verified remaining fare',
                        money(t['remaining_fare_minor']),
                      ),
                    if (t['tip_minor'] != null)
                      info(
                        'Cash tip · ${stage(t['tip_status'])}',
                        money(t['tip_minor']),
                      ),
                    info(
                      'Distance and accepted rate',
                      '${(number(s['distance_m']) / 1000).toStringAsFixed(2)} km × ${money(s['rate_minor'])}/km',
                    ),
                    if (t['started_at'] != null && t['ended_at'] != null)
                      info(
                        'Duration',
                        '${DateTime.parse('${t['ended_at']}Z').difference(DateTime.parse('${t['started_at']}Z')).inMinutes} minutes',
                      ),
                    if (ownCustomer) ...[
                      TextButton.icon(
                        onPressed: () => openPage(
                          context,
                          BookingPage(
                            store: widget.store,
                            destination: record(s['destination']),
                            pickup: record(s['pickup']),
                            stops: records(s['stops']),
                            product: records(widget.store.data['products'])
                                .where(
                                  (p) =>
                                      number(p['id']) ==
                                      number(record(s['product'])['id']),
                                )
                                .firstOrNull,
                          ),
                        ),
                        icon: const Icon(Icons.replay),
                        label: const UiText('Book this route again'),
                      ),
                      TextButton(
                        onPressed: () => openPage(
                          context,
                          NewRequestPage(
                            store: widget.store,
                            kind:
                                [
                                  'uncollected',
                                  'partially_collected',
                                ].contains(t['payment_status'])
                                ? 'fare_adjustment'
                                : 'refund',
                            initial: {'trip_id': widget.id},
                          ),
                        ),
                        child: const UiText('Request fare or refund review'),
                      ),
                    ],
                    if (ownDriver &&
                        t['status'] == 'completed' &&
                        t['payment_status'] == 'uncollected')
                      FilledButton(
                        onPressed: () => openPage(
                          context,
                          ActionForm(
                            title: 'Record cash received',
                            description:
                                'Record cash only after receiving ${money(t['fare_minor'])}. This creates a collection record for customer confirmation.',
                            fields: const [
                              FieldSpec(
                                'evidence',
                                'Collection evidence or note',
                              ),
                            ],
                            submit: 'Record cash received',
                            action: (b) => widget.store.act('collect-cash', {
                              'trip_id': widget.id,
                              'amount_minor': number(t['fare_minor']),
                              ...b,
                            }),
                          ),
                        ).then((_) => load()),
                        child: const UiText('Record cash received'),
                      ),
                    if (ownCustomer &&
                        t['payment_status'] == 'collection_reported')
                      FilledButton(
                        onPressed: () => act('confirm-cash', {}),
                        child: Text(
                          'Confirm cash paid · ${money(t['fare_minor'])}',
                        ),
                      ),
                    if ((ownCustomer || ownDriver) &&
                        t['status'] == 'completed') ...[
                      ListTile(
                        leading: const Icon(Icons.star_outline),
                        title: Text(
                          t['rating'] == null
                              ? 'Rate this trip'
                              : 'Your rating: ${record(t['rating'])['rating']}',
                        ),
                        subtitle: Text(
                          feedbackOpen
                              ? 'Feedback can be edited until ${localTime(t['feedback_edit_until'])}'
                              : 'Feedback window ended · Trip Help remains available',
                        ),
                        onTap: !feedbackOpen
                            ? null
                            : () => openPage(
                                context,
                                ActionForm(
                                  title: 'Rate your trip',
                                  fields: [
                                    for (
                                      var tagIndex = 0;
                                      tagIndex < 3;
                                      tagIndex++
                                    )
                                      FieldSpec(
                                        'tag$tagIndex',
                                        'Feedback tag ${tagIndex + 1} (optional)',
                                        initial: ratingTags.length > tagIndex
                                            ? '${ratingTags[tagIndex]}'
                                            : 'none',
                                        options: [
                                          'none',
                                          ...((t['feedback_tags'] as List?) ??
                                                  [])
                                              .map((v) => '$v'),
                                        ],
                                      ),
                                    FieldSpec(
                                      'rating',
                                      'Stars',
                                      initial: '${rating['rating'] ?? 5}',
                                      options: ['5', '4', '3', '2', '1'],
                                    ),
                                    FieldSpec(
                                      'feedback',
                                      'Feedback',
                                      initial: '${rating['feedback'] ?? ''}',
                                      multiline: true,
                                      optional: true,
                                    ),
                                  ],
                                  action: (b) => widget.store.act('rate-trip', {
                                    'trip_id': widget.id,
                                    'version': number(
                                      record(t['rating'])['version'],
                                    ),
                                    'tags': [
                                      for (var i = 0; i < 3; i++)
                                        if (b['tag$i'] != 'none') b['tag$i'],
                                    ],
                                    ...b,
                                  }),
                                ),
                              ).then((_) => load()),
                      ),
                      if (ownCustomer && t['tip_status'] != 'received')
                        ListTile(
                          leading: const Icon(Icons.favorite_outline),
                          title: UiText(
                            t['tip_minor'] == null
                                ? 'Declare a cash tip'
                                : 'Edit pending cash tip',
                          ),
                          onTap: () => openPage(
                            context,
                            ActionForm(
                              title: 'Cash tip',
                              description: 'Give the driver cash separately. The declaration remains pending until receipt is confirmed. To cancel an existing pending declaration, enter zero. Received tips require a Help review.',
                              fields: [
                                FieldSpec(
                                  'amount',
                                  'Tip in BDT',
                                  initial: t['tip_minor'] == null
                                      ? ''
                                      : (number(t['tip_minor']) / 100)
                                            .toStringAsFixed(2),
                                ),
                              ],
                              action: (b) => widget.store.act(
                                t['tip_minor'] == null ? 'tip' : 'tip-change',
                                {
                                  'trip_id': widget.id,
                                  'expected_amount_minor': number(
                                    t['tip_minor'],
                                  ),
                                  'amount_minor': bdtMinor('${b['amount']}'),
                                },
                              ),
                            ),
                          ).then((_) => load()),
                        ),
                      if (ownDriver && t['tip_status'] == 'declared_pending')
                        TextButton(
                          onPressed: () => openPage(
                            context,
                            ActionForm(
                              title: 'Confirm cash tip',
                              description:
                                  'Confirm only after receiving ${money(t['tip_minor'])} in cash, separately from the trip fare.',
                              fields: const [
                                FieldSpec('evidence', 'Tip receipt note'),
                              ],
                              action: (b) => widget.store.act('confirm-tip', {
                                'trip_id': widget.id,
                                'expected_amount_minor': number(t['tip_minor']),
                                ...b,
                              }),
                            ),
                          ),
                          child: Text(
                            'Confirm cash tip · ${money(t['tip_minor'])}',
                          ),
                        ),
                    ],
                  ],
                  if (!done && (ownCustomer || ownDriver)) ...[
                    section('Trip conversation'),
                    for (final m in records(t['messages']))
                      ListTile(
                        title: Text('${m['body']}'),
                        subtitle: Text('${m['sender']} · ${m['created_at']}'),
                      ),
                    if (!done && (ownCustomer || ownDriver))
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final text in [
                            "I'm at the pickup",
                            'Please confirm the meeting point',
                            'I need more time',
                          ])
                            ActionChip(
                              label: UiText(text),
                              onPressed: () => message.text = text,
                            ),
                        ],
                      ),
                    TextField(
                      controller: message,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: tr(context, 'Message your trip partner'),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: widget.store.busy
                          ? null
                          : () async {
                              if (await act('trip-message', {
                                'message': message.text,
                              })) {
                                message.clear();
                              }
                            },
                      icon: const Icon(Icons.send),
                      label: const UiText('Send message'),
                    ),
                    TextButton.icon(
                      onPressed: () => perform(context, () async {
                        final r = await widget.store.act('share-trip', {
                          'trip_id': widget.id,
                        });
                        final url = widget.store.base
                            .resolve(r['path'])
                            .toString();
                        await Clipboard.setData(ClipboardData(text: url));
                        if (context.mounted) {
                          await showDialog(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const UiText('Trip link copied'),
                              content: SelectableText(
                                '$url\n\nExpires in two hours. Anyone with the link can view the limited trip status.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c),
                                  child: const UiText('Close'),
                                ),
                              ],
                            ),
                          );
                        }
                      }),
                      icon: const Icon(Icons.share),
                      label: const UiText('Share trip status'),
                    ),
                    TextButton(
                      onPressed: () => act('revoke-share', {}),
                      child: const UiText('Revoke my share links'),
                    ),
                  ],
                  if (ownCustomer || ownDriver)
                    ListTile(
                      leading: const Icon(Icons.shield_outlined),
                      title: const UiText('Safety and emergency dialer'),
                      onTap: () => openPage(
                        context,
                        SafetyPage(store: widget.store, tripId: widget.id),
                      ),
                    ),
                  if (ownCustomer || ownDriver)
                    ListTile(
                      leading: const Icon(Icons.support_agent),
                      title: const UiText('Trip help and safety'),
                      subtitle: const UiText(
                        'Fare, cash disputes, lost items or urgent concerns',
                      ),
                      onTap: () => openPage(
                        context,
                        NewCasePage(store: widget.store, tripId: widget.id),
                      ),
                    ),
                  section('Confirmed timeline'),
                  if (!ownCustomer && widget.store.can('finance') && done)
                    TextButton(
                      onPressed: () => openPage(
                        context,
                        NewRequestPage(
                          store: widget.store,
                          kind: 'refund',
                          initial: {'trip_id': widget.id},
                        ),
                      ),
                      child: const UiText(
                        'Propose a reviewed financial adjustment',
                      ),
                    ),
                  for (final e in records(t['events']))
                    ListTile(
                      title: Text(stage(e['event_key'])),
                      subtitle: Text('${e['created_at']} UTC'),
                    ),
                ],
              ),
      ),
    );
  }
}

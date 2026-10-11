import '../ui/localized.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../data/platform_store.dart';
import '../ui/theme.dart';
import 'account.dart';
import 'booking.dart';
import 'common.dart';
import 'driver.dart';
import 'staff.dart';
import 'trip.dart';
import 'inbox.dart';
import 'history.dart';

class AppShell extends StatefulWidget {
  final PlatformStore store;
  const AppShell({super.key, required this.store});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int tab = 0;
  String? role;
  Timer? timer;
  bool foreground = true, polling = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 8), (_) => poll());
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    foreground = s == AppLifecycleState.resumed;
    if (foreground) poll();
  }

  Future<void> poll() async {
    if (!foreground || polling || widget.store.busy || !widget.store.signedIn) {
      return;
    }
    polling = true;
    try {
      if (role == 'driver' && widget.store.can('driver')) {
        await widget.store.api('driver-heartbeat', body: {});
      }
      await widget.store.refresh();
    } catch (e) {
      if (mounted) setState(() => widget.store.error = '$e');
    } finally {
      polling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final modes = [
      if (store.can('customer')) 'customer',
      if (store.can('driver') ||
          store.can('active_driver') ||
          store.can('driver_application'))
        'driver',
      if (store.staff) 'staff',
    ];
    if (!modes.contains(role)) {
      role = modes.firstOrNull ?? 'account';
      tab = number(record(store.user['preferences'])['last_${role}_tab']);
    }
    final customer = role == 'customer';
    final labels = customer
        ? ['Home', 'Services', 'Activity', 'Account']
        : role == 'driver'
        ? ['Drive', 'Account']
        : ['Workspace', 'Account'];
    if (tab >= labels.length) tab = 0;
    Widget page;
    if (customer) {
      page = switch (tab) {
        0 => home(context),
        1 => services(context),
        2 => activity(context),
        _ => AccountPage(store: store),
      };
    } else {
      page = tab == labels.length - 1
          ? AccountPage(store: store)
          : role == 'driver'
          ? DriverPage(store: store)
          : StaffPage(store: store);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('RideShare · ${stage(role)}'),
        actions: [
          if (modes.length > 1)
            PopupMenuButton<String>(
              tooltip: tr(context, 'Your granted experiences'),
              initialValue: role,
              onSelected: (v) => setState(() {
                role = v;
                tab = 0;
              }),
              itemBuilder: (_) => modes
                  .map((m) => PopupMenuItem(value: m, child: Text(stage(m))))
                  .toList(),
            ),
          IconButton(
            onPressed: () => openPage(context, InboxPage(store: store)),
            icon: Badge(
              isLabelVisible: number(store.data['unread']) > 0,
              label: Text('${store.data['unread']}'),
              child: const Icon(Icons.notifications_outlined),
            ),
            tooltip: tr(context, 'Inbox'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                if (store.error != null)
                  MaterialBanner(
                    content: Text(store.error!),
                    actions: [
                      TextButton(
                        onPressed: () => perform(context, store.refresh),
                        child: const UiText('Refresh'),
                      ),
                    ],
                  ),
                Expanded(child: page),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) {
          setState(() => tab = i);
          store.act('preferences', {'last_${role}_tab': i}).catchError((
            Object e,
          ) {
            store.error = '$e';
            return <String, dynamic>{};
          });
        },
        destinations: [
          for (var i = 0; i < labels.length; i++)
            NavigationDestination(
              icon: Icon(
                customer
                    ? [
                        Icons.home_outlined,
                        Icons.grid_view,
                        Icons.history,
                        Icons.person_outline,
                      ][i]
                    : i == 0
                    ? Icons.dashboard_outlined
                    : Icons.person_outline,
              ),
              label: tr(context, labels[i]),
            ),
        ],
      ),
    );
  }

  Widget home(BuildContext context) {
    final store = widget.store;
    return RefreshIndicator(
      onRefresh: store.refresh,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          UiText(
            'Let’s get you there',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => openPage(context, BookingPage(store: store)),
            icon: const Icon(Icons.search),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: UiText('Where to?', style: TextStyle(fontSize: 23)),
            ),
          ),
          if (store.active != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.route),
                title: const UiText('Your current trip'),
                subtitle: Text(stage(store.active!['status'])),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openPage(
                  context,
                  TripPage(store: store, id: store.active!['id']),
                ),
              ),
            ),
          section('Ride your way'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final p in records(store.data['products']))
                SizedBox(
                  width: 150,
                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => openPage(
                        context,
                        BookingPage(store: store, product: p),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(productIcon('${p['name']}'), size: 40),
                            const SizedBox(height: 14),
                            Text(
                              '${p['name']}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('Up to ${p['capacity']}'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (records(store.data['recent_places']).isNotEmpty) ...[
            section('Recent pickup'),
            for (final p in records(store.data['recent_places']).take(1))
              ListTile(
                leading: const Icon(Icons.my_location),
                title: Text('${p['name']}'),
                subtitle: const UiText(
                  'From your recent trip · confirm before requesting',
                ),
                onTap: () =>
                    openPage(context, BookingPage(store: store, pickup: p)),
              ),
          ],
          for (final card in records(store.data['content']).where(
            (c) =>
                record(store.data['features'])['discovery_cards'] != false &&
                '${c['content_key']}'.startsWith('discovery.'),
          ))
            Card(
              child: ListTile(
                leading: const Icon(Icons.explore_outlined),
                title: Text('${card['title']}'),
                subtitle: Text('${card['body']}'),
                onTap: card['destination'] == null
                    ? null
                    : () => openPage(
                        context,
                        BookingPage(
                          store: store,
                          destination: record(card['destination']),
                        ),
                      ),
              ),
            ),
          section('Places to go'),
          for (final p in records(store.data['saved_places']))
            ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: Text('${p['label']}'),
              subtitle: Text('${record(p['place'])['name']}'),
              onTap: () => openPage(
                context,
                BookingPage(store: store, destination: record(p['place'])),
              ),
            ),
          for (final p in records(store.data['places']).take(5))
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text('${p['name']}'),
              subtitle: Text('${p['address']}'),
              onTap: () =>
                  openPage(context, BookingPage(store: store, destination: p)),
            ),
        ],
      ),
    );
  }

  Widget services(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      UiText('Services', style: Theme.of(context).textTheme.headlineLarge),
      for (final p in records(widget.store.data['products']))
        Card(
          child: ListTile(
            leading: Icon(productIcon('${p['name']}'), size: 36),
            title: Text('${p['name']}'),
            subtitle: Text('${p['description']}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                openPage(context, BookingPage(store: widget.store, product: p)),
          ),
        ),
    ],
  );
  Widget activity(BuildContext context) => TripHistory(store: widget.store);
}

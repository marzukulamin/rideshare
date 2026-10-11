import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';

import 'data/platform_store.dart';
import 'features/auth.dart';
import 'features/shell.dart';
import 'ui/theme.dart';

void main() => runApp(RideShareApp());

class RideShareApp extends StatefulWidget {
  final PlatformStore? store;
  const RideShareApp({super.key, this.store});
  @override
  State<RideShareApp> createState() => _RideShareAppState();
}

class _RideShareAppState extends State<RideShareApp> {
  late final PlatformStore store;
  @override
  void initState() {
    super.initState();
    store = widget.store ?? PlatformStore();
    if (widget.store == null) store.initialize();
  }

  @override
  void dispose() {
    if (widget.store == null) store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => MaterialApp(
      key: ValueKey(
        '${store.user['id']}:${store.signedIn}:${store.user['roles']}:${store.user['status']}',
      ),
      locale: '${store.user['locale']}'.startsWith('bn')
          ? const Locale('bn', 'BD')
          : const Locale('en', 'BD'),
      supportedLocales: const [Locale('en', 'BD'), Locale('bn', 'BD')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      title: 'RideShare',
      debugShowCheckedModeBanner: false,
      theme: RideTheme.light,
      darkTheme: RideTheme.dark,
      themeMode: switch (record(store.user['preferences'])['theme']) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      },
      builder: (context, child) {
        final prefs = record(store.user['preferences']);
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler:
                prefs['simple_mode'] == true && media.textScaler.scale(1) < 1.25
                ? const TextScaler.linear(1.25)
                : media.textScaler,
            disableAnimations:
                prefs['reduced_motion'] == true || media.disableAnimations,
          ),
          child: child!,
        );
      },
      home: store.loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : store.signedIn
          ? AppShell(store: store)
          : LoginPage(store: store),
    ),
  );
}

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';

import 'data/platform_store.dart';
import 'features/auth.dart';
import 'features/shell.dart';
import 'features/offline_demo.dart';
import 'ui/theme.dart';

void main() => runApp(RideShareApp());

class RideShareApp extends StatefulWidget {
  final PlatformStore? store;
  final bool? startAtWelcome;
  const RideShareApp({super.key, this.store, this.startAtWelcome});
  @override
  State<RideShareApp> createState() => _RideShareAppState();
}

class _RideShareAppState extends State<RideShareApp> {
  late final PlatformStore store;
  late String mode;
  @override
  void initState() {
    super.initState();
    store = widget.store ?? PlatformStore();
    mode = (widget.startAtWelcome ?? widget.store == null)
        ? 'welcome'
        : 'connected';
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
        mode == 'connected'
            ? '${store.user['id']}:${store.signedIn}:${store.user['roles']}:${store.user['status']}'
            : mode,
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
      home: mode == 'welcome'
          ? DemoWelcomePage(
              onDemo: () => setState(() => mode = 'demo'),
              onSignIn: () {
                setState(() => mode = 'connected');
                store.initialize();
              },
            )
          : mode == 'demo'
          ? OfflineDemoPage(onExit: () => setState(() => mode = 'welcome'))
          : store.loading
          ? Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => mode = 'demo'),
                      child: const Text('Try Demo instead'),
                    ),
                  ],
                ),
              ),
            )
          : store.signedIn
          ? AppShell(store: store)
          : LoginPage(
              store: store,
              onTryDemo: () => setState(() => mode = 'demo'),
            ),
    ),
  );
}

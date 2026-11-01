import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'i18n/i18n.dart';
import 'router.dart';
import 'services/auth_service.dart';
import 'theme.dart';

class JublaApp extends StatefulWidget {
  const JublaApp({super.key, this.initialLocation});

  final String? initialLocation;

  @override
  State<JublaApp> createState() => _JublaAppState();
}

class _JublaAppState extends State<JublaApp> {
  late final GoRouter _router = createRouter(
    context.read<AuthService>(),
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.watch<I18n>();
    return MaterialApp.router(
      title: 'JUBL(A)PP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: i18n.locale,
      supportedLocales: [for (final code in I18n.supported) Locale(code)],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
    );
  }
}

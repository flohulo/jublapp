import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'screens/ereignis_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/gruppenstunde_screen.dart';
import 'screens/lager_screen.dart';
import 'screens/links_screen.dart';
import 'screens/login_screen.dart';
import 'screens/overview_screen.dart';
import 'screens/strike_screen.dart';
import 'screens/success_screen.dart';
import 'screens/weather_screen.dart';
import 'services/auth_service.dart';

/// Routen der App. Entsprechen den Seiten der früheren PWA.
class Routes {
  Routes._();

  static const login = '/';
  static const overview = '/uebersicht';
  static const groupHour = '/gruppenstunde';
  static const strike = '/strike';
  static const ereignis = '/ereignis';
  static const weather = '/wetter';
  static const success = '/erfolg';
  static const links = '/links';
  static const lager = '/lager';
  static const feedback = '/feedback';

  static const all = [
    login,
    overview,
    groupHour,
    strike,
    ereignis,
    weather,
    success,
    links,
    lager,
    feedback,
  ];

  /// Alte PWA-Adressen (`/pages/ereignis`, `/pages/links.html`,
  /// `/index.html`, `/erfolg.html` …) auf die neuen Routen abbilden, damit
  /// Lesezeichen, installierte PWAs und Handbuch-Links weiter funktionieren.
  static String normalize(String path) {
    var p = path;
    if (p.startsWith('/pages/')) p = p.substring('/pages'.length);
    if (p.endsWith('.html')) p = p.substring(0, p.length - '.html'.length);
    if (p == '/index' || p.isEmpty) p = login;
    if (p.length > 1 && p.endsWith('/')) p = p.substring(0, p.length - 1);
    return all.contains(p) ? p : login;
  }
}

GoRouter createRouter(AuthService auth, {String? initialLocation}) {
  // Per push() geöffnete Seiten erscheinen auch in der Browser-Adresse
  // (Deep-Links, Zurück-Taste, Reload).
  GoRouter.optionURLReflectsImperativeAPIs = true;
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: auth,
    redirect: (context, state) {
      final path = state.uri.path;
      final normalized = Routes.normalize(path);
      if (normalized != path) return normalized;
      if (path == Routes.login) return auth.loggedIn ? Routes.overview : null;
      if (!auth.loggedIn) return Routes.login;
      return null;
    },
    errorBuilder: (context, state) => const SizedBox.shrink(),
    routes: [
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.overview, builder: (_, _) => const OverviewScreen()),
      GoRoute(
        path: Routes.groupHour,
        builder: (_, _) => const GruppenstundeScreen(),
      ),
      GoRoute(path: Routes.strike, builder: (_, _) => const StrikeScreen()),
      GoRoute(path: Routes.ereignis, builder: (_, _) => const EreignisScreen()),
      GoRoute(path: Routes.weather, builder: (_, _) => const WeatherScreen()),
      GoRoute(path: Routes.success, builder: (_, _) => const SuccessScreen()),
      GoRoute(path: Routes.links, builder: (_, _) => const LinksScreen()),
      GoRoute(path: Routes.lager, builder: (_, _) => const LagerScreen()),
      GoRoute(path: Routes.feedback, builder: (_, _) => const FeedbackScreen()),
    ],
  );
}

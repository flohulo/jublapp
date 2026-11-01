import 'package:flutter/foundation.dart';

import 'version.dart';

/// Zentrale Konfiguration. Alle Werte lassen sich beim Build per
/// `--dart-define=NAME=wert` überschreiben.
class AppConfig {
  AppConfig._();

  static const String version = appVersion;

  /// Produktiv-Deployment, gegen das die native App (Android/Windows) spricht.
  static const String productionUrl =
      'https://jubla-wald-reporting.netlify.app';

  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Basis-URL für API, Formulare und Handbuch.
  ///
  /// Im Web ist sie leer (gleiche Origin wie die ausgelieferte App, damit das
  /// Auth-Cookie automatisch mitgesendet wird). Native Apps nutzen die
  /// Produktiv-URL.
  static String get baseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride.replaceAll(RegExp(r'/+$'), '');
    }
    return kIsWeb ? '' : productionUrl;
  }

  /// Öffentliche URL des Handbuchs (MkDocs unter /handbuch).
  static String get handbookUrl => kIsWeb && _apiBaseUrlOverride.isEmpty
      ? '/handbuch/'
      : '${baseUrl.isEmpty ? productionUrl : baseUrl}/handbuch/';

  /// Wetter-Standort (Wald/ZH).
  static const double weatherLat = 47.2753;
  static const double weatherLon = 8.9168;

  // GlitchTip (Sentry-kompatibel), wie in der PWA.
  static const String glitchtipHost = 'app.glitchtip.com';
  static const String glitchtipProjectId = '27686';
  static const String glitchtipKey = '6844209f01aa45e6b55f510ebd812e41';
  static const String environment = kReleaseMode ? 'production' : 'development';
}

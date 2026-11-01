import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'config.dart';
import 'i18n/i18n.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/error_reporter.dart';
import 'services/forms_service.dart';
import 'services/platform_services.dart';
import 'services/weather_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();
  final i18n = await I18n.load(prefs: prefs);
  final reporter = ErrorReporter();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    reporter.reportUncaught(details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    reporter.reportUncaught(error, stack);
    return true;
  };

  final api = ApiClient(baseUrl: AppConfig.baseUrl);
  final auth = AuthService(api, prefs, reporter);

  runApp(
    MultiProvider(
      providers: appProviders(
        i18n: i18n,
        api: api,
        auth: auth,
        reporter: reporter,
        forms: FormsService(api),
        config: ConfigService(api),
        weather: WeatherService(),
        opener: const DefaultUrlOpener(),
        photos: ImagePickerPhotoPicker(),
      ),
      child: const JublaApp(),
    ),
  );
}

/// Alle von den Screens benötigten Abhängigkeiten (in Tests ersetzbar).
List<SingleChildWidget> appProviders({
  required I18n i18n,
  required ApiClient api,
  required AuthService auth,
  required ErrorReporter reporter,
  required FormsService forms,
  required ConfigService config,
  required WeatherService weather,
  required UrlOpener opener,
  required PhotoPicker photos,
}) => [
  ChangeNotifierProvider<I18n>.value(value: i18n),
  Provider<ApiClient>.value(value: api),
  ChangeNotifierProvider<AuthService>.value(value: auth),
  Provider<ErrorReporter>.value(value: reporter),
  Provider<FormsService>.value(value: forms),
  Provider<ConfigService>.value(value: config),
  Provider<WeatherService>.value(value: weather),
  Provider<UrlOpener>.value(value: opener),
  Provider<PhotoPicker>.value(value: photos),
];

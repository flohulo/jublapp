import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jublapp/app.dart';
import 'package:jublapp/i18n/i18n.dart';
import 'package:jublapp/main.dart' show appProviders;
import 'package:jublapp/services/api_client.dart';
import 'package:jublapp/services/auth_service.dart';
import 'package:jublapp/services/error_reporter.dart';
import 'package:jublapp/services/forms_service.dart';
import 'package:jublapp/services/platform_services.dart';
import 'package:jublapp/services/weather_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 1×1-PNG für Foto-Tests.
final Uint8List tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

class RecordedRequest {
  RecordedRequest(this.method, this.url, this.headers, this.body);
  final String method;
  final Uri url;
  final Map<String, String> headers;
  final String body;

  Map<String, dynamic> get json => jsonDecode(body) as Map<String, dynamic>;
  Map<String, String> get form => Uri.splitQueryString(body);
  @override
  String toString() => '$method $url';
}

class FakeUrlOpener implements UrlOpener {
  final List<Uri> opened = [];
  bool result = true;

  @override
  Future<bool> open(Uri uri, {bool sameTab = false}) async {
    opened.add(uri);
    return result;
  }
}

class FakePhotoPicker implements PhotoPicker {
  @override
  bool cameraSupported = true;
  List<PickedPhoto> gallery = [
    PickedPhoto(name: 'a.png', bytes: tinyPng, mimeType: 'image/png'),
  ];
  PickedPhoto? camera = PickedPhoto(name: 'cam.jpg', bytes: tinyPng);

  @override
  Future<List<PickedPhoto>> pickFromGallery() async => gallery;

  @override
  Future<PickedPhoto?> takePhoto() async => camera;
}

final sampleWeather = {
  'current': {
    'time': '2026-10-30T10:00',
    'temperature_2m': 12.4,
    'relative_humidity_2m': 81,
    'weather_code': 63,
    'wind_speed_10m': 7.2,
    'precipitation': 0.0,
  },
  'hourly': {
    'time': [
      for (var h = 0; h < 48; h++)
        '2026-10-${30 + h ~/ 24}T${(h % 24).toString().padLeft(2, '0')}:00',
    ],
    'temperature_2m': [for (var h = 0; h < 48; h++) 10.0 + h % 5],
    'weather_code': [for (var h = 0; h < 48; h++) h.isEven ? 3 : 61],
  },
  'daily': {
    'time': [
      '2026-10-30',
      '2026-10-31',
      '2026-11-01',
      '2026-11-02',
      '2026-11-03',
      '2026-11-04',
      '2026-11-05',
    ],
    'weather_code': [63, 3, 0, 95, 71, 45, 61],
    'temperature_2m_max': [13.0, 11.5, 9.0, 8.0, 3.0, 5.0, 7.0],
    'temperature_2m_min': [8.0, 6.0, 4.0, 3.0, -1.0, 0.0, 2.0],
    'rain_sum': [4.2, 0.0, 0.0, 1.0, 0.0, 0.0, 2.5],
  },
};

/// Gebündelte Test-Umgebung: gefälschtes Backend + App-Start.
class TestEnv {
  TestEnv({
    this.pin = '1234',
    this.token = 'tok123',
    this.alarms = const [],
    this.strikeStatus = 200,
    this.formStatus = 200,
    this.scharEmail = 'schar@example.ch',
    this.weatherFails = false,
  });

  final String pin;
  final String token;
  List<Map<String, Object?>> alarms;
  int strikeStatus;
  int formStatus;
  String scharEmail;
  bool weatherFails;

  final List<RecordedRequest> requests = [];
  final opener = FakeUrlOpener();
  final photos = FakePhotoPicker();
  late SharedPreferences prefs;
  late I18n i18n;
  late AuthService auth;
  late ApiClient api;

  /// Streaming-Mock: Multipart-Bodies (Binärdaten) lassen sich so auslesen.
  MockClient get client => MockClient.streaming((request, bodyStream) async {
    final bytes = await bodyStream.toBytes();
    final body = utf8.decode(bytes, allowMalformed: true);
    final response = await _handle(request, body);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  });

  List<RecordedRequest> where(String path) =>
      requests.where((r) => r.url.path == path).toList();

  Future<http.Response> _handle(http.BaseRequest request, String body) async {
    requests.add(
      RecordedRequest(request.method, request.url, request.headers, body),
    );
    final json = {'content-type': 'application/json; charset=utf-8'};
    switch (request.url.path) {
      case '/api/login':
        if (Uri.splitQueryString(body)['pin'] == pin) {
          return http.Response(
            '{"ok":true}',
            200,
            headers: {
              ...json,
              'set-cookie':
                  'auth=$token; Path=/; HttpOnly; SameSite=Lax; Max-Age=2592000',
            },
          );
        }
        return http.Response('{"error":"Invalid PIN"}', 401, headers: json);
      case '/api/logout':
        return http.Response(
          '',
          204,
          headers: {
            'set-cookie': 'auth=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0',
          },
        );
      case '/api/config':
        return http.Response(
          jsonEncode({'SCHAR_EMAIL': scharEmail, 'SUPPORT_PHONE': ''}),
          200,
          headers: json,
        );
      case '/api/strikes':
        if (strikeStatus != 200) {
          return http.Response(
            '{"ok":false,"error":"Boom"}',
            strikeStatus,
            headers: json,
          );
        }
        return http.Response(
          jsonEncode({'ok': true, 'saved': 1, 'alarms': alarms}),
          200,
          headers: json,
        );
      case '/forms.html':
        return http.Response('<html></html>', formStatus);
      case '/v1/forecast':
        if (weatherFails) return http.Response('nope', 500);
        return http.Response(jsonEncode(sampleWeather), 200, headers: json);
    }
    return http.Response('not found', 404);
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    String lang = 'de',
    bool loggedIn = true,
    String initialLocation = '/',
    Size size = const Size(700, 1500),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      'lang': lang,
      if (loggedIn) 'auth_token': token,
    });
    prefs = await SharedPreferences.getInstance();
    // Direkt aus den Dateien (rootBundle-Laden ist in FakeAsync-Tests unzuverlässig).
    i18n = I18n.fromMaps(
      {
        for (final l in I18n.supported)
          l:
              (jsonDecode(File('assets/locales/$l.json').readAsStringSync())
                      as Map<String, dynamic>)
                  .map((k, v) => MapEntry(k, v as String)),
      },
      lang: I18n.detectLanguage(stored: prefs.getString('lang')),
      prefs: prefs,
    );

    final client = this.client;
    api = ApiClient(
      client: client,
      baseUrl: 'https://test.local',
      manageCookie: true,
    );
    final reporter = ErrorReporter(client: client, enabled: false);
    auth = AuthService(api, prefs, reporter);

    // Frischer Baum pro Aufruf (sonst bleibt der State/Router des vorigen erhalten).
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MultiProvider(
        key: UniqueKey(),
        providers: appProviders(
          i18n: i18n,
          api: api,
          auth: auth,
          reporter: reporter,
          forms: FormsService(api),
          config: ConfigService(api),
          weather: WeatherService(client: client),
          opener: opener,
          photos: photos,
        ),
        child: JublaApp(initialLocation: initialLocation),
      ),
    );
    await tester.pumpAndSettle();
  }
}

/// Alle sichtbaren Texte der aktuellen Ansicht.
List<String> visibleTexts(WidgetTester tester) => [
  for (final w in tester.widgetList<Text>(find.byType(Text)))
    if (w.data != null) w.data! else w.textSpan?.toPlainText() ?? '',
];

/// Rohe Übersetzungsschlüssel (`foo.bar_baz`) wären ein Übersetzungsfehler.
/// (Domainnamen wie `jubla.ch` sind erlaubt.)
final RegExp rawKeyPattern = RegExp(r'^(?![a-z0-9-]+\.ch$)[a-z]+\.[a-z0-9_]+$');

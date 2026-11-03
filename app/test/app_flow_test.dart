import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jublapp/config.dart';
import 'package:jublapp/i18n/i18n.dart';
import 'package:jublapp/router.dart';
import 'package:jublapp/services/api_client.dart';
import 'package:jublapp/services/platform_services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'helpers.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 1400));
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String key, String text) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.enterText(finder, text);
  await tester.pump();
}

Future<void> chooseDropdown(
  WidgetTester tester,
  String key,
  String label,
) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> tapSave(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Speichern'));
  await tester.pump();
}

void main() {
  group('Routing', () {
    test('alte PWA-Adressen werden auf Routen abgebildet', () {
      expect(Routes.normalize('/pages/ereignis'), Routes.ereignis);
      expect(Routes.normalize('/pages/links.html'), Routes.links);
      expect(Routes.normalize('/pages/uebersicht.html'), Routes.overview);
      expect(Routes.normalize('/erfolg.html'), Routes.success);
      expect(Routes.normalize('/index.html'), Routes.login);
      expect(Routes.normalize('/links/'), Routes.links);
      expect(Routes.normalize('/pages/lager.html'), Routes.lager);
      expect(Routes.normalize('/gibt-es-nicht'), Routes.login);
    });

    testWidgets('ohne Login landet jede Seite beim Login', (tester) async {
      final env = TestEnv();
      await env.pumpApp(tester, loggedIn: false, initialLocation: '/strike');
      expect(find.byKey(const Key('pin-field')), findsOneWidget);
    });

    testWidgets(
      'mit Login führt der Login-Link zur Übersicht, alte Adresse funktioniert',
      (tester) async {
        final env = TestEnv();
        await env.pumpApp(tester, initialLocation: '/pages/links.html');
        expect(find.text('Notfall & Krise'), findsOneWidget);
      },
    );
  });

  group('Login', () {
    testWidgets('zu viele Fehlversuche (429) zeigen eine eigene Meldung', (
      tester,
    ) async {
      final env = TestEnv(loginRateLimited: true);
      await env.pumpApp(tester, loggedIn: false);
      await enter(tester, 'pin-field', '9999');
      await tapKey(tester, 'login-button');
      await tester.pumpAndSettle();
      expect(
        find.text('Zu viele Fehlversuche. Bitte in 15 Minuten erneut versuchen.'),
        findsOneWidget,
      );
      expect(env.auth.loggedIn, isFalse);
    });

    testWidgets('falscher PIN zeigt Fehler und bleibt auf Login', (
      tester,
    ) async {
      final env = TestEnv();
      await env.pumpApp(tester, loggedIn: false);
      await enter(tester, 'pin-field', '9999');
      await tapKey(tester, 'login-button');
      await tester.pumpAndSettle();
      expect(find.text('Falscher PIN.'), findsOneWidget);
      expect(find.byKey(const Key('pin-field')), findsOneWidget);
      expect(env.auth.loggedIn, isFalse);
    });

    testWidgets('richtiger PIN: Cookie wird gespeichert und mitgesendet', (
      tester,
    ) async {
      final env = TestEnv();
      await env.pumpApp(tester, loggedIn: false);
      await enter(tester, 'pin-field', '1234');
      await tapKey(tester, 'login-button');
      await tester.pumpAndSettle();

      expect(find.textContaining('Übersicht'), findsOneWidget);
      expect(env.auth.loggedIn, isTrue);
      expect(env.prefs.getString('auth_token'), env.token);
      expect(env.where('/api/login').single.form['pin'], '1234');

      // Folgeanfrage trägt das Cookie.
      await tester.tap(find.text('Links'));
      await tester.pumpAndSettle();
      expect(
        env.where('/api/config').single.headers['Cookie'],
        'auth=${env.token}',
      );
    });

    testWidgets('Logout ruft /api/logout auf und löscht die Sitzung', (
      tester,
    ) async {
      final env = TestEnv();
      await env.pumpApp(tester);
      await tester.tap(find.byTooltip('Abmelden'));
      await tester.pumpAndSettle();
      expect(env.where('/api/logout'), hasLength(1));
      expect(env.prefs.getString('auth_token'), isNull);
      expect(find.byKey(const Key('pin-field')), findsOneWidget);
    });

    testWidgets('abgelaufene Sitzung (401) führt zurück zum Login', (
      tester,
    ) async {
      final env = TestEnv(strikeStatus: 401);
      await env.pumpApp(tester, initialLocation: '/strike');
      await enter(tester, 'strike-leader', 'Flo');
      await tapSave(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pin-field')), findsOneWidget);
      expect(env.auth.loggedIn, isFalse);
    });
  });

  group('Navigation', () {
    testWidgets(
      'Übersicht → Gruppenstunde → Strike/Ereignis/Wetter und zurück',
      (tester) async {
        final env = TestEnv();
        await env.pumpApp(tester);
        await tester.tap(find.text('Gruppenstunde'));
        await tester.pumpAndSettle();
        for (final entry in {
          'Strike': 'Strike-Verwaltung',
          'Ereignis melden': 'Ereignis melden',
          'Wetter (Beta)': 'Wetter (Beta)',
        }.entries) {
          await tester.tap(find.text(entry.key));
          await tester.pumpAndSettle();
          expect(find.textContaining(entry.value), findsWidgets);
          await tester.tap(find.byTooltip('Schliessen'));
          await tester.pumpAndSettle();
          expect(find.textContaining('Gruppenstunde'), findsWidgets);
        }
      },
    );
  });

  group('Strike', () {
    testWidgets(
      'ohne Leiter:in erscheint die Fehlermeldung, nichts wird gesendet',
      (tester) async {
        final env = TestEnv();
        await env.pumpApp(tester, initialLocation: '/strike');
        await tapSave(tester);
        expect(find.text('Bitte Leiter:in angeben.'), findsOneWidget);
        expect(env.where('/api/strikes'), isEmpty);
      },
    );

    testWidgets(
      'speichert Strikes, zeigt Alarm und wechselt zur Erfolgsseite',
      (tester) async {
        final env = TestEnv(
          alarms: [
            {
              'name': 'Max',
              'strikes': 3,
              'reasons': ['x'],
            },
          ],
        );
        await env.pumpApp(tester, initialLocation: '/strike');
        await enter(tester, 'strike-leader', 'Flo');
        await enter(tester, 'strike-name-1', 'Max');
        await enter(tester, 'strike-count-1', '3');
        await enter(tester, 'strike-count-2', '9'); // nur 0–3 zulässig
        await tapSave(tester);
        await tester.pump();
        expect(
          find.text('Gespeichert. Alarm ausgelöst für: Max'),
          findsOneWidget,
        );
        await settle(tester);

        final body = env.where('/api/strikes').single.json;
        expect(body['leiterName'], 'Flo');
        expect(body['child_name_1'], 'Max');
        expect(body['child_strikes_1'], '3');
        expect(body['child_strikes_2'], '');
        expect(body['datetime'], matches(r'^\d{2}\.\d{2}\.\d{4}$'));
        expect(find.text('Erfolgreich übermittelt'), findsOneWidget);

        await tester.tap(find.byKey(const Key('back-to-overview')));
        await tester.pumpAndSettle();
        expect(find.text('Gruppenstunde'), findsOneWidget);
      },
    );

    testWidgets('Serverfehler wird angezeigt', (tester) async {
      final env = TestEnv(strikeStatus: 500);
      await env.pumpApp(tester, initialLocation: '/strike');
      await enter(tester, 'strike-leader', 'Flo');
      await tapSave(tester);
      await tester.pumpAndSettle();
      expect(find.text('Fehler beim Speichern: Boom'), findsOneWidget);
    });
  });

  group('Ereignis', () {
    testWidgets('Pflichtfelder werden der Reihe nach geprüft', (tester) async {
      final env = TestEnv();
      await env.pumpApp(tester, initialLocation: '/ereignis');
      await tapSave(tester);
      expect(
        find.text('Bitte Name der meldenden Person eintragen.'),
        findsOneWidget,
      );

      await enter(tester, 'ereignis-melder', 'Anna Muster');
      await tapSave(tester);
      expect(
        find.text('Bitte Funktion der meldenden Person angeben.'),
        findsOneWidget,
      );

      await chooseDropdown(tester, 'ereignis-funktion', 'Hauptleitung');
      await tapSave(tester);
      expect(
        find.text('Bitte Art des Ereignisses als Stichwort eintragen.'),
        findsOneWidget,
      );
      expect(env.where('/forms.html'), isEmpty);
    });

    testWidgets('sendet vollständiges Formular samt Fotos als Netlify-Form', (
      tester,
    ) async {
      final env = TestEnv();
      await env.pumpApp(tester, lang: 'en', initialLocation: '/ereignis');
      await enter(tester, 'ereignis-melder', 'Anna Muster');
      await chooseDropdown(tester, 'ereignis-funktion', 'Main Leader');
      await chooseDropdown(tester, 'ereignis-kategorie', 'Property damage');
      await enter(tester, 'ereignis-art', 'Sturz');
      await chooseDropdown(tester, 'ereignis-schweregrad', 'Medium');
      await enter(tester, 'ereignis-ort', 'Wald');
      await enter(tester, 'ereignis-beschreibung', 'Ausgerutscht');
      await tapKey(tester, 'photo-gallery');
      await tapKey(tester, 'photo-camera');
      expect(find.byType(Image), findsNWidgets(2));

      await tester.tap(find.byTooltip('Save'));
      await tester.pump();
      await settle(tester);

      final request = env.where('/forms.html').single;
      expect(request.headers['Cookie'], 'auth=${env.token}');
      expect(
        request.headers['content-type'],
        startsWith('multipart/form-data'),
      );
      final body = request.body;
      // Werte werden unabhängig von der UI-Sprache auf Deutsch gespeichert.
      for (final expected in [
        'name="form-name"',
        'ereignis',
        'name="melder_funktion"',
        'Hauptleitung',
        'name="kategorie"',
        'Sachschaden',
        'name="schweregrad"',
        'Mittel',
        'name="art"',
        'Sturz',
        'name="ort"',
        'name="beschreibung"',
        'name="foto_1"; filename="ereignis_1.png"',
        'name="foto_2"; filename="ereignis_2.jpg"',
        'name="bot-field"',
        'name="weiteres_vorgehen"',
      ]) {
        expect(body, contains(expected));
      }
      expect(
        body,
        matches(RegExp(r'name="datum"\r?\n\r?\n\d{4}-\d{2}-\d{2}T\d{2}:\d{2}')),
      );
      expect(find.text('Successfully submitted'), findsOneWidget);
    });

    testWidgets('mehr als 10 Fotos werden abgewiesen', (tester) async {
      final env = TestEnv();
      env.photos.gallery = List.generate(
        12,
        (i) =>
            PickedPhoto(name: 'p$i.png', bytes: tinyPng, mimeType: 'image/png'),
      );
      await env.pumpApp(tester, initialLocation: '/ereignis');
      await tapKey(tester, 'photo-gallery');
      expect(find.text('Maximal 10 Fotos möglich.'), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(10));
    });
  });

  group('Feedback', () {
    testWidgets(
      'leere Beschreibung wird abgelehnt, sonst url-encoded gesendet',
      (tester) async {
        final env = TestEnv();
        await env.pumpApp(tester, initialLocation: '/feedback');
        await tapSave(tester);
        expect(find.text('Bitte Beschreibung eingeben.'), findsOneWidget);

        await enter(tester, 'feedback-email', 'a@b.ch');
        await enter(tester, 'feedback-message', 'Super App');
        await tapSave(tester);
        await settle(tester);

        final form = env.where('/forms.html').single.form;
        expect(form['form-name'], 'feedback-form');
        expect(form['type'], 'Bug Report');
        expect(form['email'], 'a@b.ch');
        expect(form['message'], 'Super App');
        expect(
          form['timestamp'],
          matches(r'^\d{2}\.\d{2}\.\d{4} \d{2}:\d{2}$'),
        );
        expect(find.text('Erfolgreich übermittelt'), findsOneWidget);
      },
    );

    testWidgets('Fehler beim Senden lässt erneutes Senden zu', (tester) async {
      final env = TestEnv(formStatus: 500);
      await env.pumpApp(tester, initialLocation: '/feedback');
      await enter(tester, 'feedback-message', 'Hallo');
      await tapSave(tester);
      await tester.pumpAndSettle();
      expect(
        find.text('Fehler beim Senden. Bitte versuche es nochmals.'),
        findsOneWidget,
      );
      env.formStatus = 200;
      await tapSave(tester);
      await settle(tester);
      expect(find.text('Erfolgreich übermittelt'), findsOneWidget);
    });
  });

  group('Wetter', () {
    testWidgets('lädt und zeigt aktuelle Werte, Stunden und Tage', (
      tester,
    ) async {
      final env = TestEnv();
      await env.pumpApp(tester, initialLocation: '/wetter');
      expect(
        tester.widget<Text>(find.byKey(const Key('weather-temp'))).data,
        '12°',
      );
      expect(find.text('Mässiger Regen'), findsOneWidget);
      expect(find.text('7 km/h'), findsOneWidget);
      expect(find.text('81%'), findsOneWidget);
      expect(find.text('0 mm'), findsWidgets);
      expect(find.text('Datenstand: 30.10.2026, 10:00 Uhr'), findsOneWidget);
      expect(find.text('Heute'), findsOneWidget);
      // 30.10.2026 ist ein Freitag → 31.10. Samstag.
      expect(find.text('Sa'), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget);
      expect(
        env.where('/v1/forecast').single.url.queryParameters['timezone'],
        'Europe/Zurich',
      );
    });

    testWidgets(
      'Fehler beim Laden wird angezeigt und Aktualisieren funktioniert',
      (tester) async {
        final env = TestEnv(weatherFails: true);
        await env.pumpApp(tester, initialLocation: '/wetter');
        expect(find.text('Fehler beim Laden'), findsOneWidget);
        env.weatherFails = false;
        await tester.tap(
          find.byWidgetPredicate(
            (w) =>
                w is FaIcon && w.icon == FontAwesomeIcons.rotateRight.data,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Mässiger Regen'), findsOneWidget);
      },
    );
  });

  group('Links', () {
    testWidgets('zeigt Schar-E-Mail aus /api/config und öffnet mailto', (
      tester,
    ) async {
      final env = TestEnv();
      await env.pumpApp(tester, initialLocation: '/links');
      expect(find.text('schar@example.ch'), findsOneWidget);
      await tester.tap(find.text('Schar E-Mail'));
      await tester.pumpAndSettle();
      expect(env.opener.opened.single.toString(), 'mailto:schar@example.ch');
    });

    testWidgets('nicht konfigurierte E-Mail wird gemeldet', (tester) async {
      final env = TestEnv(scharEmail: '');
      await env.pumpApp(tester, initialLocation: '/links');
      expect(find.text('Nicht konfiguriert'), findsOneWidget);
    });

    testWidgets('Notfallnummer: Bestätigung, dann Anruf', (tester) async {
      final env = TestEnv();
      await env.pumpApp(tester, initialLocation: '/links');
      expect(find.byKey(const Key('call-zh')), findsNothing);
      await tapKey(tester, 'emergency-toggle');
      await tapKey(tester, 'call-zh');
      expect(find.text('Krisentelefon anrufen?'), findsOneWidget);

      await tapKey(tester, 'call-cancel');
      expect(env.opener.opened, isEmpty);

      await tapKey(tester, 'call-national');
      await tapKey(tester, 'call-confirm');
      expect(env.opener.opened.single.toString(), 'tel:+41792597690');
    });

    testWidgets('ohne Telefon-App wird die Nummer kopiert', (tester) async {
      final env = TestEnv();
      env.opener.result = false;
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await env.pumpApp(tester, initialLocation: '/links');
      await tapKey(tester, 'emergency-toggle');
      await tapKey(tester, 'call-zh');
      await tapKey(tester, 'call-confirm');
      expect(clipboard, '0800 505 202');
      expect(find.text('Nummer kopiert: 0800 505 202'), findsOneWidget);
    });

    testWidgets('Websites und Handbuch werden geöffnet, Feedback navigiert', (
      tester,
    ) async {
      final env = TestEnv();
      await env.pumpApp(tester, initialLocation: '/links');
      await tester.tap(find.text('eCamp3'));
      await tester.pumpAndSettle();
      expect(env.opener.opened.last.toString(), 'https://app.ecamp3.ch/');
      await tester.tap(find.text('Handbuch'));
      await tester.pumpAndSettle();
      expect(env.opener.opened.last.path, '/handbuch/');
      await tester.tap(find.text('Datenschutz'));
      await tester.pumpAndSettle();
      expect(env.opener.opened.last.path, '/handbuch/datenschutz/');
      await tester.tap(find.text('Feedback & Bugreports'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('feedback-message')), findsOneWidget);
    });
  });

  group('Lager', () {
    testWidgets('Übersicht-Karte öffnet die Lager-Seite, Button öffnet Padlet', (
      tester,
    ) async {
      final env = TestEnv();
      await env.pumpApp(tester);
      await tester.tap(find.text('Lager'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('lager-open')), findsOneWidget);
      await tester.tap(find.byKey(const Key('lager-open')));
      await tester.pumpAndSettle();
      expect(env.opener.opened.single.toString(), AppConfig.padletUrl);
      await tester.tap(find.byTooltip('Schliessen'));
      await tester.pumpAndSettle();
      expect(find.text('Gruppenstunde'), findsOneWidget);
    });
  });

  group('Mehrsprachigkeit', () {
    testWidgets(
      'Sprachumschalter wirkt sofort auf alle Texte und wird gespeichert',
      (tester) async {
        final env = TestEnv();
        await env.pumpApp(tester);
        expect(find.text('Gruppenstunde'), findsOneWidget);
        for (final (code, label) in [
          ('EN', 'Group meeting'),
          ('FR', 'Heure de groupe'),
          ('IT', 'Incontro di gruppo'),
          ('DE', 'Gruppenstunde'),
        ]) {
          await tester.tap(find.text(code));
          await tester.pumpAndSettle();
          expect(find.text(label), findsOneWidget, reason: code);
        }
        await tester.tap(find.text('FR'));
        await tester.pumpAndSettle();
        expect(env.prefs.getString('lang'), 'fr');
      },
    );

    for (final lang in I18n.supported) {
      testWidgets('Kein Rohschlüssel sichtbar auf irgendeiner Seite ($lang)', (
        tester,
      ) async {
        final env = TestEnv();
        await env.pumpApp(tester, lang: lang, loggedIn: false);
        // Login-Seite
        expect(
          visibleTexts(tester).where(rawKeyPattern.hasMatch),
          isEmpty,
          reason: 'login/$lang',
        );

        for (final route in Routes.all.skip(1)) {
          await env.pumpApp(tester, lang: lang, initialLocation: route);
          if (route == Routes.links) {
            await tapKey(tester, 'emergency-toggle');
            await tapKey(tester, 'call-zh');
          }
          final raw = visibleTexts(
            tester,
          ).where(rawKeyPattern.hasMatch).toList();
          expect(raw, isEmpty, reason: '$route/$lang: $raw');
          expect(
            visibleTexts(tester).where((t) => t.trim().isEmpty).length,
            lessThan(visibleTexts(tester).length),
            reason: '$route/$lang',
          );
        }
      });
    }

    testWidgets('Fehlermeldungen sind in jeder Sprache übersetzt (Strike)', (
      tester,
    ) async {
      final env = TestEnv();
      await env.pumpApp(tester, lang: 'it', initialLocation: '/strike');
      await tester.tap(find.byTooltip('Salva'));
      await tester.pump();
      expect(find.text("Indicare l'animatore/-trice."), findsOneWidget);
    });
  });

  group('ApiClient', () {
    test(
      'Cookie wird nur bei Cookie-Verwaltung gelesen und gesendet',
      () async {
        final env = TestEnv();
        final client = ApiClient(
          client: env.client,
          baseUrl: 'https://x',
          manageCookie: false,
        );
        final r = await client.postFormRaw('/api/login', {'pin': '1234'});
        expect(r.statusCode, 200);
        expect(client.authToken, isNull);
        await client.get('/api/config');
        expect(env.requests.last.headers.containsKey('Cookie'), isFalse);
      },
    );

    test('401/403 lösen UnauthorizedException und Callback aus', () async {
      final env = TestEnv(strikeStatus: 403);
      var called = 0;
      final client = ApiClient(
        client: env.client,
        baseUrl: 'https://x',
        manageCookie: true,
        onUnauthorized: () => called++,
      );
      await expectLater(
        client.postJson('/api/strikes', {}),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(called, 1);
    });
  });
}

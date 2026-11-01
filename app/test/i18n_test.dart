import 'dart:convert';
import 'dart:io';

import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jublapp/i18n/i18n.dart';

/// Kontrolle der Mehrsprachigkeit: Quelle der Wahrheit ist `../locales/`
/// (Weblate); `assets/locales/` ist die Spiegelung für die App.
Map<String, String> _load(String dir, String lang) {
  final raw = File('$dir/$lang.json').readAsStringSync();
  return (jsonDecode(raw) as Map<String, dynamic>).map(
    (k, v) => MapEntry(k, v as String),
  );
}

Set<String> _placeholders(String text) =>
    RegExp(r'\{(\w+)\}').allMatches(text).map((m) => m.group(1)!).toSet();

void main() {
  const langs = I18n.supported;
  final source = {for (final l in langs) l: _load('../locales', l)};
  final assets = {for (final l in langs) l: _load('assets/locales', l)};

  test(
    'Quell-Locales und App-Assets sind identisch (npm run build ausführen)',
    () {
      for (final l in langs) {
        expect(assets[l], source[l], reason: 'assets/locales/$l.json veraltet');
      }
    },
  );

  test('alle Sprachen haben exakt dieselben Schlüssel wie Deutsch', () {
    final de = source['de']!.keys.toSet();
    for (final l in langs) {
      final keys = source[l]!.keys.toSet();
      expect(de.difference(keys), isEmpty, reason: '$l: fehlende Schlüssel');
      expect(keys.difference(de), isEmpty, reason: '$l: überzählige Schlüssel');
    }
  });

  test('Platzhalter stimmen in allen Sprachen überein', () {
    for (final entry in source['de']!.entries) {
      final expected = _placeholders(entry.value);
      for (final l in langs) {
        expect(
          _placeholders(source[l]![entry.key]!),
          expected,
          reason: '$l / ${entry.key}',
        );
      }
    }
  });

  test('keine leeren Übersetzungen', () {
    for (final l in langs) {
      source[l]!.forEach((k, v) {
        expect(v.trim(), isNotEmpty, reason: '$l / $k');
      });
    }
  });

  test('nicht-deutsche Texte sind tatsächlich übersetzt', () {
    // Schlüssel, die in jeder Sprache identisch sein dürfen.
    final same = RegExp(
      r'^(common\.app_name|login\.group_name|login\.pin_placeholder|'
      r'links\.(jubla_wald|ecamp|title)|lang\..*|wetter\.days_short_\d|'
      r'feedback\.email_placeholder|ereignis\.label_date|'
      r'strike\.label_date|feedback\.label_date|common\.date_time|'
      r'.*\.label_name_placeholder|common\.name|strike\.title|'
      r'uebersicht\.card_links|common\.links|feedback\.title|common\.feedback|'
      r'links\.feedback|common\.handbook|links\.handbook|links\.schar_email|'
      r'common\.error)$',
    );
    for (final l in langs.where((l) => l != 'de')) {
      final untranslated = [
        for (final e in source['de']!.entries)
          if (source[l]![e.key] == e.value && !same.hasMatch(e.key)) e.key,
      ];
      // Toleranz: einzelne Wörter, die in einer Sprache gleich lauten.
      expect(
        untranslated.length,
        lessThan(source['de']!.length ~/ 10),
        reason: '$l: wirkt unübersetzt: $untranslated',
      );
    }
  });

  test('jeder im Code verwendete Schlüssel existiert in allen Sprachen', () {
    final used = <String>{};
    final keyPattern = RegExp(r"""\bt\(\s*'([a-z_]+\.[a-z0-9_]+)'""");
    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      final text = file.readAsStringSync();
      used.addAll(keyPattern.allMatches(text).map((m) => m.group(1)!));
      // Direkt als String übergebene Schlüssel (z. B. in Listen/Konstanten).
      used.addAll(
        RegExp(
          r"""'((?:common|login|uebersicht|gruppenstunde|strike|ereignis|erfolg|links|wetter|feedback)\.[a-z0-9_]+)'""",
        ).allMatches(text).map((m) => m.group(1)!),
      );
    }
    expect(used, isNotEmpty);
    for (final l in langs) {
      final missing = used.where((k) => !source[l]!.containsKey(k)).toList();
      expect(
        missing,
        isEmpty,
        reason: '$l: im Code verwendet, aber nicht übersetzt',
      );
    }
    // Dynamische Schlüssel: Wettercodes, Wochentage.
    for (final l in langs) {
      for (final code in [
        0,
        1,
        2,
        3,
        45,
        48,
        51,
        53,
        55,
        61,
        63,
        65,
        71,
        73,
        75,
        77,
        80,
        81,
        82,
        85,
        86,
        95,
        96,
        99,
      ]) {
        expect(
          source[l]!.containsKey('wetter.code_$code'),
          isTrue,
          reason: '$l wetter.code_$code',
        );
      }
      for (var d = 0; d < 7; d++) {
        expect(source[l]!.containsKey('wetter.days_short_$d'), isTrue);
      }
    }
  });

  group('I18n', () {
    I18n make(String lang) => I18n.fromMaps(source, lang: lang);

    test('Übersetzen mit Parametern', () {
      expect(
        make('de').t('strike.success_alarm', {'names': 'Anna'}),
        'Gespeichert. Alarm ausgelöst für: Anna',
      );
      expect(
        make('fr').t('links.dialog_text', {'phone': '123'}),
        contains('123'),
      );
    });

    test(
      'Fallback: unbekannter Schlüssel liefert Schlüssel, fehlender Text Deutsch',
      () {
        expect(make('en').t('does.not.exist'), 'does.not.exist');
        final partial = I18n.fromMaps({
          'de': {'a.b': 'Hallo'},
          'en': <String, String>{},
        }, lang: 'en');
        expect(partial.t('a.b'), 'Hallo');
      },
    );

    test('Spracherkennung: gespeichert vor Gerät vor Deutsch', () {
      expect(I18n.detectLanguage(stored: 'it'), 'it');
      expect(I18n.detectLanguage(stored: 'xx', deviceLocales: const []), 'de');
      expect(
        I18n.detectLanguage(
          deviceLocales: const [Locale('es', 'ES'), Locale('fr', 'CH')],
        ),
        'fr',
      );
      expect(I18n.detectLanguage(deviceLocales: const [Locale('ja')]), 'de');
    });
  });

  testWidgets(
    'I18n.load liest die gebündelten Assets und merkt sich die Sprache',
    (tester) async {
      SharedPreferences.setMockInitialValues({'lang': 'fr'});
      final prefs = await SharedPreferences.getInstance();
      final i18n = await I18n.load(prefs: prefs, deviceLocales: const []);
      expect(i18n.lang, 'fr');
      expect(i18n.t('login.submit'), 'Se connecter');
      await i18n.setLanguage('it');
      expect(prefs.getString('lang'), 'it');
      expect(i18n.t('login.submit'), source['it']!['login.submit']);
    },
  );
}

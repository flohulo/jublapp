import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mehrsprachigkeit auf Basis der `assets/locales/*.json`
/// (flache Schlüssel wie `strike.title`, Platzhalter als `{name}`).
class I18n extends ChangeNotifier {
  I18n._(this._translations, this._lang, this._prefs);

  static const List<String> supported = ['de', 'gsw', 'fr', 'it', 'en'];
  static const String defaultLang = 'de';
  static const String storageKey = 'lang';

  final Map<String, Map<String, String>> _translations;
  final SharedPreferences? _prefs;
  String _lang;

  String get lang => _lang;
  Locale get locale => Locale(_lang);

  /// Lädt alle Sprachen und bestimmt die Startsprache
  /// (gespeichert → Gerätesprache → Deutsch).
  static Future<I18n> load({
    SharedPreferences? prefs,
    List<Locale>? deviceLocales,
    AssetBundle? bundle,
  }) async {
    final assets = bundle ?? rootBundle;
    final translations = <String, Map<String, String>>{};
    for (final code in supported) {
      final raw = await assets.loadString('assets/locales/$code.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      translations[code] = decoded.map((k, v) => MapEntry(k, v.toString()));
    }
    final lang = detectLanguage(
      stored: prefs?.getString(storageKey),
      deviceLocales: deviceLocales ?? ui.PlatformDispatcher.instance.locales,
    );
    return I18n._(translations, lang, prefs);
  }

  /// Für Tests: ohne Asset-Bundle direkt aus Maps erzeugen.
  @visibleForTesting
  factory I18n.fromMaps(
    Map<String, Map<String, String>> maps, {
    String lang = defaultLang,
    SharedPreferences? prefs,
  }) => I18n._(maps, lang, prefs);

  static String detectLanguage({
    String? stored,
    List<Locale> deviceLocales = const [],
  }) {
    if (stored != null && supported.contains(stored)) return stored;
    for (final locale in deviceLocales) {
      final code = locale.languageCode.toLowerCase();
      if (supported.contains(code)) return code;
    }
    return defaultLang;
  }

  Future<void> setLanguage(String lang) async {
    if (!supported.contains(lang)) lang = defaultLang;
    if (lang == _lang) return;
    _lang = lang;
    try {
      await _prefs?.setString(storageKey, lang);
    } catch (_) {}
    notifyListeners();
  }

  bool has(String key) => _translations[_lang]?.containsKey(key) ?? false;

  /// Übersetzt [key]. Fehlt er in der aktuellen Sprache, wird Deutsch
  /// verwendet, fehlt er auch dort, der Schlüssel selbst (wie in der PWA).
  String t(String key, [Map<String, Object?>? params]) {
    var text = _translations[_lang]?[key] ?? _translations[defaultLang]?[key];
    if (text == null) return key;
    if (params != null) {
      params.forEach((name, value) {
        text = text!.replaceAll('{$name}', '${value ?? ''}');
      });
    }
    return text!;
  }
}

extension I18nContext on BuildContext {
  /// Übersetzung mit Rebuild bei Sprachwechsel.
  String t(String key, [Map<String, Object?>? params]) =>
      watch<I18n>().t(key, params);

  I18n get i18n => read<I18n>();
}

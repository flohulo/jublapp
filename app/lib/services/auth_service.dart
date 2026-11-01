import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'error_reporter.dart';

enum LoginResult { success, invalidPin, failed }

/// Anmeldezustand (PIN-Login gegen `/api/login`, 30 Tage gültiges Cookie).
class AuthService extends ChangeNotifier {
  AuthService(this._api, this._prefs, this._reporter) {
    if (_api.manageCookie) {
      _api.authToken = _prefs?.getString(_tokenKey);
      _loggedIn = _api.authToken?.isNotEmpty ?? false;
    } else {
      _loggedIn = _prefs?.getBool(_hintKey) ?? false;
    }
    _api.onUnauthorized = expire;
  }

  static const _tokenKey = 'auth_token';
  // Im Web ist das Cookie HttpOnly; wir merken nur, ob eine Anmeldung bestand.
  static const _hintKey = 'auth_hint';

  final ApiClient _api;
  final SharedPreferences? _prefs;
  final ErrorReporter _reporter;
  bool _loggedIn = false;

  bool get loggedIn => _loggedIn;

  Future<LoginResult> login(String pin) async {
    int? status;
    try {
      final response = await _api.postFormRaw('/api/login', {'pin': pin});
      status = response.statusCode;
      if (status >= 200 && status < 300) {
        await _persist(true);
        return LoginResult.success;
      }
      if (status == 401) return LoginResult.invalidPin;
      throw ApiException('Login failed', statusCode: status);
    } catch (e) {
      _reporter.reportSubmissionFailure('login', e, status);
      return LoginResult.failed;
    }
  }

  Future<void> logout() async {
    try {
      await _api.postFormRaw('/api/logout', const {});
    } catch (_) {
      // Wie in der PWA: lokal abmelden, auch wenn der Server nicht erreichbar ist.
    } finally {
      await _persist(false);
    }
  }

  /// Sitzung vom Server abgelehnt → lokal abmelden.
  void expire() {
    if (!_loggedIn) return;
    _persist(false);
  }

  Future<void> _persist(bool value) async {
    _loggedIn = value;
    if (!value) _api.authToken = null;
    notifyListeners();
    try {
      if (_api.manageCookie) {
        final token = _api.authToken;
        if (value && token != null) {
          await _prefs?.setString(_tokenKey, token);
        } else {
          await _prefs?.remove(_tokenKey);
        }
      } else {
        await _prefs?.setBool(_hintKey, value);
      }
    } catch (_) {}
  }
}

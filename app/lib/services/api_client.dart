import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Server hat die Anmeldung abgelehnt (401/403) – Login nötig.
class UnauthorizedException implements Exception {
  const UnauthorizedException([this.statusCode = 401]);
  final int statusCode;
  @override
  String toString() => 'UnauthorizedException($statusCode)';
}

/// Fehlerantwort des Servers oder Netzwerkproblem.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class UploadFile {
  const UploadFile({
    required this.field,
    required this.filename,
    required this.bytes,
    this.contentType = 'image/jpeg',
  });
  final String field;
  final String filename;
  final Uint8List bytes;
  final String contentType;
}

/// HTTP-Zugriff auf die Netlify-Backends.
///
/// Authentifizierung läuft über das `auth`-Cookie:
/// * Web: der Browser verwaltet das (HttpOnly-)Cookie selbst.
/// * Native (Android/Windows): das Cookie wird aus der Login-Antwort gelesen,
///   persistiert und bei jeder Anfrage als `Cookie`-Header mitgesendet.
class ApiClient {
  ApiClient({
    http.Client? client,
    required this.baseUrl,
    bool? manageCookie,
    this.authToken,
    this.onUnauthorized,
  }) : _client = client ?? http.Client(),
       manageCookie = manageCookie ?? !kIsWeb;

  final http.Client _client;
  final String baseUrl;
  final bool manageCookie;

  /// Wert des `auth`-Cookies (nur wenn [manageCookie]).
  String? authToken;

  /// Wird bei 401/403 aufgerufen (z. B. um zur Anmeldung zurückzukehren).
  VoidCallback? onUnauthorized;

  static const Duration timeout = Duration(seconds: 60);

  Uri uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> _headers([Map<String, String>? extra]) => {
    if (manageCookie && authToken != null && authToken!.isNotEmpty)
      'Cookie': 'auth=$authToken',
    ...?extra,
  };

  /// Liest/entfernt das `auth`-Cookie aus einer Antwort (nur native).
  void _captureCookie(http.BaseResponse response) {
    if (!manageCookie) return;
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null) return;
    final match = RegExp(r'(?:^|[,;\s])auth=([^;,\s]*)').firstMatch(setCookie);
    if (match == null) return;
    final value = match.group(1) ?? '';
    authToken = value.isEmpty ? null : value;
  }

  Future<http.Response> _run(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(timeout);
      _captureCookie(response);
      return response;
    } on TimeoutException {
      throw const ApiException('timeout');
    } on http.ClientException catch (e) {
      throw ApiException(e.message);
    } on Exception catch (e) {
      throw ApiException(e.toString());
    }
  }

  void _checkAuth(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      onUnauthorized?.call();
      throw UnauthorizedException(response.statusCode);
    }
  }

  Future<http.Response> get(String path) async {
    final response = await _run(
      () => _client.get(uri(path), headers: _headers()),
    );
    _checkAuth(response);
    return response;
  }

  Future<http.Response> postJson(String path, Map<String, Object?> body) async {
    final response = await _run(
      () => _client.post(
        uri(path),
        headers: _headers({'Content-Type': 'application/json'}),
        body: jsonEncode(body),
      ),
    );
    _checkAuth(response);
    return response;
  }

  /// Login/Logout: 401 ist hier ein normales Ergebnis und löst weder
  /// Exception noch [onUnauthorized] aus.
  Future<http.Response> postFormRaw(String path, Map<String, String> body) =>
      _run(
        () => _client.post(
          uri(path),
          headers: _headers({
            'Content-Type': 'application/x-www-form-urlencoded',
          }),
          body: body,
        ),
      );

  Future<http.Response> postForm(String path, Map<String, String> body) async {
    final response = await postFormRaw(path, body);
    _checkAuth(response);
    return response;
  }

  Future<http.Response> postMultipart(
    String path,
    Map<String, String> fields,
    List<UploadFile> files,
  ) async {
    final response = await _run(() async {
      final request = http.MultipartRequest('POST', uri(path))
        ..headers.addAll(_headers())
        ..fields.addAll(fields);
      for (final file in files) {
        request.files.add(
          http.MultipartFile.fromBytes(
            file.field,
            file.bytes,
            filename: file.filename,
            contentType: MediaType.parse(file.contentType),
          ),
        );
      }
      return http.Response.fromStream(await _client.send(request));
    });
    _checkAuth(response);
    return response;
  }

  void close() => _client.close();
}

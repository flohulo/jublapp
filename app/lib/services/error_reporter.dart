import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

/// Meldet Fehler an GlitchTip (Sentry-kompatible Store-API), wie die PWA.
/// Nur in Release-Builds aktiv; Fehler beim Melden werden verschluckt.
class ErrorReporter {
  ErrorReporter({http.Client? client, bool? enabled})
    : _client = client ?? http.Client(),
      enabled = enabled ?? kReleaseMode;

  final http.Client _client;
  final bool enabled;
  final Random _random = Random.secure();

  static final Uri _endpoint = Uri.https(
    AppConfig.glitchtipHost,
    '/api/${AppConfig.glitchtipProjectId}/store/',
  );

  void reportSubmissionFailure(String form, Object error, [int? statusCode]) {
    _send(
      message: 'Form submission failed: $form',
      tags: {
        'form': form,
        'failure_type': error.runtimeType.toString(),
        if (statusCode != null) 'http_status': '$statusCode',
      },
    );
  }

  void reportUncaught(Object error, StackTrace? stack) {
    _send(
      message: '${error.runtimeType}: $error',
      tags: {'failure_type': error.runtimeType.toString()},
      level: 'fatal',
    );
  }

  String _eventId() => List.generate(
    16,
    (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  void _send({
    required String message,
    required Map<String, String> tags,
    String level = 'error',
  }) {
    if (!enabled) return;
    final event = {
      'event_id': _eventId(),
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'platform': 'other',
      'level': level,
      'message': message,
      'release': AppConfig.version,
      'environment': AppConfig.environment,
      'tags': {
        ...tags,
        'platform': defaultTargetPlatform.name,
        'web': '$kIsWeb',
      },
    };
    _client
        .post(
          _endpoint,
          headers: {
            'Content-Type': 'application/json',
            'X-Sentry-Auth':
                'Sentry sentry_version=7, '
                'sentry_client=jublapp-flutter/${AppConfig.version}, '
                'sentry_key=${AppConfig.glitchtipKey}',
          },
          body: jsonEncode(event),
        )
        .catchError((_) => http.Response('', 0));
  }
}

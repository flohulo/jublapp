import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../i18n/i18n.dart';
import '../router.dart';
import '../services/api_client.dart';
import '../services/error_reporter.dart';
import '../widgets/form_widgets.dart';
import '../widgets/page_scaffold.dart';

/// Strike-Verwaltung: erfasst bis zu 4 Kinder mit 0–3 Strikes und sendet sie
/// an `/api/strikes` (Sheet, Ausschluss-Mail, Muster-Erkennung).
class StrikeScreen extends StatefulWidget {
  const StrikeScreen({super.key});

  @override
  State<StrikeScreen> createState() => _StrikeScreenState();
}

class _StrikeScreenState extends State<StrikeScreen> {
  static const _kidCount = 4;

  final _date = TextEditingController(text: formatDate(DateTime.now()));
  final _leader = TextEditingController();
  final _names = List.generate(_kidCount, (_) => TextEditingController());
  final _strikes = List.generate(_kidCount, (_) => TextEditingController());

  bool _busy = false;
  String _status = '';
  bool _statusIsError = false;
  bool _statusIsSuccess = false;
  Timer? _redirect;

  @override
  void dispose() {
    _redirect?.cancel();
    for (final c in [_date, _leader, ..._names, ..._strikes]) {
      c.dispose();
    }
    super.dispose();
  }

  void _setStatus(String message, {bool error = false, bool success = false}) {
    setState(() {
      _status = message;
      _statusIsError = error;
      _statusIsSuccess = success;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (picked != null) _date.text = formatDate(picked);
  }

  Future<void> _submit() async {
    if (_busy) return;
    final i18n = context.read<I18n>();
    final api = context.read<ApiClient>();
    final reporter = context.read<ErrorReporter>();
    final router = GoRouter.of(context);

    if (_leader.text.trim().isEmpty) {
      _setStatus(i18n.t('strike.error_no_leader'));
      return;
    }

    setState(() => _busy = true);
    _setStatus(i18n.t('strike.saving'));

    // Feldnamen entsprechen dem Formular der PWA (backend/functions/strikes.js).
    final payload = <String, Object?>{
      'datetime': _date.text,
      'leiterName': _leader.text,
      for (var i = 0; i < _kidCount; i++) ...{
        'child_name_${i + 1}': _names[i].text,
        'child_strikes_${i + 1}': _strikes[i].text,
      },
    };

    int? statusCode;
    try {
      final response = await api.postJson('/api/strikes', payload);
      statusCode = response.statusCode;
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (statusCode < 200 || statusCode >= 300) {
        throw ApiException(
          (data['error'] as String?) ?? i18n.t('strike.error_unknown'),
          statusCode: statusCode,
        );
      }

      final alarms = (data['alarms'] as List?) ?? const [];
      if (alarms.isNotEmpty) {
        final names = alarms.map((a) => (a as Map)['name']).join(', ');
        _setStatus(
          i18n.t('strike.success_alarm', {'names': names}),
          success: true,
        );
      } else {
        _setStatus(i18n.t('strike.success'), success: true);
      }
      _redirect = Timer(const Duration(milliseconds: 1200), () {
        router.go(Routes.success);
      });
    } on UnauthorizedException {
      router.go(Routes.login);
    } catch (e) {
      reporter.reportSubmissionFailure('strike', e, statusCode);
      if (!mounted) return;
      _setStatus(
        i18n.t('strike.error_save', {'message': e.toString()}),
        error: true,
      );
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: context.t('strike.title'),
      leadingTooltip: context.t('common.close'),
      onLeading: () => context.go(Routes.groupHour),
      action: HeaderAction(
        icon: FontAwesomeIcons.check,
        tooltip: context.t('common.save'),
        onPressed: _busy ? null : _submit,
      ),
      body: FormColumn(
        children: [
          FormGroup(
            label: context.t('strike.label_date'),
            child: JublaTextField(
              fieldKey: const Key('strike-date'),
              controller: _date,
              suffixIcon: IconButton(
                icon: const FaIcon(FontAwesomeIcons.calendarDays, size: 18),
                onPressed: _pickDate,
              ),
            ),
          ),
          FormGroup(
            label: context.t('strike.label_leader'),
            child: JublaTextField(
              fieldKey: const Key('strike-leader'),
              controller: _leader,
              hint: context.t('strike.label_name_placeholder'),
            ),
          ),
          for (var i = 0; i < _kidCount; i++) ...[
            FormGroup(
              label: context.t('strike.label_child_name', {'n': i + 1}),
              child: JublaTextField(
                fieldKey: Key('strike-name-${i + 1}'),
                controller: _names[i],
              ),
            ),
            FormGroup(
              label: context.t('strike.label_strike_count'),
              child: JublaTextField(
                fieldKey: Key('strike-count-${i + 1}'),
                controller: _strikes[i],
                keyboardType: TextInputType.number,
                hint: '0',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-3]')),
                  LengthLimitingTextInputFormatter(1),
                ],
              ),
            ),
          ],
          StatusMessage(
            _status,
            isError: _statusIsError,
            isSuccess: _statusIsSuccess,
          ),
        ],
      ),
    );
  }
}

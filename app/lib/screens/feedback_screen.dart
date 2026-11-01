import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../i18n/i18n.dart';
import '../router.dart';
import '../services/api_client.dart';
import '../services/error_reporter.dart';
import '../services/forms_service.dart';
import '../widgets/form_widgets.dart';
import '../widgets/page_scaffold.dart';

/// Feedback & Bugreports. Netlify-Form `feedback-form` (url-encoded).
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  // (Wert für Netlify, i18n-Schlüssel)
  static const _types = [
    ('Bug Report', 'feedback.category_bug'),
    ('Feedback', 'feedback.category_idea'),
    ('Sonstiges', 'feedback.category_other'),
  ];

  final _email = TextEditingController();
  final _message = TextEditingController();
  final _timestamp = DateTime.now();
  late final _dateCtrl = TextEditingController(
    text: formatDateTime(_timestamp),
  );
  String _type = _types.first.$1;

  bool _busy = false;
  String _status = '';
  bool _statusIsError = false;
  Timer? _redirect;

  @override
  void dispose() {
    _redirect?.cancel();
    _dateCtrl.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  void _setStatus(String message, {bool error = false}) {
    setState(() {
      _status = message;
      _statusIsError = error;
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    final i18n = context.read<I18n>();
    final forms = context.read<FormsService>();
    final reporter = context.read<ErrorReporter>();
    final router = GoRouter.of(context);

    if (_message.text.trim().isEmpty) {
      _setStatus(i18n.t('feedback.error_no_message'), error: true);
      return;
    }

    setState(() => _busy = true);
    _setStatus(i18n.t('feedback.sending'));

    int? statusCode;
    try {
      await forms.submitUrlEncoded({
        'form-name': 'feedback-form',
        'type': _type,
        'email': _email.text.trim(),
        'timestamp': formatDateTime(_timestamp),
        'message': _message.text,
      });
      router.go(Routes.success);
    } on UnauthorizedException {
      router.go(Routes.login);
    } catch (e) {
      if (e is ApiException) statusCode = e.statusCode;
      reporter.reportSubmissionFailure('feedback', e, statusCode);
      if (!mounted) return;
      _setStatus(i18n.t('feedback.error_send'), error: true);
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: context.t('feedback.title'),
      leadingTooltip: context.t('common.close'),
      onLeading: () => context.go(Routes.links),
      action: HeaderAction(
        icon: FontAwesomeIcons.check,
        tooltip: context.t('common.save'),
        onPressed: _busy ? null : _submit,
      ),
      body: FormColumn(
        children: [
          FormGroup(
            label: context.t('feedback.label_category'),
            child: JublaDropdown<String>(
              fieldKey: const Key('feedback-type'),
              value: _type,
              placeholder: context.t('common.please_select'),
              items: [
                for (final (value, key) in _types)
                  DropdownMenuItem(value: value, child: Text(context.t(key))),
              ],
              onChanged: (v) => setState(() => _type = v ?? _types.first.$1),
            ),
          ),
          FormGroup(
            label: context.t('feedback.label_email'),
            child: JublaTextField(
              fieldKey: const Key('feedback-email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              hint: context.t('feedback.email_placeholder'),
              autofillHints: const [AutofillHints.email],
            ),
          ),
          FormGroup(
            label: context.t('feedback.label_date'),
            child: JublaTextField(
              fieldKey: const Key('feedback-date'),
              controller: _dateCtrl,
              readOnly: true,
            ),
          ),
          FormGroup(
            label: context.t('feedback.label_message'),
            child: JublaTextField(
              fieldKey: const Key('feedback-message'),
              controller: _message,
              hint: context.t('feedback.message_placeholder'),
              minLines: 5,
              maxLines: 10,
            ),
          ),
          StatusMessage(_status, isError: _statusIsError),
        ],
      ),
    );
  }
}

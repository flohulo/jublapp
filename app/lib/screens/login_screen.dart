import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../i18n/i18n.dart';
import '../router.dart';
import '../services/auth_service.dart';
import '../services/platform_services.dart';
import '../theme.dart';
import '../widgets/lang_switcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _pin = TextEditingController();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
  );
  bool _busy = false;
  bool _error = false;
  String _errorKey = '';

  @override
  void dispose() {
    _pin.dispose();
    _shake.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || _pin.text.isEmpty) return;
    final auth = context.read<AuthService>();
    setState(() {
      _busy = true;
      _error = false;
      _errorKey = '';
    });
    final result = await auth.login(_pin.text);
    if (!mounted) return;
    if (result == LoginResult.success) {
      context.go(Routes.overview);
      return;
    }
    _pin.clear();
    setState(() {
      _busy = false;
      _error = true;
      _errorKey = switch (result) {
        LoginResult.invalidPin => 'login.error_invalid',
        LoginResult.rateLimited => 'login.error_rate_limited',
        _ => 'login.error_failed',
      };
    });
    _shake.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.watch<I18n>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Material(
        color: Colors.white,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Spacer(),
                        const Text(
                          'JUBL(A)PP',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 25),
                        Text(
                          i18n.t('login.greeting'),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 25),
                        Text(
                          i18n.t('login.group_name'),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 50),
                        AnimatedBuilder(
                          animation: _shake,
                          builder: (context, child) {
                            final t = _shake.value;
                            final dx = t == 0 || t == 1
                                ? 0.0
                                : (t < 0.33
                                      ? -5.0
                                      : (t < 0.66 ? 5.0 : -5.0));
                            return Transform.translate(
                              offset: Offset(dx, 0),
                              child: child,
                            );
                          },
                          child: _LoginForm(
                            controller: _pin,
                            busy: _busy,
                            error: _error,
                            onSubmit: _submit,
                            placeholder: i18n.t('login.pin_placeholder'),
                            buttonLabel: i18n.t('login.submit'),
                          ),
                        ),
                        if (_error && _errorKey.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                i18n.t(_errorKey),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ),
                        const Spacer(),
                        const _Footer(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.controller,
    required this.busy,
    required this.error,
    required this.onSubmit,
    required this.placeholder,
    required this.buttonLabel,
  });

  final TextEditingController controller;
  final bool busy;
  final bool error;
  final VoidCallback onSubmit;
  final String placeholder;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    final borderColor = error ? Colors.red : AppColors.primary;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: borderColor, width: 2),
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: FractionallySizedBox(
          widthFactor: 0.8,
          child: Column(
            children: [
              TextField(
                key: const Key('pin-field'),
                controller: controller,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => onSubmit(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: placeholder,
                  hintStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF9E9E9E),
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 15, right: 5),
                    child: FaIcon(
                      FontAwesomeIcons.key,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 40),
                  suffixIcon: const SizedBox(width: 40),
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  border: border,
                  enabledBorder: border,
                  focusedBorder: border,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('login-button'),
                  onPressed: busy ? null : onSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.8,
                    ),
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          buttonLabel.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final i18n = context.watch<I18n>();
    return Column(
      children: [
        const LangSwitcher(dark: true),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          children: [
            _FooterLink(
              label: i18n.t('common.handbook'),
              url: AppConfig.handbookUrl,
            ),
            _FooterLink(
              label: i18n.t('common.privacy'),
              url: AppConfig.privacyUrl,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          i18n.t('common.developed_by'),
          style: const TextStyle(fontSize: 13, color: AppColors.textDark),
        ),
        const SizedBox(height: 15),
        Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.read<UrlOpener>().open(
                  Uri.parse(AppConfig.changelogUrl),
                ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 4),
              child: Text(
                'Version ${AppConfig.version}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          context.read<UrlOpener>().open(Uri.parse(url), sameTab: true),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textDark,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

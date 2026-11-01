import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../i18n/i18n.dart';
import '../router.dart';
import '../services/platform_services.dart';
import '../theme.dart';
import '../widgets/menu_widgets.dart';
import '../widgets/page_scaffold.dart';

class LinksScreen extends StatefulWidget {
  const LinksScreen({super.key});

  @override
  State<LinksScreen> createState() => _LinksScreenState();
}

enum _ConfigState { loading, ready, failed }

class _LinksScreenState extends State<LinksScreen> {
  bool _emergencyOpen = false;
  _ConfigState _configState = _ConfigState.loading;
  String _scharEmail = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadConfig());
  }

  Future<void> _loadConfig() async {
    final service = context.read<ConfigService>();
    try {
      final config = await service.load();
      if (!mounted) return;
      setState(() {
        _scharEmail = config.scharEmail;
        _configState = _ConfigState.ready;
      });
    } catch (e) {
      // 401/403 → ApiClient meldet ab, der Router leitet zum Login.
      debugPrint('${context.i18n.t('links.error_config')} $e');
      if (mounted) setState(() => _configState = _ConfigState.failed);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openWeb(String url) async {
    final opened = await context.read<UrlOpener>().open(Uri.parse(url));
    if (!opened && mounted) _toast(context.i18n.t('common.open_failed'));
  }

  Future<void> _openHandbook() async {
    final opened = await context.read<UrlOpener>().open(
      Uri.parse(AppConfig.handbookUrl),
      sameTab: true,
    );
    if (!opened && mounted) _toast(context.i18n.t('common.open_failed'));
  }

  Future<void> _mailToSchar() async {
    final i18n = context.i18n;
    final opened = await context.read<UrlOpener>().open(
      Uri(scheme: 'mailto', path: _scharEmail),
    );
    if (opened) return;
    // Kein Mail-Programm (z. B. Windows ohne Standard-App): Adresse kopieren.
    await Clipboard.setData(ClipboardData(text: _scharEmail));
    if (mounted) _toast(i18n.t('links.email_copied', {'email': _scharEmail}));
  }

  Future<void> _confirmCall(String tel, String display) async {
    final i18n = context.i18n;
    final opener = context.read<UrlOpener>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _CallDialog(phone: display),
    );
    if (confirmed != true) return;
    final opened = await opener.open(Uri(scheme: 'tel', path: tel));
    if (opened) return;
    // Geräte ohne Telefon-App (Windows, manche Browser): Nummer kopieren.
    await Clipboard.setData(ClipboardData(text: display));
    if (mounted) _toast(i18n.t('links.phone_copied', {'phone': display}));
  }

  @override
  Widget build(BuildContext context) {
    final emailSubtitle = switch (_configState) {
      _ConfigState.loading => context.t('links.loading'),
      _ =>
        _scharEmail.isNotEmpty
            ? _scharEmail
            : context.t('links.not_configured'),
    };
    return PageScaffold(
      title: context.t('links.title'),
      leadingTooltip: context.t('common.close'),
      onLeading: () => context.go(Routes.overview),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: const Key('emergency-toggle'),
            onTap: () => setState(() => _emergencyOpen = !_emergencyOpen),
            child: Semantics(
              expanded: _emergencyOpen,
              child: SectionTitle(
                context.t('links.section_emergency'),
                trailing: AnimatedRotation(
                  turns: _emergencyOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: const FaIcon(
                    FontAwesomeIcons.chevronDown,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
          if (_emergencyOpen)
            MenuGrid(
              children: [
                MenuCard(
                  key: const Key('call-zh'),
                  emergency: true,
                  icon: FontAwesomeIcons.phone,
                  label: context.t('links.jubla_zh_crisis'),
                  sublabel: '0800 505 202',
                  onTap: () => _confirmCall('+41800505202', '0800 505 202'),
                ),
                MenuCard(
                  key: const Key('call-national'),
                  emergency: true,
                  icon: FontAwesomeIcons.phone,
                  label: context.t('links.jubla_national_crisis'),
                  sublabel: '079 259 76 90',
                  onTap: () => _confirmCall('+41792597690', '079 259 76 90'),
                ),
              ],
            ),
          SectionTitle(context.t('links.section_websites')),
          MenuGrid(
            children: [
              _webCard(
                context.t('links.jubla_wald'),
                'jubla-wald.ch',
                'https://jubla-wald.ch',
              ),
              _webCard(
                context.t('links.jubla_zh'),
                'jublazueri.ch',
                'https://jublazueri.ch',
              ),
              _webCard(
                context.t('links.jubla_ch'),
                'jubla.ch',
                'https://www.jubla.ch',
              ),
              _webCard(
                context.t('links.ecamp'),
                'ecamp3.ch',
                'https://app.ecamp3.ch/',
              ),
            ],
          ),
          SectionTitle(context.t('links.section_contact')),
          ListBlock(
            children: [
              ListBlockItem(
                icon: FontAwesomeIcons.book,
                title: context.t('links.handbook'),
                subtitle: context.t('links.handbook_subtitle'),
                onTap: _openHandbook,
              ),
              ListBlockItem(
                icon: FontAwesomeIcons.envelope,
                title: context.t('links.schar_email'),
                subtitle: emailSubtitle,
                onTap: () {
                  if (_scharEmail.isNotEmpty) _mailToSchar();
                },
              ),
              ListBlockItem(
                icon: FontAwesomeIcons.commentDots,
                title: context.t('links.feedback'),
                subtitle: context.t('links.feedback_subtitle'),
                onTap: () => context.push(Routes.feedback),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _webCard(String label, String sublabel, String url) => MenuCard(
    icon: FontAwesomeIcons.arrowUpRightFromSquare,
    label: label,
    sublabel: sublabel,
    onTap: () => _openWeb(url),
  );
}

class _CallDialog extends StatelessWidget {
  const _CallDialog({required this.phone});
  final String phone;

  @override
  Widget build(BuildContext context) {
    const marker = '\u0000';
    // Text enthält {phone}; die Nummer wird fett hervorgehoben.
    final parts = context
        .t('links.dialog_text', {'phone': marker})
        .split(marker);
    return AlertDialog(
      key: const Key('call-dialog'),
      title: Text(context.t('links.dialog_title')),
      content: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: parts.first),
            if (parts.length > 1) ...[
              TextSpan(
                text: phone,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: parts.skip(1).join(marker)),
            ],
          ],
        ),
        style: const TextStyle(height: 1.5, color: AppColors.textDark),
      ),
      actions: [
        TextButton(
          key: const Key('call-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFFEEEEEE),
            foregroundColor: AppColors.textDark,
          ),
          child: Text(context.t('links.dialog_cancel')),
        ),
        FilledButton(
          key: const Key('call-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text(context.t('links.dialog_confirm')),
        ),
      ],
    );
  }
}

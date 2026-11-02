import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../i18n/i18n.dart';
import '../router.dart';
import '../services/platform_services.dart';
import '../theme.dart';
import '../widgets/embedded_page.dart';
import '../widgets/page_scaffold.dart';

/// Lager-Seite: Padlet im Web eingebettet, auf Android/Windows als Link.
class LagerScreen extends StatelessWidget {
  const LagerScreen({super.key});

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.i18n.t('common.open_failed');
    final opened = await context.read<UrlOpener>().open(
      Uri.parse(AppConfig.padletUrl),
    );
    if (!opened) messenger.showSnackBar(SnackBar(content: Text(failed)));
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: context.t('lager.title'),
      leadingTooltip: context.t('common.close'),
      onLeading: () => context.go(Routes.overview),
      fillBody: embedSupported,
      padBody: !embedSupported,
      body: embedSupported
          ? buildEmbed(AppConfig.padletUrl)
          : Column(
              children: [
                Text(
                  context.t('lager.native_hint'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('lager-open'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () => _open(context),
                  icon: const FaIcon(
                    FontAwesomeIcons.upRightFromSquare,
                    size: 16,
                  ),
                  label: Text(context.t('lager.open_btn')),
                ),
              ],
            ),
    );
  }
}

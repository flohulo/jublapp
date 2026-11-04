import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/i18n.dart';
import '../theme.dart';

/// DE | GSW | FR | IT | EN – wechselt die Sprache sofort (ohne Neuladen).
class LangSwitcher extends StatelessWidget {
  const LangSwitcher({super.key, this.dark = false});

  /// `true` für helle Hintergründe (Login), sonst weiss auf Rot.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final i18n = context.watch<I18n>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final lang in I18n.supported)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _LangButton(
              lang: lang,
              active: lang == i18n.lang,
              dark: dark,
              onTap: () => context.read<I18n>().setLanguage(lang),
            ),
          ),
      ],
    );
  }
}

class _LangButton extends StatelessWidget {
  const _LangButton({
    required this.lang,
    required this.active,
    required this.dark,
    required this.onTap,
  });

  final String lang;
  final bool active;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    final Color border;
    if (dark) {
      background = active ? AppColors.primary : const Color(0xFFF0F0F0);
      foreground = active ? Colors.white : AppColors.textDark;
      border = active ? AppColors.primary : const Color(0xFFCCCCCC);
    } else {
      background = active ? Colors.white : Colors.white24;
      foreground = active ? AppColors.primary : Colors.white;
      border = active ? Colors.white : Colors.white54;
    }
    return Semantics(
      button: true,
      selected: active,
      label: 'Language: $lang',
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 32, minHeight: 28),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            lang.toUpperCase(),
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: active ? FontWeight.w800 : FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

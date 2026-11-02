import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme.dart';
import 'lang_switcher.dart';

/// Rahmen jeder Seite: rote Kopfzeile mit Titel, Sprachwahl und Inhalt in
/// einer zentrierten Spalte (wie `.mobile-container` der PWA).
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.leadingIcon = FontAwesomeIcons.xmark,
    this.leadingTooltip,
    this.onLeading,
    this.action,
    this.showLangSwitcher = true,
    this.padBody = false,
    this.fillBody = false,
    this.backgroundColor = AppColors.bgInner,
  });

  final String title;
  final Widget body;
  final FaIconData leadingIcon;
  final String? leadingTooltip;
  final VoidCallback? onLeading;
  final Widget? action;
  final bool showLangSwitcher;
  final bool padBody;

  /// Body füllt den restlichen Platz (ohne Scrollen), z. B. für eingebettete
  /// Seiten.
  final bool fillBody;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.primary,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bgOuter,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTheme.maxContentWidth,
            ),
            child: Material(
              color: backgroundColor,
              elevation: 4,
              shadowColor: Colors.black26,
              child: Column(
                children: [
                  _Header(
                    title: title,
                    leadingIcon: leadingIcon,
                    leadingTooltip: leadingTooltip,
                    onLeading: onLeading,
                    action: action,
                  ),
                  if (showLangSwitcher)
                    const ColoredBox(
                      color: AppColors.primary,
                      child: SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 6),
                          child: LangSwitcher(),
                        ),
                      ),
                    ),
                  Expanded(
                    child: SafeArea(
                      top: false,
                      child: fillBody
                          ? SizedBox.expand(child: body)
                          : SingleChildScrollView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: padBody
                                  ? const EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 20,
                                    )
                                  : EdgeInsets.zero,
                              child: SizedBox(
                                width: double.infinity,
                                child: body,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.leadingIcon,
    this.leadingTooltip,
    this.onLeading,
    this.action,
  });

  final String title;
  final FaIconData leadingIcon;
  final String? leadingTooltip;
  final VoidCallback? onLeading;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: onLeading == null
                      ? null
                      : IconButton(
                          tooltip: leadingTooltip,
                          onPressed: onLeading,
                          icon: FaIcon(
                            leadingIcon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                ),
                Expanded(
                  child: Text(
                    'JUBL(A)PP\n$title',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ),
                SizedBox(width: 48, height: 48, child: action),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Weisses Symbol-Icon für die Kopfzeile (z. B. Speichern-Haken).
class HeaderAction extends StatelessWidget {
  const HeaderAction({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 24,
    this.spinning = false,
  });

  final FaIconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = FaIcon(icon, color: Colors.white, size: size);
    if (spinning) iconWidget = _Spin(child: iconWidget);
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      disabledColor: Colors.white54,
      icon: iconWidget,
    );
  }
}

class _Spin extends StatefulWidget {
  const _Spin({required this.child});
  final Widget child;

  @override
  State<_Spin> createState() => _SpinState();
}

class _SpinState extends State<_Spin> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RotationTransition(turns: _controller, child: widget.child);
}

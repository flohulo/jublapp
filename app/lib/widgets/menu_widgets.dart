import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme.dart';

/// Quadratische rote Kachel mit Beschriftung (`.card` + `.card-label`).
class MenuCard extends StatelessWidget {
  const MenuCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.sublabel,
    this.emergency = false,
  });

  final FaIconData icon;
  final String label;
  final String? sublabel;
  final VoidCallback onTap;
  final bool emergency;

  @override
  Widget build(BuildContext context) {
    final color = emergency ? AppColors.emergency : AppColors.primary;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Semantics(
            button: true,
            label: label,
            child: Material(
              color: color,
              borderRadius: BorderRadius.circular(12),
              elevation: 3,
              shadowColor: Colors.black26,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: FaIcon(icon, color: Colors.white, size: 40),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        // Auch die Beschriftung ist antippbar (grössere Trefferfläche).
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        if (sublabel != null) ...[
          const SizedBox(height: 2),
          Text(
            sublabel!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Color(0xFF555555)),
          ),
        ],
      ],
    );
  }
}

/// Zwei Kacheln pro Zeile (`.grid-container`).
class MenuGrid extends StatelessWidget {
  const MenuGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 15.0;
          final width = (constraints.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final child in children)
                SizedBox(width: width, child: child),
            ],
          );
        },
      ),
    );
  }
}

/// Überschrift mit Linie darunter (`.section-title`).
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 20, 15, 0),
      padding: const EdgeInsets.only(bottom: 5),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFCCCCCC), width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Weisser Block mit Einträgen (`.list-block`).
class ListBlock extends StatelessWidget {
  const ListBlock({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: AppColors.divider),
            children[i],
          ],
        ],
      ),
    );
  }
}

class ListBlockItem extends StatelessWidget {
  const ListBlockItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final FaIconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 15),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: FaIcon(icon, color: Colors.white, size: 18)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

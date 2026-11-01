import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../i18n/i18n.dart';
import '../router.dart';
import '../widgets/menu_widgets.dart';
import '../widgets/page_scaffold.dart';

class GruppenstundeScreen extends StatelessWidget {
  const GruppenstundeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: context.t('gruppenstunde.title'),
      leadingTooltip: context.t('common.close'),
      onLeading: () => context.go(Routes.overview),
      body: MenuGrid(
        children: [
          MenuCard(
            icon: FontAwesomeIcons.handFist,
            label: context.t('gruppenstunde.card_strike'),
            onTap: () => context.push(Routes.strike),
          ),
          MenuCard(
            icon: FontAwesomeIcons.triangleExclamation,
            label: context.t('gruppenstunde.card_ereignis'),
            onTap: () => context.push(Routes.ereignis),
          ),
          MenuCard(
            icon: FontAwesomeIcons.cloudSun,
            label: context.t('gruppenstunde.card_wetter'),
            onTap: () => context.push(Routes.weather),
          ),
        ],
      ),
    );
  }
}

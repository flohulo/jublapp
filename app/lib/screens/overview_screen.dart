import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../i18n/i18n.dart';
import '../router.dart';
import '../services/auth_service.dart';
import '../widgets/menu_widgets.dart';
import '../widgets/page_scaffold.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: context.t('uebersicht.title'),
      leadingIcon: FontAwesomeIcons.rightFromBracket,
      leadingTooltip: context.t('common.logout'),
      onLeading: () async {
        final auth = context.read<AuthService>();
        final router = GoRouter.of(context);
        await auth.logout();
        router.go(Routes.login);
      },
      body: MenuGrid(
        children: [
          MenuCard(
            icon: FontAwesomeIcons.peopleGroup,
            label: context.t('uebersicht.card_gruppenstunde'),
            onTap: () => context.push(Routes.groupHour),
          ),
          MenuCard(
            icon: FontAwesomeIcons.link,
            label: context.t('uebersicht.card_links'),
            onTap: () => context.push(Routes.links),
          ),
          MenuCard(
            icon: FontAwesomeIcons.campground,
            label: context.t('uebersicht.card_lager'),
            onTap: () => context.push(Routes.lager),
          ),
        ],
      ),
    );
  }
}

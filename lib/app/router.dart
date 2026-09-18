import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/player/player_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/topic/topic_screen.dart';
import '../ui/widgets/bottom_nav.dart';

abstract final class Routes {
  static const home = '/home';
  static const profile = '/profile';
  static const settings = '/settings';
  static String topic(String topicId) => '/topic/$topicId';
  static String player(String passageId) => '/player/$passageId';
}

final appRouter = GoRouter(
  initialLocation: Routes.home,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _ShellScaffold(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.home,
              builder: (context, state) => HomeScreen(
                onOpenTopic: (topicId) => context.push(Routes.topic(topicId)),
                onOpenPassage: (passageId) =>
                    context.push(Routes.player(passageId)),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.profile,
              builder: (context, state) => ProfileScreen(
                onOpenPassage: (passageId) =>
                    context.push(Routes.player(passageId)),
                onOpenSettings: () => context.push(Routes.settings),
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: Routes.settings,
      builder: (context, state) => SettingsScreen(onBack: () => context.pop()),
    ),
    GoRoute(
      path: '/topic/:topicId',
      builder: (context, state) => TopicScreen(
        topicId: state.pathParameters['topicId']!,
        onBack: () => context.pop(),
        onOpenPassage: (passageId) => context.push(Routes.player(passageId)),
      ),
    ),
    GoRoute(
      path: '/player/:passageId',
      builder: (context, state) => PlayerScreen(
        passageId: state.pathParameters['passageId']!,
      ),
    ),
  ],
);

class _ShellScaffold extends StatelessWidget {
  const _ShellScaffold({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: shell,
      bottomNavigationBar: EchoraBottomNav(
        currentIndex: shell.currentIndex,
        onSelect: (index) => shell.goBranch(
          index,
          initialLocation: index == shell.currentIndex,
        ),
      ),
    );
  }
}

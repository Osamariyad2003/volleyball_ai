import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai_chat/presentation/screens/ai_chat_screen.dart';
import '../../../../injection_container.dart' as di;
import '../../../matches/data/repositories/matches_repository.dart';
import '../../../matches/presentation/pages/matches_overview_page.dart';
import '../../../tournaments/data/repositories/competition_repository.dart';
import '../../../tournaments/presentation/pages/competitions_page.dart';
import '../../../tutorials/presentation/screens/tutorials_page.dart';
import '../../../voice_coach/application/providers.dart';
import '../../../voice_coach/presentation/screens/coach_welcome_screen.dart';
import '../../../voice_coach/presentation/screens/live_coaching_screen.dart';
import '../../../voice_coach/presentation/screens/match_setup_screen.dart';
import '../providers/navigation_providers.dart';

class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(mainNavigationIndexProvider);
    final compactNav = MediaQuery.sizeOf(context).width < 430;
    const tabs = [
      _VoiceCoachHomeTab(),
      AiChatScreen(),
      _CompetitionsTab(),
      _MatchesTab(),
      TutorialsPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: tabs),
      bottomNavigationBar: NavigationBar(
        height: compactNav ? 68 : null,
        labelBehavior: compactNav
            ? NavigationDestinationLabelBehavior.onlyShowSelected
            : NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          ref.read(mainNavigationIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: _CoachNavIcon(),
            selectedIcon: _CoachNavIcon(isSelected: true),
            label: 'Coach',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_rounded),
            selectedIcon: Icon(Icons.auto_awesome_rounded),
            label: 'Exercises',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_rounded),
            selectedIcon: Icon(Icons.emoji_events_rounded),
            label: 'Competitions',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_score_rounded),
            selectedIcon: Icon(Icons.sports_score_rounded),
            label: 'Matches',
          ),
          NavigationDestination(
            icon: Icon(Icons.ondemand_video_rounded),
            selectedIcon: Icon(Icons.ondemand_video_rounded),
            label: 'Tutorials',
          ),
        ],
      ),
    );
  }
}

class _CoachNavIcon extends StatelessWidget {
  const _CoachNavIcon({this.isSelected = false});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 34,
      width: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.18)
            : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.28),
          width: isSelected ? 1.6 : 1.1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Icon(
        Icons.sports_volleyball_rounded,
        size: 18,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _VoiceCoachHomeTab extends ConsumerWidget {
  const _VoiceCoachHomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(matchSessionProvider);
    final hasSeenCoachWelcome = ref.watch(
      settingsProvider.select((settings) => settings.hasSeenCoachWelcome),
    );
    if (session == null) {
      if (!hasSeenCoachWelcome) {
        return const CoachWelcomeScreen();
      }
      return const MatchSetupScreen();
    }
    return const LiveCoachingScreen();
  }
}

class _CompetitionsTab extends StatelessWidget {
  const _CompetitionsTab();

  @override
  Widget build(BuildContext context) {
    if (!di.sl.isRegistered<CompetitionRepository>()) {
      return const _ApiUnavailableView(title: 'Competitions');
    }

    return const CompetitionsPage();
  }
}

class _MatchesTab extends StatelessWidget {
  const _MatchesTab();

  @override
  Widget build(BuildContext context) {
    final hasMatchesDependencies =
        di.sl.isRegistered<CompetitionRepository>() &&
        di.sl.isRegistered<MatchesRepository>();
    if (!hasMatchesDependencies) {
      return const _ApiUnavailableView(title: 'Matches');
    }

    return const MatchesOverviewPage();
  }
}

class _ApiUnavailableView extends StatelessWidget {
  const _ApiUnavailableView({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.key_off_rounded,
                    size: 44,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$title is unavailable right now.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Add SPORTRADAR_API_KEY to .env and restart the app to load competition data.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
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

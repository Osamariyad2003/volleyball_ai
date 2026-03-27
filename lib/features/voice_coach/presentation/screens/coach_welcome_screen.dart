import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';

class CoachWelcomeScreen extends ConsumerStatefulWidget {
  const CoachWelcomeScreen({super.key});

  @override
  ConsumerState<CoachWelcomeScreen> createState() => _CoachWelcomeScreenState();
}

class _CoachWelcomeScreenState extends ConsumerState<CoachWelcomeScreen> {
  late final PageController _pageController;
  int _pageIndex = 0;

  static const _pages = [
    _CoachWelcomePageData(
      icon: Icons.record_voice_over_rounded,
      title: 'Your Bench-Side Coach',
      description:
          'Track the match live, ask tactical questions in plain language, and get fast coaching cues without leaving the court.',
      bullets: [
        'Live coaching answers during rallies',
        'Voice playback for quick bench communication',
        'One place for setup, scouting, and chat',
      ],
    ),
    _CoachWelcomePageData(
      icon: Icons.center_focus_strong_rounded,
      title: 'Scout Live And Replay',
      description:
          'Capture live frames or upload a replay clip, then scout the current frame for spacing, blocker shape, and defensive seams.',
      bullets: [
        'Live camera scouting during the match',
        'Upload saved video and scout replay frames',
        'Log replay events while the clip plays',
      ],
    ),
    _CoachWelcomePageData(
      icon: Icons.dashboard_customize_rounded,
      title: 'Set Up Before You Scout',
      description:
          'Start with match setup, choose your coaching voice, set the teams, and move straight into the scouting workspace.',
      bullets: [
        'Create the match in a few taps',
        'Adjust rotation and score as you go',
        'Open tactical board, history, and tutorials anytime',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _pageIndex == _pages.length - 1;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF07131B),
              theme.colorScheme.primary.withValues(alpha: 0.18),
              const Color(0xFF09202A),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _finishWelcome,
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Coach Setup',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'A quick walkthrough before you build the match and start scouting.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _pageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return _CoachWelcomeCard(page: page);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _pageIndex == index ? 26 : 8,
                      decoration: BoxDecoration(
                        color: _pageIndex == index
                            ? theme.colorScheme.secondary
                            : Colors.white.withValues(alpha: 0.26),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    if (_pageIndex > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOut,
                            );
                          },
                          child: const Text('Back'),
                        ),
                      ),
                    if (_pageIndex > 0) const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: isLastPage
                            ? _finishWelcome
                            : () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 240),
                                  curve: Curves.easeOut,
                                );
                              },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(isLastPage ? 'Set Up To Scout' : 'Next'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _finishWelcome() async {
    final settings = ref.read(settingsProvider);
    await ref
        .read(settingsProvider.notifier)
        .save(settings.copyWith(hasSeenCoachWelcome: true));
  }
}

class _CoachWelcomeCard extends StatelessWidget {
  const _CoachWelcomeCard({required this.page});

  final _CoachWelcomePageData page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: const Color(0xFF0B1823),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(page.icon, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 22),
            Text(
              page.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              page.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
            const SizedBox(height: 24),
            ...page.bullets.map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 7),
                      height: 8,
                      width: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        bullet,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Text(
                'Flow: Welcome -> Match Setup -> Live Scout',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachWelcomePageData {
  const _CoachWelcomePageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.bullets,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<String> bullets;
}

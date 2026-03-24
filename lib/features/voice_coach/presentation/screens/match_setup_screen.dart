import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../../tutorials/presentation/screens/tutorials_page.dart';
import 'session_history_screen.dart';
import 'settings_screen.dart';

final _matchSetupSelectedVoiceIdProvider =
    StateProvider.autoDispose<String?>((ref) {
      return null;
    });

final _matchSetupIsSavingProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

class MatchSetupScreen extends ConsumerStatefulWidget {
  const MatchSetupScreen({super.key});

  @override
  ConsumerState<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends ConsumerState<MatchSetupScreen> {
  late final TextEditingController _matchNameController;
  late final TextEditingController _homeController;
  late final TextEditingController _awayController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _matchNameController = TextEditingController(text: 'Friday Night Match');
    _homeController = TextEditingController(text: 'Home');
    _awayController = TextEditingController(text: 'Away');
    ref.read(_matchSetupSelectedVoiceIdProvider.notifier).state =
        settings.voiceId;
  }

  @override
  void dispose() {
    _matchNameController.dispose();
    _homeController.dispose();
    _awayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final hasGeminiApiKey = ref.watch(hasGeminiApiKeyProvider);
    final voicesAsync = ref.watch(availableVoicesProvider);
    final selectedVoiceId = ref.watch(_matchSetupSelectedVoiceIdProvider);
    final isSaving = ref.watch(_matchSetupIsSavingProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.primary.withValues(alpha: 0.16),
              theme.colorScheme.secondary.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              Row(
                children: [
                  _RoundActionButton(
                    icon: Icons.history_rounded,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SessionHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  _RoundActionButton(
                    icon: Icons.ondemand_video_rounded,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TutorialsPage(),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  _RoundActionButton(
                    icon: Icons.tune_rounded,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.95),
                      const Color(0xFF0A4F5A),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 54,
                          width: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.sports_volleyball_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Volleyball AI Voice Coach',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Run live sideline coaching on-device, save every rally in Hive, and let Gemini answer tactical questions in real time.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Match Setup', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _matchNameController,
                        decoration: const InputDecoration(
                          labelText: 'Match name',
                          hintText: 'Regional semifinal',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _homeController,
                        decoration: const InputDecoration(
                          labelText: 'Home team',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _awayController,
                        decoration: const InputDecoration(
                          labelText: 'Away team',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: hasGeminiApiKey
                              ? theme.colorScheme.primary.withValues(
                                  alpha: 0.08,
                                )
                              : theme.colorScheme.secondary.withValues(
                                  alpha: 0.1,
                                ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          hasGeminiApiKey
                              ? 'Gemini key loaded from .env'
                              : 'No Gemini key found. Add GEMINI_API_KEY to the project .env file.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                      voicesAsync.when(
                        data: (voices) {
                          final theme = Theme.of(context);
                          final items = voices.isEmpty
                              ? [
                                  DropdownMenuItem<String>(
                                    value: settings.voiceId,
                                    child: Text(
                                      settings.voiceLocale,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ]
                              : voices
                                    .map(
                                      (voice) => DropdownMenuItem<String>(
                                        value: voice.id,
                                        child: Text(
                                          voice.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList();
                          final selected =
                              items.any(
                                (item) => item.value == selectedVoiceId,
                              )
                              ? selectedVoiceId
                              : items.first.value;
                          return DropdownButtonFormField<String>(
                            key: ValueKey(selected),
                            initialValue: selected,
                            isExpanded: true,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                            selectedItemBuilder: (context) {
                              final selectedItems = voices.isEmpty
                                  ? [
                                      settings.voiceLocale,
                                    ]
                                  : voices.map((voice) => voice.label).toList();
                              return selectedItems
                                  .map(
                                    (label) => Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                      ),
                                    ),
                                  )
                                  .toList();
                            },
                            decoration: const InputDecoration(
                              labelText: 'Coaching voice',
                              contentPadding: EdgeInsets.fromLTRB(
                                18,
                                20,
                                18,
                                16,
                              ),
                            ),
                            items: items,
                            onChanged: (value) {
                              ref
                                  .read(
                                    _matchSetupSelectedVoiceIdProvider.notifier,
                                  )
                                  .state = value;
                            },
                          );
                        },
                        loading: () =>
                            const LinearProgressIndicator(minHeight: 2),
                        error: (error, stackTrace) =>
                            const Text('Device voices unavailable right now.'),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: isSaving ? null : _handleStart,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: isSaving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Start Coaching'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleStart() async {
    final matchName = _matchNameController.text.trim();
    final home = _homeController.text.trim();
    final away = _awayController.text.trim();

    if (matchName.isEmpty || home.isEmpty || away.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add the match name and both team names.'),
        ),
      );
      return;
    }

    ref.read(_matchSetupIsSavingProvider.notifier).state = true;

    final currentSettings = ref.read(settingsProvider);
    final voice = ref.read(_matchSetupSelectedVoiceIdProvider) ??
        currentSettings.voiceId;
    final parts = voice.split('::');
    final nextSettings = currentSettings.copyWith(
      voiceLocale: parts.isNotEmpty ? parts.first : currentSettings.voiceLocale,
      voiceName: parts.length > 1 ? parts[1] : currentSettings.voiceName,
    );

    await ref.read(coachControllerProvider).saveSettings(nextSettings);
    await ref
        .read(coachControllerProvider)
        .createMatch(matchName: matchName, homeTeam: home, awayTeam: away);

    ref.read(_matchSetupIsSavingProvider.notifier).state = false;
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon),
      ),
    );
  }
}

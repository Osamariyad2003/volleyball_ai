import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../data/models/coach_models.dart';

final _settingsSelectedVoiceIdProvider = StateProvider.autoDispose<String?>((
  ref,
) {
  return null;
});

final _settingsSpeechRateProvider = StateProvider.autoDispose<double?>((ref) {
  return null;
});

final _settingsAutoSpeakProvider = StateProvider.autoDispose<bool?>((ref) {
  return null;
});

final _settingsThemePreferenceProvider =
    StateProvider.autoDispose<AppThemePreference?>((ref) {
      return null;
    });

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    ref.read(_settingsSelectedVoiceIdProvider.notifier).state = settings.voiceId;
    ref.read(_settingsSpeechRateProvider.notifier).state = settings.speechRate;
    ref.read(_settingsAutoSpeakProvider.notifier).state = settings.autoSpeak;
    ref.read(_settingsThemePreferenceProvider.notifier).state =
        settings.themePreference;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final hasGeminiApiKey = ref.watch(hasGeminiApiKeyProvider);
    final voicesAsync = ref.watch(availableVoicesProvider);
    final selectedVoiceId = ref.watch(_settingsSelectedVoiceIdProvider);
    final speechRate = ref.watch(_settingsSpeechRateProvider);
    final autoSpeak = ref.watch(_settingsAutoSpeakProvider);
    final themePreference = ref.watch(_settingsThemePreferenceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gemini & Voice',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: hasGeminiApiKey
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.08)
                          : Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      hasGeminiApiKey
                          ? 'Gemini is configured from the root .env file.'
                          : 'Gemini is not configured. Add GEMINI_API_KEY to .env, then restart the app.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  voicesAsync.when(
                    data: (voices) {
                      final theme = Theme.of(context);
                      final items = voices
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
                          items.any((item) => item.value == selectedVoiceId)
                          ? selectedVoiceId
                          : (items.isEmpty
                                ? settings.voiceId
                                : items.first.value);
                      return DropdownButtonFormField<String>(
                        key: ValueKey(selected),
                        initialValue: selected,
                        items: items.isEmpty
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
                            : items,
                        isExpanded: true,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        selectedItemBuilder: (context) {
                          final selectedItems = items.isEmpty
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
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              )
                              .toList();
                        },
                        decoration: InputDecoration(
                          labelText: 'TTS voice',
                          contentPadding: const EdgeInsets.fromLTRB(
                            18,
                            20,
                            18,
                            16,
                          ),
                        ),
                        onChanged: (value) {
                          ref
                              .read(_settingsSelectedVoiceIdProvider.notifier)
                              .state = value;
                        },
                      );
                    },
                    loading: () => const LinearProgressIndicator(minHeight: 2),
                    error: (error, stackTrace) =>
                        const Text('Unable to load device voices.'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Speech rate ${(speechRate ?? settings.speechRate).toStringAsFixed(2)}',
                  ),
                  Slider(
                    value: speechRate ?? settings.speechRate,
                    min: 0.35,
                    max: 0.7,
                    divisions: 7,
                    onChanged: (value) {
                      ref.read(_settingsSpeechRateProvider.notifier).state =
                          value;
                    },
                  ),
                  SwitchListTile.adaptive(
                    value: autoSpeak ?? settings.autoSpeak,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Auto-speak responses and alerts'),
                    onChanged: (value) {
                      ref.read(_settingsAutoSpeakProvider.notifier).state =
                          value;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 14),
                  SegmentedButton<AppThemePreference>(
                    segments: const [
                      ButtonSegment(
                        value: AppThemePreference.dark,
                        label: Text('Dark'),
                      ),
                      ButtonSegment(
                        value: AppThemePreference.light,
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: AppThemePreference.system,
                        label: Text('System'),
                      ),
                    ],
                    selected: {themePreference ?? settings.themePreference},
                    onSelectionChanged: (selection) {
                      ref
                          .read(_settingsThemePreferenceProvider.notifier)
                          .state = selection.first;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () async {
              final current = ref.read(settingsProvider);
              final parts = (selectedVoiceId ?? current.voiceId).split('::');
              final updated = current.copyWith(
                voiceLocale: parts.isNotEmpty
                    ? parts.first
                    : current.voiceLocale,
                voiceName: parts.length > 1 ? parts[1] : current.voiceName,
                speechRate: speechRate ?? current.speechRate,
                autoSpeak: autoSpeak ?? current.autoSpeak,
                themePreference: themePreference ?? current.themePreference,
              );
              await ref.read(coachControllerProvider).saveSettings(updated);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../../application/providers.dart';
import '../../data/models/coach_models.dart';
import '../widgets/scouting_overlay.dart';

class PostMatchScreen extends ConsumerStatefulWidget {
  const PostMatchScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<PostMatchScreen> createState() => _PostMatchScreenState();
}

class _PostMatchScreenState extends ConsumerState<PostMatchScreen> {
  late final TextEditingController _weaknessController;
  VideoPlayerController? _scoutingVideoController;
  List<ScoutingEvent> _scoutingEvents = const [];
  bool _isLoadingScoutingVideo = false;
  String? _scoutingVideoError;

  @override
  void initState() {
    super.initState();
    _weaknessController = TextEditingController();
  }

  @override
  void dispose() {
    _scoutingVideoController?.dispose();
    _weaknessController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(coachControllerProvider);
    final session = controller.findSession(widget.sessionId);
    final activeSession = ref.watch(matchSessionProvider);

    if (session == null) {
      return const Scaffold(body: Center(child: Text('Session not found.')));
    }

    final pointBreakdown = <String, int>{};
    for (final rally in session.rallies) {
      final key = rally.pointType ?? 'unknown';
      pointBreakdown[key] = (pointBreakdown[key] ?? 0) + 1;
    }

    final momentumSpots = <FlSpot>[];
    var difference = 0;
    for (var i = 0; i < session.rallies.length; i++) {
      final rally = session.rallies[i];
      difference += rally.winner == 'home' ? 1 : -1;
      momentumSpots.add(FlSpot(i.toDouble(), difference.toDouble()));
    }

    final latestDebrief = session.conversation.lastWhere(
      (message) => message.mode == 'debrief',
      orElse: () => ChatMessage(
        id: 'none',
        role: 'ai',
        text: 'Play a debrief to generate a spoken match summary.',
        confidence: 0,
        mode: 'debrief',
        followups: const [],
        timestamp: session.createdAt,
      ),
    );

    final rotationMap = <int, List<String>>{};
    for (final rally in session.rallies) {
      rotationMap.putIfAbsent(rally.rotation, () => []).add(rally.winner);
    }
    final dateText = DateFormat('MMM d, y • HH:mm').format(session.createdAt);

    return Scaffold(
      appBar: AppBar(title: const Text('Post-Match Review')),
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
                    session.matchName,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text('${session.homeTeam} vs ${session.awayTeam}'),
                  const SizedBox(height: 6),
                  Text(
                    '$dateText • Final ${session.scoreHome}-${session.scoreAway}',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () async {
                            if (activeSession?.id != session.id) {
                              await ref
                                  .read(coachControllerProvider)
                                  .resumeSession(session);
                            }
                            await ref
                                .read(coachControllerProvider)
                                .playDebrief();
                          },
                          child: const Text('Play Debrief'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            await ref
                                .read(coachControllerProvider)
                                .resumeSession(session);
                            if (context.mounted) {
                              Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst);
                            }
                          },
                          child: const Text('Resume Session'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(latestDebrief.text),
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Match Scouting Replay',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _isLoadingScoutingVideo
                            ? null
                            : _reloadScoutingVideo,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reload Clip'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Replay scouting now starts from uploaded match video in the live coach flow. Open a session and upload a clip there to scout actions and log events.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  _ScoutingReplayPlayer(
                    controller: _scoutingVideoController,
                    isLoading: _isLoadingScoutingVideo,
                    errorMessage: _scoutingVideoError,
                    onTogglePlayback: _togglePlayback,
                    onSeekBack: () => _seekBy(const Duration(seconds: -5)),
                    onSeekForward: () => _seekBy(const Duration(seconds: 5)),
                  ),
                  if (_scoutingVideoController != null &&
                      _scoutingVideoController!.value.isInitialized) ...[
                    const SizedBox(height: 18),
                    ScoutingOverlay(
                      controller: _scoutingVideoController!,
                      activeRotation: session.currentRotation.clamp(1, 6),
                      initialEvents: _scoutingEvents,
                      onRecordEvent: (event) {
                        setState(() {
                          _scoutingEvents = [event, ..._scoutingEvents];
                        });
                      },
                    ),
                  ],
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
                  Text(
                    'Drill Builder',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _weaknessController,
                    decoration: const InputDecoration(
                      labelText: 'Weakness',
                      hintText: 'Serve receive under pressure',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () async {
                      if (activeSession?.id != session.id) {
                        await ref
                            .read(coachControllerProvider)
                            .resumeSession(session);
                      }
                      await ref
                          .read(coachControllerProvider)
                          .buildDrill(_weaknessController.text);
                    },
                    child: const Text('Build Drill'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total rallies',
                  value: '${session.rallies.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Home win rate',
                  value: session.rallies.isEmpty
                      ? '--'
                      : '${((session.rallies.where((r) => r.winner == 'home').length / session.rallies.length) * 100).round()}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Current set',
                  value: '${session.currentSet}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Current rotation',
                  value: '${session.currentRotation}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Momentum Chart',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 220,
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: momentumSpots.isEmpty
                                ? [const FlSpot(0, 0)]
                                : momentumSpots,
                            isCurved: true,
                            barWidth: 3,
                            color: Theme.of(context).colorScheme.primary,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
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
                  Text(
                    'Rotation Win Rate',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(6, (index) {
                    final rotation = index + 1;
                    final rallies = rotationMap[rotation] ?? const <String>[];
                    final wins = rallies
                        .where((winner) => winner == 'home')
                        .length;
                    final percentage = rallies.isEmpty
                        ? 0
                        : ((wins / rallies.length) * 100).round();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 86,
                            child: Text('Rotation $rotation'),
                          ),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('$percentage%'),
                        ],
                      ),
                    );
                  }),
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
                  Text(
                    'Point Type Breakdown',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (pointBreakdown.isEmpty)
                    const Text('No manual point tags were recorded yet.')
                  else
                    ...pointBreakdown.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(entry.key.replaceAll('_', ' ')),
                            ),
                            Text('${entry.value}'),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeScoutingVideo() async {
    setState(() {
      _isLoadingScoutingVideo = false;
      _scoutingVideoError =
          'No replay clip is attached here. Upload a match video from the live coach screen to scout it.';
    });
  }

  Future<void> _reloadScoutingVideo() async {
    if (_scoutingVideoController == null) {
      return;
    }
    await _scoutingVideoController?.pause();
    await _initializeScoutingVideo();
  }

  Future<void> _togglePlayback() async {
    final controller = _scoutingVideoController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _seekBy(Duration delta) async {
    final controller = _scoutingVideoController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final next = controller.value.position + delta;
    final maxPosition = controller.value.duration;
    final safePosition = next < Duration.zero
        ? Duration.zero
        : next > maxPosition
        ? maxPosition
        : next;

    await controller.seekTo(safePosition);
    if (mounted) {
      setState(() {});
    }
  }
}

class _ScoutingReplayPlayer extends StatelessWidget {
  const _ScoutingReplayPlayer({
    required this.controller,
    required this.isLoading,
    required this.errorMessage,
    required this.onTogglePlayback,
    required this.onSeekBack,
    required this.onSeekForward,
  });

  final VideoPlayerController? controller;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onTogglePlayback;
  final VoidCallback onSeekBack;
  final VoidCallback onSeekForward;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final videoController = controller;
    final isReady =
        videoController != null && videoController.value.isInitialized;
    final aspectRatio = isReady && videoController.value.aspectRatio > 0
        ? videoController.value.aspectRatio
        : 16 / 9;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.surfaceContainerHighest,
                    theme.colorScheme.primary.withValues(alpha: 0.14),
                  ],
                ),
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : isReady
                  ? VideoPlayer(videoController)
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          errorMessage ??
                              'The scouting clip could not be loaded right now.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        if (isReady) ...[
          const SizedBox(height: 12),
          VideoProgressIndicator(
            videoController,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: theme.colorScheme.primary,
              bufferedColor: theme.colorScheme.primary.withValues(alpha: 0.24),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onTogglePlayback,
                icon: Icon(
                  videoController.value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                label: Text(videoController.value.isPlaying ? 'Pause' : 'Play'),
              ),
              OutlinedButton.icon(
                onPressed: onSeekBack,
                icon: const Icon(Icons.replay_5_rounded),
                label: const Text('Back 5s'),
              ),
              OutlinedButton.icon(
                onPressed: onSeekForward,
                icon: const Icon(Icons.forward_5_rounded),
                label: const Text('Forward 5s'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}

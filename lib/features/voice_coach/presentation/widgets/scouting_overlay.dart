import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ScoutingEvent {
  const ScoutingEvent({
    required this.symbol,
    required this.timestamp,
    required this.rotation,
    required this.recordedAt,
    this.actionLabel,
  });

  final String symbol;
  final Duration timestamp;
  final int rotation;
  final DateTime recordedAt;
  final String? actionLabel;
}

class ScoutingOverlay extends StatefulWidget {
  const ScoutingOverlay({
    super.key,
    required this.controller,
    required this.activeRotation,
    this.onRecordEvent,
    this.initialEvents = const [],
    this.suggestedActionLabel,
    this.seekPreviewOffset = const Duration(seconds: 3),
    this.logHeight = 260,
  }) : assert(
         activeRotation >= 1 && activeRotation <= 6,
         'activeRotation must be between 1 and 6.',
       );

  final VideoPlayerController controller;
  final int activeRotation;
  final ValueChanged<ScoutingEvent>? onRecordEvent;
  final List<ScoutingEvent> initialEvents;
  final String? suggestedActionLabel;
  final Duration seekPreviewOffset;
  final double logHeight;

  @override
  State<ScoutingOverlay> createState() => _ScoutingOverlayState();
}

class _ScoutingOverlayState extends State<ScoutingOverlay> {
  late final List<ScoutingEvent> _events;

  static const _valuationButtons = <_ScoutingSymbol>[
    _ScoutingSymbol(
      symbol: '#',
      label: 'Point',
      color: Color(0xFF16A34A),
      icon: Icons.emoji_events_rounded,
    ),
    _ScoutingSymbol(
      symbol: '+',
      label: 'Positive',
      color: Color(0xFF2563EB),
      icon: Icons.trending_up_rounded,
    ),
    _ScoutingSymbol(
      symbol: '!',
      label: 'Neutral',
      color: Color(0xFFF59E0B),
      icon: Icons.horizontal_rule_rounded,
    ),
    _ScoutingSymbol(
      symbol: '/',
      label: 'Poor',
      color: Color(0xFFF97316),
      icon: Icons.south_east_rounded,
    ),
    _ScoutingSymbol(
      symbol: '-',
      label: 'Error',
      color: Color(0xFFDC2626),
      icon: Icons.close_rounded,
    ),
    _ScoutingSymbol(
      symbol: '=',
      label: 'Blocked',
      color: Color(0xFF7C3AED),
      icon: Icons.block_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _events = List<ScoutingEvent>.from(widget.initialEvents.reversed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Scouting Panel', style: theme.textTheme.titleLarge),
            const Spacer(),
            _InfoPill(
              label: 'Rotation ${widget.activeRotation}',
              color: theme.colorScheme.primary,
            ),
            if ((widget.suggestedActionLabel ?? '').isNotEmpty) ...[
              const SizedBox(width: 8),
              _InfoPill(
                label: widget.suggestedActionLabel!,
                color: theme.colorScheme.secondary,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Record valuation symbols while the clip plays, then tap any event to jump back three seconds before it.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _valuationButtons.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
          ),
          itemBuilder: (context, index) {
            final entry = _valuationButtons[index];
            return _ScoutingActionButton(
              symbol: entry.symbol,
              label: entry.label,
              icon: entry.icon,
              color: entry.color,
              onPressed: () => _recordEvent(entry.symbol),
            );
          },
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text('Event Log', style: theme.textTheme.titleMedium),
            const Spacer(),
            Text(
              '${_events.length} events',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: widget.logHeight,
          child: _events.isEmpty
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.28,
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No scouting events recorded yet.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: _events.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    final button = _valuationButtons.firstWhere(
                      (item) => item.symbol == event.symbol,
                    );
                    final previewStart = _safePreviewPosition(event.timestamp);
                    return _ScoutingLogTile(
                      event: event,
                      color: button.color,
                      onTap: () => _seekToPreview(event),
                      previewLabel: _formatDuration(previewStart),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _recordEvent(String symbol) {
    final event = ScoutingEvent(
      symbol: symbol,
      timestamp: widget.controller.value.position,
      rotation: widget.activeRotation,
      recordedAt: DateTime.now(),
      actionLabel: widget.suggestedActionLabel,
    );

    setState(() {
      _events.insert(0, event);
    });

    widget.onRecordEvent?.call(event);
  }

  Future<void> _seekToPreview(ScoutingEvent event) async {
    await widget.controller.seekTo(_safePreviewPosition(event.timestamp));
  }

  Duration _safePreviewPosition(Duration eventTime) {
    final target = eventTime - widget.seekPreviewOffset;
    if (target.isNegative) {
      return Duration.zero;
    }
    return target;
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

class _ScoutingSymbol {
  const _ScoutingSymbol({
    required this.symbol,
    required this.label,
    required this.color,
    required this.icon,
  });

  final String symbol;
  final String label;
  final Color color;
  final IconData icon;
}

class _ScoutingActionButton extends StatelessWidget {
  const _ScoutingActionButton({
    required this.symbol,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String symbol;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              symbol,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoutingLogTile extends StatelessWidget {
  const _ScoutingLogTile({
    required this.event,
    required this.color,
    required this.onTap,
    required this.previewLabel,
  });

  final ScoutingEvent event;
  final Color color;
  final VoidCallback onTap;
  final String previewLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 42,
                width: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  event.symbol,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rotation ${event.rotation}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Event at ${_formatDuration(event.timestamp)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if ((event.actionLabel ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        event.actionLabel!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      'Tap to seek to $previewLabel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.replay_rounded, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }
}

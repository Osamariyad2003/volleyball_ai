import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/player_position.dart';
import '../../data/volleyball_court_geometry.dart';
import '../providers/tactical_board_providers.dart';
import '../widgets/volleyball_court_painter.dart';

class TacticalBoardScreen extends ConsumerWidget {
  const TacticalBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tacticalBoardControllerProvider);
    final controller = ref.read(tacticalBoardControllerProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Volleyball Tactical Board')),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF09121D),
              theme.colorScheme.primary.withValues(alpha: 0.14),
              const Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTabletLandscape = constraints.maxWidth >= 980;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _BoardIntroCard(
                    homeCount: state.homePlayers.length,
                    awayCount: state.awayPlayers.length,
                  ),
                  const SizedBox(height: 16),
                  if (isTabletLandscape)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _TeamBoardCard(
                            title: 'Home Rotation',
                            subtitle:
                                'Blue markers rotate clockwise through zones.',
                            team: TacticalTeam.home,
                            players: state.homePlayers,
                            onRotate: controller.rotateHomePlayers,
                            onAddPlayer: (zoneIndex) => _handleAddPlayer(
                              context,
                              ref,
                              team: TacticalTeam.home,
                              zoneIndex: zoneIndex,
                            ),
                            onMovePlayer:
                                ({
                                  required String playerId,
                                  required int zoneIndex,
                                }) {
                                  controller.movePlayer(
                                    team: TacticalTeam.home,
                                    playerId: playerId,
                                    zoneIndex: zoneIndex,
                                  );
                                },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _TeamBoardCard(
                            title: 'Away Matchup',
                            subtitle:
                                'White markers mirror the opponent alignment.',
                            team: TacticalTeam.away,
                            players: state.awayPlayers,
                            onAddPlayer: (zoneIndex) => _handleAddPlayer(
                              context,
                              ref,
                              team: TacticalTeam.away,
                              zoneIndex: zoneIndex,
                            ),
                            onMovePlayer:
                                ({
                                  required String playerId,
                                  required int zoneIndex,
                                }) {
                                  controller.movePlayer(
                                    team: TacticalTeam.away,
                                    playerId: playerId,
                                    zoneIndex: zoneIndex,
                                  );
                                },
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _TeamBoardCard(
                      title: 'Home Rotation',
                      subtitle: 'Blue markers rotate clockwise through zones.',
                      team: TacticalTeam.home,
                      players: state.homePlayers,
                      onRotate: controller.rotateHomePlayers,
                      onAddPlayer: (zoneIndex) => _handleAddPlayer(
                        context,
                        ref,
                        team: TacticalTeam.home,
                        zoneIndex: zoneIndex,
                      ),
                      onMovePlayer:
                          ({required String playerId, required int zoneIndex}) {
                            controller.movePlayer(
                              team: TacticalTeam.home,
                              playerId: playerId,
                              zoneIndex: zoneIndex,
                            );
                          },
                    ),
                    const SizedBox(height: 16),
                    _TeamBoardCard(
                      title: 'Away Matchup',
                      subtitle: 'White markers mirror the opponent alignment.',
                      team: TacticalTeam.away,
                      players: state.awayPlayers,
                      onAddPlayer: (zoneIndex) => _handleAddPlayer(
                        context,
                        ref,
                        team: TacticalTeam.away,
                        zoneIndex: zoneIndex,
                      ),
                      onMovePlayer:
                          ({required String playerId, required int zoneIndex}) {
                            controller.movePlayer(
                              team: TacticalTeam.away,
                              playerId: playerId,
                              zoneIndex: zoneIndex,
                            );
                          },
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handleAddPlayer(
    BuildContext context,
    WidgetRef ref, {
    required TacticalTeam team,
    required int zoneIndex,
  }) async {
    final jerseyNumber = await _showAddPlayerDialog(
      context,
      team: team,
      zoneIndex: zoneIndex,
    );
    if (jerseyNumber == null || !context.mounted) {
      return;
    }

    final message = ref
        .read(tacticalBoardControllerProvider.notifier)
        .addPlayer(
          team: team,
          zoneIndex: zoneIndex,
          jerseyNumber: jerseyNumber,
        );

    if (message != null && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<int?> _showAddPlayerDialog(
    BuildContext context, {
    required TacticalTeam team,
    required int zoneIndex,
  }) async {
    return showDialog<int>(
      context: context,
      builder: (_) => _AddPlayerDialog(team: team, zoneIndex: zoneIndex),
    );
  }
}

class _AddPlayerDialog extends StatefulWidget {
  const _AddPlayerDialog({required this.team, required this.zoneIndex});

  final TacticalTeam team;
  final int zoneIndex;

  @override
  State<_AddPlayerDialog> createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends State<_AddPlayerDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context).pop(int.parse(_controller.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add ${widget.team.name} player to Zone ${widget.zoneIndex}'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Jersey Number',
            hintText: '7',
          ),
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) {
              return 'Enter a jersey number.';
            }
            final parsed = int.tryParse(trimmed);
            if (parsed == null || parsed <= 0) {
              return 'Enter a valid positive number.';
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}

class _BoardIntroCard extends StatelessWidget {
  const _BoardIntroCard({required this.homeCount, required this.awayCount});

  final int homeCount;
  final int awayCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.94),
            const Color(0xFF0F766E),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tactical Board',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap any empty zone to add a player, drag bubbles between zones, and rotate the home lineup in match order.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                label: 'Home $homeCount',
                color: const Color(0xFF2563EB),
                textColor: Colors.white,
              ),
              _InfoChip(
                label: 'Away $awayCount',
                color: const Color(0xFF102235),
                textColor: Colors.white,
              ),
              _InfoChip(
                label: 'Zones 1-6 mapped',
                color: Colors.white.withValues(alpha: 0.14),
                textColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamBoardCard extends StatelessWidget {
  const _TeamBoardCard({
    required this.title,
    required this.subtitle,
    required this.team,
    required this.players,
    required this.onAddPlayer,
    required this.onMovePlayer,
    this.onRotate,
  });

  final String title;
  final String subtitle;
  final TacticalTeam team;
  final List<PlayerPosition> players;
  final ValueChanged<int> onAddPlayer;
  final void Function({required String playerId, required int zoneIndex})
  onMovePlayer;
  final VoidCallback? onRotate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onRotate != null)
                  FilledButton.tonalIcon(
                    onPressed: onRotate,
                    icon: const Icon(Icons.rotate_right_rounded),
                    label: const Text('Rotate'),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _ResponsiveCourtBoard(
              team: team,
              players: players,
              onAddPlayer: onAddPlayer,
              onMovePlayer: onMovePlayer,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsiveCourtBoard extends StatelessWidget {
  const _ResponsiveCourtBoard({
    required this.team,
    required this.players,
    required this.onAddPlayer,
    required this.onMovePlayer,
  });

  final TacticalTeam team;
  final List<PlayerPosition> players;
  final ValueChanged<int> onAddPlayer;
  final void Function({required String playerId, required int zoneIndex})
  onMovePlayer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bubbleSize = constraints.maxWidth >= 480 ? 54.0 : 46.0;
        final playersByZone = {
          for (final player in players) player.zoneIndex: player,
        };

        return AspectRatio(
          aspectRatio: 1.12,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: LayoutBuilder(
              builder: (context, boardConstraints) {
                final boardSize = boardConstraints.biggest;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    const CustomPaint(painter: VolleyballCourtPainter()),
                    const Positioned(
                      top: 12,
                      left: 14,
                      child: _BoardLabel(label: 'Front Row'),
                    ),
                    const Positioned(
                      bottom: 12,
                      left: 14,
                      child: _BoardLabel(label: 'Back Row'),
                    ),
                    for (final zoneIndex in const [4, 3, 2, 5, 6, 1])
                      Positioned.fromRect(
                        rect: VolleyballCourtGeometry.zoneRect(
                          zoneIndex,
                          boardSize,
                        ).deflate(6),
                        child: _ZoneTarget(
                          zoneIndex: zoneIndex,
                          team: team,
                          player: playersByZone[zoneIndex],
                          onAddPlayer: () => onAddPlayer(zoneIndex),
                          onAcceptPlayer: (playerId) {
                            onMovePlayer(
                              playerId: playerId,
                              zoneIndex: zoneIndex,
                            );
                          },
                        ),
                      ),
                    for (final player in players)
                      _PlayerPlacement(
                        team: team,
                        player: player,
                        boardSize: boardSize,
                        bubbleSize: bubbleSize,
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _PlayerPlacement extends StatelessWidget {
  const _PlayerPlacement({
    required this.team,
    required this.player,
    required this.boardSize,
    required this.bubbleSize,
  });

  final TacticalTeam team;
  final PlayerPosition player;
  final Size boardSize;
  final double bubbleSize;

  @override
  Widget build(BuildContext context) {
    final absolute = VolleyballCourtGeometry.denormalize(
      player.position,
      boardSize,
    );
    final bubble = _PlayerBubble(
      jerseyNumber: player.jerseyNumber,
      team: team,
      size: bubbleSize,
    );

    return Positioned(
      left: absolute.dx - (bubbleSize / 2),
      top: absolute.dy - (bubbleSize / 2),
      child: LongPressDraggable<_DraggedPlayer>(
        data: _DraggedPlayer(team: team, playerId: player.id),
        feedback: Material(
          color: Colors.transparent,
          child: _PlayerBubble(
            jerseyNumber: player.jerseyNumber,
            team: team,
            size: bubbleSize,
            elevated: true,
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.28, child: bubble),
        child: bubble,
      ),
    );
  }
}

class _ZoneTarget extends StatelessWidget {
  const _ZoneTarget({
    required this.zoneIndex,
    required this.team,
    required this.player,
    required this.onAddPlayer,
    required this.onAcceptPlayer,
  });

  final int zoneIndex;
  final TacticalTeam team;
  final PlayerPosition? player;
  final VoidCallback onAddPlayer;
  final ValueChanged<String> onAcceptPlayer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DragTarget<_DraggedPlayer>(
      onWillAcceptWithDetails: (details) {
        return details.data.team == team &&
            (player == null || player!.id == details.data.playerId);
      },
      onAcceptWithDetails: (details) {
        onAcceptPlayer(details.data.playerId);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final isEmpty = player == null;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEmpty ? onAddPlayer : null,
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isHovering
                      ? theme.colorScheme.secondary
                      : Colors.white.withValues(alpha: isEmpty ? 0.35 : 0.14),
                  width: isHovering ? 2.2 : 1.2,
                ),
                color: isHovering
                    ? theme.colorScheme.secondary.withValues(alpha: 0.18)
                    : isEmpty
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.transparent,
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'Zone $zoneIndex',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isEmpty)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_circle_outline_rounded,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Add Player',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlayerBubble extends StatelessWidget {
  const _PlayerBubble({
    required this.jerseyNumber,
    required this.team,
    required this.size,
    this.elevated = false,
  });

  final int jerseyNumber;
  final TacticalTeam team;
  final double size;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final isHome = team == TacticalTeam.home;
    final background = isHome
        ? const Color(0xFF2563EB)
        : const Color(0xFF102235);
    final foreground = Colors.white;

    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
        border: Border.all(
          color: isHome
              ? Colors.white.withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: 0.78),
          width: 2,
        ),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Text(
        '$jerseyNumber',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DraggedPlayer {
  const _DraggedPlayer({required this.team, required this.playerId});

  final TacticalTeam team;
  final String playerId;
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BoardLabel extends StatelessWidget {
  const _BoardLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

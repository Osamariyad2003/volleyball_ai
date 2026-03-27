import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/player_position.dart';
import '../../data/volleyball_court_geometry.dart';

const _uuid = Uuid();

enum TacticalTeam { home, away }

class TacticalBoardState {
  const TacticalBoardState({
    required this.homePlayers,
    required this.awayPlayers,
  });

  const TacticalBoardState.initial()
    : homePlayers = const [],
      awayPlayers = const [];

  final List<PlayerPosition> homePlayers;
  final List<PlayerPosition> awayPlayers;

  TacticalBoardState copyWith({
    List<PlayerPosition>? homePlayers,
    List<PlayerPosition>? awayPlayers,
  }) {
    return TacticalBoardState(
      homePlayers: homePlayers ?? this.homePlayers,
      awayPlayers: awayPlayers ?? this.awayPlayers,
    );
  }
}

final tacticalBoardControllerProvider =
    NotifierProvider.autoDispose<TacticalBoardController, TacticalBoardState>(
      TacticalBoardController.new,
    );

class TacticalBoardController extends AutoDisposeNotifier<TacticalBoardState> {
  static const _homeRotationMap = <int, int>{
    1: 6,
    6: 5,
    5: 4,
    4: 3,
    3: 2,
    2: 1,
  };

  @override
  TacticalBoardState build() => const TacticalBoardState.initial();

  String? addPlayer({
    required TacticalTeam team,
    required int zoneIndex,
    required int jerseyNumber,
  }) {
    if (jerseyNumber <= 0) {
      return 'Jersey number must be greater than 0.';
    }

    final players = _playersFor(team);
    if (players.any((player) => player.zoneIndex == zoneIndex)) {
      return 'Zone $zoneIndex already has a ${team.name} player.';
    }
    if (players.any((player) => player.jerseyNumber == jerseyNumber)) {
      return 'Jersey #$jerseyNumber is already on the ${team.name} side.';
    }

    final player = PlayerPosition(
      id: _uuid.v4(),
      jerseyNumber: jerseyNumber,
      position: VolleyballCourtGeometry.normalizedZoneCenter(zoneIndex),
      zoneIndex: zoneIndex,
    );

    _setPlayers(team, [...players, player]);
    return null;
  }

  void movePlayer({
    required TacticalTeam team,
    required String playerId,
    required int zoneIndex,
  }) {
    final players = _playersFor(team);
    final occupiedByOther = players.any(
      (player) => player.zoneIndex == zoneIndex && player.id != playerId,
    );
    if (occupiedByOther) {
      return;
    }

    final updated = players
        .map(
          (player) => player.id == playerId
              ? player.copyWith(
                  zoneIndex: zoneIndex,
                  position: VolleyballCourtGeometry.normalizedZoneCenter(
                    zoneIndex,
                  ),
                )
              : player,
        )
        .toList();
    _setPlayers(team, updated);
  }

  void rotateHomePlayers() {
    final updated = state.homePlayers.map((player) {
      final nextZone = _homeRotationMap[player.zoneIndex] ?? player.zoneIndex;
      return player.copyWith(
        zoneIndex: nextZone,
        position: VolleyballCourtGeometry.normalizedZoneCenter(nextZone),
      );
    }).toList();
    state = state.copyWith(homePlayers: updated);
  }

  List<PlayerPosition> _playersFor(TacticalTeam team) {
    return team == TacticalTeam.home ? state.homePlayers : state.awayPlayers;
  }

  void _setPlayers(TacticalTeam team, List<PlayerPosition> players) {
    state = team == TacticalTeam.home
        ? state.copyWith(homePlayers: players)
        : state.copyWith(awayPlayers: players);
  }
}

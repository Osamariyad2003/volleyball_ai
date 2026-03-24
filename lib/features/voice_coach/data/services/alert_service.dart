import '../models/coach_models.dart';

class AlertService {
  final List<CoachingAlert> _alerts = [];
  int _counter = 0;

  List<CoachingAlert> checkForAlerts(MatchSession match) {
    final newAlerts = <CoachingAlert>[];
    final rallies = match.rallies;
    if (rallies.length < 3) {
      return const [];
    }

    final last5 = rallies.reversed.take(5).toList();
    final awayWins = last5.where((r) => r.winner == 'away').length;
    if (awayWins >= 4 && last5.length >= 5) {
      newAlerts.add(
        CoachingAlert(
          id: 'alert_${++_counter}',
          priority: AlertPriority.critical,
          category: 'momentum_shift',
          title: 'Opponent on a run!',
          message:
              "They've won $awayWins of the last 5 rallies. Consider calling timeout.",
        ),
      );
    }

    if (match.scoreAway >= 24 && match.scoreAway > match.scoreHome) {
      newAlerts.add(
        CoachingAlert(
          id: 'alert_${++_counter}',
          priority: AlertPriority.critical,
          category: 'set_point',
          title: 'Set point against us!',
          message:
              'Score ${match.scoreHome}-${match.scoreAway}. Focus on serve receive.',
        ),
      );
    }

    final rotationMap = <int, List<String>>{};
    for (final rally in rallies.reversed.take(20)) {
      rotationMap.putIfAbsent(rally.rotation, () => []).add(rally.winner);
    }

    for (final entry in rotationMap.entries) {
      if (entry.value.length < 3) {
        continue;
      }
      final losses = entry.value.where((winner) => winner == 'away').length;
      if (losses / entry.value.length >= 0.75) {
        newAlerts.add(
          CoachingAlert(
            id: 'alert_${++_counter}',
            priority: AlertPriority.high,
            category: 'rotation_weakness',
            title: 'Rotation ${entry.key} struggling',
            message:
                'Lost $losses/${entry.value.length} rallies in rotation ${entry.key}.',
          ),
        );
      }
    }

    final recentServes = rallies.reversed
        .take(8)
        .where((r) => r.serverTeam == 'away')
        .toList();
    final aces = recentServes.where((r) => r.pointType == 'ace').length;
    if (aces >= 2) {
      newAlerts.add(
        CoachingAlert(
          id: 'alert_${++_counter}',
          priority: AlertPriority.high,
          category: 'serve_threat',
          title: 'Aces incoming!',
          message:
              '$aces aces in the last ${recentServes.length} opponent serves. Adjust reception.',
        ),
      );
    }

    final last3 = rallies.reversed.take(3).toList();
    if (last3.length == 3 &&
        last3.every((rally) => rally.winner == 'away') &&
        match.scoreAway >= 20) {
      newAlerts.add(
        CoachingAlert(
          id: 'alert_${++_counter}',
          priority: AlertPriority.critical,
          category: 'timeout_needed',
          title: 'Take a timeout now',
          message:
              'Three straight lost and the opponent is in the 20s. Regroup.',
        ),
      );
    }

    _alerts.addAll(newAlerts);
    return newAlerts;
  }
}

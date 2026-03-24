import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vollyball_stats/core/model/match_result.dart';
import 'package:vollyball_stats/core/widget/EmptyPageWidget.dart';

class MatchResultsList extends StatelessWidget {
  const MatchResultsList({super.key, required this.matches});

  final List<MatchResult> matches;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return EmptyPageWidget();
    }

    final formatter = DateFormat('MMM d, HH:mm');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final match = matches[index];
        final scheduled = match.scheduledAt == null
            ? 'Time TBD'
            : formatter.format(match.scheduledAt!.toLocal());
        final scoreText = match.homeScore == null && match.awayScore == null
            ? 'vs'
            : '${match.homeScore ?? 0} : ${match.awayScore ?? 0}';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scheduled, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text(match.homeTeam)),
                    Text(
                      scoreText,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Expanded(
                      child: Text(match.awayTeam, textAlign: TextAlign.right),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Chip(label: Text(match.status.toUpperCase())),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

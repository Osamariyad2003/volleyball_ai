import 'package:flutter/material.dart';
import 'package:vollyball_stats/core/model/team.dart';
import 'package:vollyball_stats/core/widget/EmptyPageWidget.dart';

class TeamsList extends StatelessWidget {
  const TeamsList({super.key, required this.teams});

  final List<Team> teams;

  @override
  Widget build(BuildContext context) {
    if (teams.isEmpty) {
      return EmptyPageWidget();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: teams.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final team = teams[index];
        final initials = team.name.isEmpty
            ? '?'
            : team.name
                  .trim()
                  .split(RegExp(r'\s+'))
                  .where((part) => part.isNotEmpty)
                  .take(2)
                  .map((part) => part[0].toUpperCase())
                  .join();

        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(initials)),
            title: Text(team.name),
            subtitle: Text(
              [
                if (team.country.isNotEmpty) team.country,
                if (team.abbreviation.isNotEmpty) team.abbreviation,
              ].join(' - '),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:vollyball_stats/core/model/category.dart';
import 'package:vollyball_stats/core/model/tournament.dart';
import 'package:vollyball_stats/core/model/tournaments.dart';
import 'package:vollyball_stats/core/widget/TournamentsGrid.dart';

class BackdropCategoryWidget extends StatelessWidget {
  const BackdropCategoryWidget({
    Key? key,
    required this.category,
    required this.tournaments,
  }) : super(key: key);

  final Tournaments tournaments;
  final Category category;

  @override
  Widget build(BuildContext context) {
    return new Container(
      key: new PageStorageKey<Category>(category),
      child: TournamentsGrid(
        tournamentList: tournaments.tournaments
            .where(
              (Tournament tournament) =>
                  (tournament.category.id == category.id) ||
                  category.id == Category.ID_ALL,
            )
            .toList(),
      ),
    );
  }
}

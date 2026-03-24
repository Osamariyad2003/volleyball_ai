import 'package:flutter/material.dart';

import '../model/category.dart';
import '../model/tournament.dart';
import '../model/tournaments.dart';
import 'TournamentsGrid.dart';

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

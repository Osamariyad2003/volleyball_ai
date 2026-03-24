import 'package:flutter/material.dart';

import '../model/tournament.dart';
import '../navigator.dart';
import 'EmptyPageWidget.dart';

class TournamentsGrid extends StatelessWidget {
  final List<Tournament> tournamentList;

  const TournamentsGrid({Key? key, required this.tournamentList})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200.0,
      ),
      itemCount: tournamentList.length,
      itemBuilder: (context, index) {
        if (tournamentList.length == 0) {
          return new EmptyPageWidget();
        } else {
          return getCard(context, tournamentList[index]);
        }
      },
    );
  }

  Card getCard(BuildContext context, Tournament tournament) {
    return Card(
      child: InkWell(
        onTap: () => launchTournamentDetail(context, tournament.id),
        child: new Center(
          child: new Container(
            margin: const EdgeInsets.all(10.0),
            child: new Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                new Stack(children: <Widget>[Text(tournament.name)]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

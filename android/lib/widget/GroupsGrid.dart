import 'package:flutter/material.dart';

import '../model/tournamentinfo.dart';
import 'EmptyPageWidget.dart';

class GroupsGrid extends StatelessWidget {
  final TournamentInfo tournamentInfo;

  GroupsGrid({Key? key, required this.tournamentInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200.0,
      ),
      itemCount: tournamentInfo.groups.length,
      itemBuilder: (context, index) {
        if (tournamentInfo.groups.length == 0) {
          return new EmptyPageWidget();
        } else {
          return InkWell(
            child: Card(
              child: new Center(
                child: new Container(
                  margin: const EdgeInsets.all(10.0),
                  child: new Center(
                    child: new Container(
                      margin: const EdgeInsets.all(10.0),
                      child: new Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          new Stack(children: <Widget>[getCardLayout(index)]),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Text getCardLayout(int index) {
    if (tournamentInfo.groups[index].name.isNotEmpty) {
      return Text("Group " + tournamentInfo.groups[index].name);
    } else {
      return Text("Single group tournament");
    }
  }
}

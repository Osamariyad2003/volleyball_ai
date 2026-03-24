import 'package:flutter/material.dart';
import 'package:vollyball_stats/core/model/livestandings.dart';
import 'package:vollyball_stats/core/model/match_result.dart';
import 'package:vollyball_stats/core/model/team.dart';
import 'package:vollyball_stats/core/model/tournament.dart';
import 'package:vollyball_stats/core/model/tournamentinfo.dart';
import 'package:vollyball_stats/core/net/StatsInteractor.dart';
import 'package:vollyball_stats/core/net/StatsInteractorImpl.dart';
import 'package:vollyball_stats/core/widget/EmptyPageWidget.dart';
import 'package:vollyball_stats/core/widget/GroupsGrid.dart';
import 'package:vollyball_stats/core/widget/LiveStandingsList.dart';
import 'package:vollyball_stats/core/widget/MatchResultsList.dart';
import 'package:vollyball_stats/core/widget/TeamsList.dart';

class TournamentsGrid extends StatelessWidget {
  final List<Tournament> tournamentList;

  const TournamentsGrid({super.key, required this.tournamentList});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200.0,
      ),
      itemCount: tournamentList.length,
      itemBuilder: (context, index) {
        if (tournamentList.isEmpty) {
          return EmptyPageWidget();
        } else {
          return getCard(context, tournamentList[index]);
        }
      },
    );
  }

  Card getCard(BuildContext context, Tournament tournament) {
    return Card(
      child: InkWell(
        onTap: () => launchTournamentDetail(context, tournament),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Stack(children: <Widget>[Text(tournament.name)]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void launchTournamentDetail(BuildContext context, Tournament tournament) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _TournamentDetailPage(tournament: tournament),
      ),
    );
  }
}

class _TournamentDetailPage extends StatelessWidget {
  _TournamentDetailPage({required this.tournament});

  final Tournament tournament;
  final StatsInteractor _statsInteractor = StatsInteractorImpl();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tournament.name),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Groups'),
              Tab(text: 'Standings'),
              Tab(text: 'Teams'),
              Tab(text: 'Matches'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            FutureBuilder<TournamentInfo>(
              future: _statsInteractor.fetchTournamentInfo(tournament.id),
              builder: (context, snapshot) {
                return _buildAsyncBody(
                  snapshot: snapshot,
                  onData: (data) => GroupsGrid(tournamentInfo: data),
                  emptyMessage: 'No tournament information available.',
                );
              },
            ),
            FutureBuilder<LiveStandings>(
              future: _statsInteractor.fetchTournamentStandings(tournament.id),
              builder: (context, snapshot) {
                return _buildAsyncBody(
                  snapshot: snapshot,
                  onData: (data) => LiveStandingsList(livestandings: data),
                  emptyMessage: 'No live standings available.',
                );
              },
            ),
            FutureBuilder<List<Team>>(
              future: _loadTeams(),
              builder: (context, snapshot) {
                return _buildAsyncBody(
                  snapshot: snapshot,
                  onData: (data) => TeamsList(teams: data),
                  emptyMessage: 'No teams available for the current season.',
                );
              },
            ),
            FutureBuilder<List<MatchResult>>(
              future: _loadMatchesAndResults(),
              builder: (context, snapshot) {
                return _buildAsyncBody(
                  snapshot: snapshot,
                  onData: (data) => MatchResultsList(matches: data),
                  emptyMessage:
                      'No matches or results available for the current season.',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Team>> _loadTeams() {
    if (tournament.current_season.id.isEmpty) {
      throw StateError('No current season id available for this tournament.');
    }
    return _statsInteractor.fetchTeams(tournament.current_season.id);
  }

  Future<List<MatchResult>> _loadMatchesAndResults() {
    if (tournament.current_season.id.isEmpty) {
      throw StateError('No current season id available for this tournament.');
    }
    return _statsInteractor.fetchMatchesAndResults(
      tournament.current_season.id,
    );
  }

  Widget _buildAsyncBody<T>({
    required AsyncSnapshot<T> snapshot,
    required Widget Function(T data) onData,
    required String emptyMessage,
  }) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(snapshot.error.toString(), textAlign: TextAlign.center),
        ),
      );
    }

    final data = snapshot.data;
    if (data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(emptyMessage, textAlign: TextAlign.center),
        ),
      );
    }

    return onData(data);
  }
}

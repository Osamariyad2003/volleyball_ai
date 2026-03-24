import '../../../net/StatsInteractor.dart';
import '../../../net/StatsInteractorImpl.dart';
import 'LiveStandingsView.dart';

class LiveStandingsPagePresenter {
  String tournamentId;
  LiveStandingsView view;
  late StatsInteractor interactor;

  LiveStandingsPagePresenter(this.view, this.tournamentId) {
    interactor = new StatsInteractorImpl();
  }

  void getLiveStandings() {
    interactor
        .fetchTournamentStandings(tournamentId)
        .then((standings) => view.showLiveStandings(standings))
        .catchError((e) => view.showError(e));
  }
}

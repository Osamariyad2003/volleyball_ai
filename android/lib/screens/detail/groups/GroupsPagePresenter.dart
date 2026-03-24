import '../../../net/StatsInteractor.dart';
import '../../../net/StatsInteractorImpl.dart';
import 'GroupsView.dart';

class GroupsPagePresenter {
  String tournamentId;
  GroupsView view;
  late StatsInteractor interactor;

  GroupsPagePresenter(this.view, this.tournamentId) {
    interactor = new StatsInteractorImpl();
  }

  void getTournamentInfo() {
    interactor
        .fetchTournamentInfo(tournamentId)
        .then((info) => view.showGroups(info))
        .catchError((e) => view.showError(e));
  }
}

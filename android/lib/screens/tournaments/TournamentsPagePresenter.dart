import '../../net/StatsInteractor.dart';
import '../../net/StatsInteractorImpl.dart';
import 'TournamentsView.dart';

class TournamentsPagePresenter {
  TournamentsView view;
  late StatsInteractor interactor;

  TournamentsPagePresenter(this.view) {
    interactor = StatsInteractorImpl();
  }

  void getTournaments() {
    interactor
        .fetchTournaments()
        .then((tournaments) => view.showTournaments(tournaments))
        .catchError((e) => view.showError(e));
  }

  void getCategories() {}
}

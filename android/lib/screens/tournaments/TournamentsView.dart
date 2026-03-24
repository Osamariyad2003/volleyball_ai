import '../../arch/BaseView.dart';
import '../../model/tournaments.dart';

abstract class TournamentsView extends BaseView {
  void showTournaments(Tournaments result);
  void showError(e);
}

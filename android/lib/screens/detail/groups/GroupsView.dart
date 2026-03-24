import '../../../arch/BaseView.dart';
import '../../../model/tournamentinfo.dart';

abstract class GroupsView extends BaseView {
  void showGroups(TournamentInfo result);
  void showError(e);
}

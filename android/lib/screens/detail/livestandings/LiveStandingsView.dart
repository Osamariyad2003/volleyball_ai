import '../../../arch/BaseView.dart';
import '../../../model/livestandings.dart';

abstract class LiveStandingsView extends BaseView {
  void showLiveStandings(LiveStandings result);
  void showError(e);
}

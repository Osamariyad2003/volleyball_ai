import 'package:flutter/material.dart';

import '../../../model/livestandings.dart';
import '../../../widget/ErrorWidget.dart';
import '../../../widget/LiveStandingsList.dart';
import '../../../widget/WidgetUtil.dart';
import '../DetailPage.dart';
import 'LiveStandingsPagePresenter.dart';
import 'LiveStandingsView.dart';

class LiveStandingsPage extends StatefulWidget {
  const LiveStandingsPage({
    Key? key,
    required this.title,
    required this.detailPage,
  }) : super(key: key);

  final String title;
  final DetailPage detailPage;

  @override
  _LiveStandingsPageState createState() =>
      new _LiveStandingsPageState(detailPage);
}

class _LiveStandingsPageState extends State<LiveStandingsPage>
    implements LiveStandingsView {
  bool isLoading = true;
  bool isError = false;
  late LiveStandings standings;

  late LiveStandingsPagePresenter presenter;

  _LiveStandingsPageState(DetailPage detailPage) {
    presenter = LiveStandingsPagePresenter(this, detailPage.getTournamentId());
  }

  @override
  void initState() {
    super.initState();
    resetState();
  }

  void resetState() {
    isLoading = true;
    isError = false;

    presenter.getLiveStandings();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text(widget.title)),
      body: createView(),
    );
  }

  Widget createView() {
    if (isError) {
      return NetworkErrorWidget(
        onTapCallback: () => setState(() {
          resetState();
        }),
      );
    } else if (isLoading) {
      return getProgressDialog();
    } else {
      return LiveStandingsList(livestandings: standings);
    }
  }

  @override
  void showError(e) {
    setState(() {
      isLoading = false;
      isError = true;
    });
  }

  @override
  void showLiveStandings(LiveStandings result) {
    setState(() {
      standings = result;
      isLoading = false;
      isError = false;
    });
  }
}

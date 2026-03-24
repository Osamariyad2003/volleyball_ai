import 'package:flutter/material.dart';

import '../../../model/tournamentinfo.dart';
import '../../../widget/ErrorWidget.dart';
import '../../../widget/GroupsGrid.dart';
import '../../../widget/WidgetUtil.dart';
import '../DetailPage.dart';
import 'GroupsPagePresenter.dart';
import 'GroupsView.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({Key? key, required this.title, required this.detailPage})
    : super(key: key);

  final String title;
  final DetailPage detailPage;

  @override
  _GroupsPageState createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> implements GroupsView {
  bool isLoading = true;
  bool isError = false;
  late TournamentInfo info;

  late GroupsPagePresenter presenter;

  @override
  void initState() {
    super.initState();
    presenter = GroupsPagePresenter(this, widget.detailPage.getTournamentId());
    resetState();
  }

  void resetState() {
    isLoading = true;
    isError = false;

    presenter.getTournamentInfo();
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
      return GroupsGrid(tournamentInfo: info);
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
  void showGroups(TournamentInfo result) {
    setState(() {
      info = result;
      isLoading = false;
      isError = false;
    });
  }
}

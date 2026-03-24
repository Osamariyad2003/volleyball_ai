import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../model/category.dart';
import '../../model/tournaments.dart';
import '../../widget/BackdropCategoryWidget.dart';
import '../../widget/BackdropPanel.dart';
import '../../widget/BackdropTitle.dart';
import '../../widget/ErrorWidget.dart';
import '../../widget/WidgetUtil.dart';
import 'TournamentsPagePresenter.dart';
import 'TournamentsView.dart';

class TournamentsPage extends StatefulWidget {
  TournamentsPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _TournamentsPageState createState() => new _TournamentsPageState();
}

class _TournamentsPageState extends State<TournamentsPage>
    with SingleTickerProviderStateMixin
    implements TournamentsView {
  bool isLoading = true;
  bool isError = false;
  Tournaments? tournaments;
  late TournamentsPagePresenter presenter;

  final GlobalKey _backdropKey = new GlobalKey(debugLabel: 'Backdrop');
  late AnimationController _controller;
  final Category allCategory = new Category(Category.ID_ALL, Category.NAME_ALL);
  Category _currentSelectedCategory = new Category(
    Category.ID_ALL,
    Category.NAME_ALL,
  );

  _TournamentsPageState() {
    presenter = TournamentsPagePresenter(this);
  }

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(
      duration: const Duration(milliseconds: 300),
      value: 1.0,
      vsync: this,
    );
    resetState();
  }

  void resetState() {
    isLoading = true;
    isError = false;
    _currentSelectedCategory = new Category(Category.ID_ALL, Category.NAME_ALL);
    presenter.getTournaments();
  }

  @override
  void showError(e) {
    setState(() {
      tournaments = null;
      isLoading = false;
      isError = true;
    });
  }

  @override
  void showTournaments(Tournaments result) {
    setState(() {
      tournaments = result;
      isLoading = false;
      isError = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changeCategory(Category category) {
    setState(() {
      _currentSelectedCategory = category;
      _controller.fling(velocity: 2.0);
    });
  }

  bool get _backdropPanelVisible {
    final AnimationStatus status = _controller.status;
    return status == AnimationStatus.completed ||
        status == AnimationStatus.forward;
  }

  void _toggleBackdropPanelVisibility() {
    _controller.fling(velocity: _backdropPanelVisible ? -2.0 : 2.0);
  }

  double get _backdropHeight {
    final renderObject = _backdropKey.currentContext?.findRenderObject();
    if (renderObject is RenderBox) {
      return renderObject.size.height;
    }
    return 0.0;
  }

  // By design: the panel can only be opened with a swipe. To close the panel
  // the user must either tap its heading or the backdrop's menu icon.

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_controller.isAnimating ||
        _controller.status == AnimationStatus.completed)
      return;

    if (_backdropHeight != 0.0) {
      _controller.value -= details.primaryDelta! / _backdropHeight!;
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_controller.isAnimating ||
        _controller.status == AnimationStatus.completed)
      return;

    final double flingVelocity =
        details.velocity.pixelsPerSecond.dy / _backdropHeight;
    if (flingVelocity < 0.0)
      _controller.fling(velocity: math.max(2.0, -flingVelocity));
    else if (flingVelocity > 0.0)
      _controller.fling(velocity: math.min(-2.0, -flingVelocity));
    else
      _controller.fling(velocity: _controller.value < 0.5 ? -2.0 : 2.0);
  }

  // Stacks a BackdropPanel, which displays the selected category, on top
  // of the backdrop. The categories are displayed with ListTiles. Just one
  // can be selected at a time. This is a LayoutWidgetBuild function because
  // we need to know how big the BackdropPanel will be to set up its
  // animation.
  Widget buildStack(BuildContext context, BoxConstraints constraints) {
    const double panelTitleHeight = 48.0;
    final Size panelSize = constraints.biggest;
    final double panelTop = panelSize.height - panelTitleHeight;

    final Animation<RelativeRect> panelAnimation = new RelativeRectTween(
      begin: new RelativeRect.fromLTRB(
        0.0,
        panelTop - MediaQuery.of(context).padding.bottom,
        0.0,
        panelTop - panelSize.height,
      ),
      end: const RelativeRect.fromLTRB(0.0, 0.0, 0.0, 0.0),
    ).animate(new CurvedAnimation(parent: _controller, curve: Curves.linear));

    if (isError) {
      return NetworkErrorWidget(
        onTapCallback: () => setState(() {
          resetState();
        }),
      );
    } else if (isLoading) {
      return getProgressDialog();
    } else {
      final ThemeData theme = Theme.of(context);
      final List<Widget> backdropItems = getUniqueCategories(tournaments!)
          .map<Widget>((Category category) {
            final bool selected = category.id == _currentSelectedCategory.id;
            return new Material(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
              ),
              color: selected
                  ? Colors.white.withAlpha((0.25 * 255).toInt())
                  : Colors.transparent,
              child: new ListTile(
                title: new Text(category.name),
                selected: selected,
                onTap: () {
                  _changeCategory(category);
                },
              ),
            );
          })
          .toList();

      // Add the All category manually
      backdropItems.insert(0, getAllCategoryWidget());

      return new Container(
        key: _backdropKey,
        color: theme.primaryColor,
        child: new Stack(
          children: <Widget>[
            new ListTileTheme(
              iconColor: theme.primaryIconTheme.color,
              textColor: theme.primaryTextTheme.titleLarge?.color?.withOpacity(
                0.6,
              ),
              selectedColor: theme.primaryTextTheme.titleLarge?.color,
              child: new ListView(children: backdropItems),
            ),
            new PositionedTransition(
              rect: panelAnimation,
              child: new BackdropPanel(
                onTap: _toggleBackdropPanelVisibility,
                onVerticalDragUpdate: _handleDragUpdate,
                onVerticalDragEnd: _handleDragEnd,
                title: new Text(_currentSelectedCategory.name),
                child: new BackdropCategoryWidget(
                  category: _currentSelectedCategory,
                  tournaments: tournaments!,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  List<Category> getUniqueCategories(Tournaments tournaments) {
    Set<Category> categoriesSet = new Set();
    for (var tournament in tournaments.tournaments) {
      categoriesSet.add(tournament.category);
    }

    return categoriesSet.toList();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        elevation: 0.0,
        title: new BackdropTitle(
          key: UniqueKey(),
          listenable: _controller.view,
        ),
        leading: new IconButton(
          onPressed: _toggleBackdropPanelVisibility,
          icon: new AnimatedIcon(
            icon: AnimatedIcons.close_menu,
            progress: _controller.view,
          ),
        ),
      ),
      body: new LayoutBuilder(builder: buildStack),
    );
  }

  Widget getAllCategoryWidget() {
    final bool selected = allCategory.id == _currentSelectedCategory.id;
    return new Material(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
      ),
      color: selected
          ? Colors.white.withAlpha((0.25 * 255).toInt())
          : Colors.transparent,
      child: new ListTile(
        title: new Text(allCategory.name),
        selected: selected,
        onTap: () {
          _changeCategory(allCategory);
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AppScaffoldDark extends StatelessWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? appBarBottom;
  final bool showAppBar;

  const AppScaffoldDark({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.appBarBottom,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: showAppBar
          ? AppBar(
              title: title != null
                  ? Text(title!)
                  : Image.asset(
                      'assets/icons/ic_volleyball_emblem.png',
                      height: 32,
                    ),
              actions: [
                if (actions != null) ...actions!,
                const SizedBox(width: 8),
              ],
              bottom: appBarBottom,
              backgroundColor: theme.scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
            )
          : null,
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

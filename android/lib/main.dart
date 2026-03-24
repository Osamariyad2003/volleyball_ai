import 'package:flutter/material.dart';

import 'screens/tournaments/TournamentsPage.dart';
import 'style/theme.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Volleystats',
      theme: getThemeData(),
      home: new TournamentsPage(title: 'volleystats'),
    );
  }
}

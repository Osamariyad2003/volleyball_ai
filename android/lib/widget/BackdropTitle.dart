import 'package:flutter/material.dart';

class BackdropTitle extends AnimatedWidget {
  const BackdropTitle({
    required Key key,
    required Animation<double> listenable,
  }) : super(key: key, listenable: listenable);

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = listenable as Animation<double>;
    return new DefaultTextStyle(
      style: Theme.of(context).primaryTextTheme.headlineMedium!,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      child: new Stack(
        children: <Widget>[
          new Opacity(
            opacity: new CurvedAnimation(
              parent: new ReverseAnimation(animation),
              curve: const Interval(0.5, 1.0),
            ).value,
            child: const Text('Select a Category'),
          ),
          new Opacity(
            opacity: new CurvedAnimation(
              parent: animation,
              curve: const Interval(0.5, 1.0),
            ).value,
            child: const Text('Volleystats'),
          ),
        ],
      ),
    );
  }
}

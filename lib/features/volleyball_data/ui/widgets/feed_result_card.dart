import 'package:flutter/material.dart';

import '../../state/volleyball_data_state.dart';

class FeedResultCard<T> extends StatelessWidget {
  const FeedResultCard({
    super.key,
    required this.title,
    required this.state,
    required this.onRetry,
    required this.builder,
    this.emptyMessage = 'No data available.',
  });

  final String title;
  final FeedState<T> state;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildBody(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (state.status) {
      case FeedStatus.idle:
        return Text(
          'Select a feed to load data.',
          style: Theme.of(context).textTheme.bodyMedium,
        );
      case FeedStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        );
      case FeedStatus.error:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.error ?? 'Something went wrong.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        );
      case FeedStatus.success:
        final data = state.data;
        if (data == null || _isEmptyValue(data)) {
          return Text(
            emptyMessage,
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
        return builder(data);
    }
  }

  bool _isEmptyValue(T data) {
    if (data is List) {
      return data.isEmpty;
    }
    return false;
  }
}

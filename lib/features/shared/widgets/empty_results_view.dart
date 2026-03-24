import 'package:flutter/material.dart';

class EmptyResultsView extends StatelessWidget {
  final String assetPath;
  final String title;
  final String message;
  final VoidCallback onClearFilters;

  const EmptyResultsView({
    super.key,
    required this.assetPath,
    this.title = 'No Results Found',
    this.message = 'Try adjusting your search or filters to find what you\'re looking for.',
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Duotone Image
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Opacity(
                opacity: 0.6,
                child: Image.asset(
                  assetPath,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Clear All Filters'),
            ),
          ],
        ),
      ),
    );
  }
}

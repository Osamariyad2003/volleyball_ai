import 'package:flutter/material.dart';

class AiChatQuickSuggestions extends StatelessWidget {
  const AiChatQuickSuggestions({
    required this.suggestions,
    required this.isLoading,
    required this.onSelected,
    super.key,
  });

  final List<String> suggestions;
  final bool isLoading;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ActionChip(
            label: Text(suggestion),
            onPressed: isLoading ? null : () => onSelected(suggestion),
          );
        },
      ),
    );
  }
}

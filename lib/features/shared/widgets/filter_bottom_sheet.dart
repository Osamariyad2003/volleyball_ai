import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _filterCategoryProvider = StateProvider.autoDispose<String?>((ref) {
  return null;
});

final _filterGenderProvider = StateProvider.autoDispose<String?>((ref) {
  return null;
});

class FilterBottomSheet extends ConsumerStatefulWidget {
  final String? initialCategory;
  final String? initialGender;
  final List<String> categories;
  final Function(String? category, String? gender) onApply;
  final VoidCallback onClear;

  const FilterBottomSheet({
    super.key,
    this.initialCategory,
    this.initialGender,
    required this.categories,
    required this.onApply,
    required this.onClear,
  });

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  @override
  void initState() {
    super.initState();
    ref.read(_filterCategoryProvider.notifier).state = widget.initialCategory;
    ref.read(_filterGenderProvider.notifier).state = widget.initialGender;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCategory = ref.watch(_filterCategoryProvider);
    final selectedGender = ref.watch(_filterGenderProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Tournaments',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton.filledTonal(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Category',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: widget.categories.map((category) {
              final isSelected = selectedCategory == category;
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  ref.read(_filterCategoryProvider.notifier).state = selected
                      ? category
                      : null;
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Gender',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildGenderOption(context, 'Men', 'assets/icons/ic_volleyball_man.png'),
              const SizedBox(width: 12),
              _buildGenderOption(context, 'Women', 'assets/icons/ic_volleyball_woman.png'),
              const SizedBox(width: 12),
              _buildGenderOption(context, 'Any', 'assets/icons/ic_volleyball_emblem.png'),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onClear();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Clear All'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    widget.onApply(selectedCategory, selectedGender);
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGenderOption(BuildContext context, String gender, String assetPath) {
    final theme = Theme.of(context);
    final selectedGender = ref.watch(_filterGenderProvider);
    final isSelected = selectedGender == gender;

    return Expanded(
      child: InkWell(
        onTap: () => ref.read(_filterGenderProvider.notifier).state = gender,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Image.asset(assetPath, width: 28, height: 28),
              const SizedBox(height: 6),
              Text(
                gender,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

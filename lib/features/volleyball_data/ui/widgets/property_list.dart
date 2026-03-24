import 'package:flutter/material.dart';

class PropertyItem {
  const PropertyItem(this.label, this.value);

  final String label;
  final String value;
}

class PropertyList extends StatelessWidget {
  const PropertyList({super.key, required this.items});

  final List<PropertyItem> items;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items
        .where((item) => item.value.trim().isNotEmpty)
        .toList();
    if (visibleItems.isEmpty) {
      return Text(
        'No details available.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Column(
      children: visibleItems
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      item.label,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.value,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

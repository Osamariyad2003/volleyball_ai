import 'package:flutter/material.dart';

class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black12,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class ListSkeleton extends StatelessWidget {
  final int itemCount;
  final bool shrinkWrap;

  const ListSkeleton({super.key, this.itemCount = 6, this.shrinkWrap = false});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => Row(
        children: [
          const LoadingSkeleton(width: 60, height: 60, borderRadius: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LoadingSkeleton(width: 150, height: 20),
                const SizedBox(height: 8),
                const LoadingSkeleton(width: 100, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

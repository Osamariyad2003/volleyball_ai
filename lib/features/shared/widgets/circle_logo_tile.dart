import 'package:flutter/material.dart';

class CircleLogoTile extends StatelessWidget {
  final String? imageUrl;
  final String label;
  final double size;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool showStar;
  final String heroTag;

  const CircleLogoTile({
    super.key,
    this.imageUrl,
    required this.label,
    this.size = 64,
    this.onTap,
    this.isSelected = false,
    this.showStar = false,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Hero(
                tag: heroTag,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.surfaceContainerHighest,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.5),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: ClipOval(
                    child: imageUrl != null && imageUrl!.startsWith('http')
                        ? Image.network(
                            imageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                ),
              ),
              if (showStar)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: size + 20,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? theme.colorScheme.primary : null,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Image.asset(
      'assets/icons/ic_volleyball_emblem.png',
      fit: BoxFit.contain,
    );
  }
}

import 'package:flutter/material.dart';

class AdaptiveGlassAvatar extends StatelessWidget {
  const AdaptiveGlassAvatar({
    super.key,
    required this.child,
    this.size = 40,
    this.glassAlpha,
    this.borderAlpha,
  });

  final Widget child;
  final double size;
  final double? glassAlpha;
  final double? borderAlpha;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surface.withValues(alpha: glassAlpha ?? 0.92),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: borderAlpha ?? 0.2),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

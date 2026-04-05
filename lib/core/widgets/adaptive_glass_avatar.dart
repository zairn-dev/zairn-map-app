import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../navigation/adaptive_liquid_glass.dart';

class AdaptiveGlassAvatar extends StatelessWidget {
  const AdaptiveGlassAvatar({
    super.key,
    required this.child,
    this.size = 40,
    this.glassAlpha = 0.16,
    this.borderAlpha = 0.3,
  });

  final Widget child;
  final double size;
  final double glassAlpha;
  final double borderAlpha;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final shape = LiquidOval(
      side: BorderSide(
        color: colors.outlineVariant.withValues(alpha: borderAlpha),
      ),
    );

    return AdaptiveLiquidGlass(
      shape: shape,
      settings: LiquidGlassSettings(
        thickness: 12,
        blur: 4,
        glassColor: colors.surface.withValues(alpha: glassAlpha),
        lightIntensity: 0.48,
        ambientStrength: 0.2,
        saturation: 1.04,
        chromaticAberration: 0.002,
      ),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: colors.surface.withValues(alpha: glassAlpha),
          shape: shape,
        ),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: child),
        ),
      ),
    );
  }
}

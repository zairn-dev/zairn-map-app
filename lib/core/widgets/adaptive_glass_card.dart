import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../navigation/adaptive_liquid_glass.dart';

class AdaptiveGlassCard extends StatelessWidget {
  const AdaptiveGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding,
    this.glassAlpha = 0.16,
    this.borderAlpha = 0.32,
    this.tintColor,
    this.borderColor,
    this.settings,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double glassAlpha;
  final double borderAlpha;
  final Color? tintColor;
  final Color? borderColor;
  final LiquidGlassSettings? settings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final resolvedTintColor = tintColor ?? colors.surface;
    final resolvedBorderColor = borderColor ?? colors.outlineVariant;
    final shape = LiquidRoundedSuperellipse(
      borderRadius: borderRadius,
      side: BorderSide(
        color: resolvedBorderColor.withValues(alpha: borderAlpha),
      ),
    );
    final glassSettings =
        settings ??
        LiquidGlassSettings(
          thickness: 16,
          blur: 5,
          glassColor: resolvedTintColor.withValues(alpha: glassAlpha),
          lightIntensity: 0.5,
          ambientStrength: 0.2,
          saturation: 1.06,
          chromaticAberration: 0.002,
        );

    return AdaptiveLiquidGlass(
      shape: shape,
      settings: glassSettings,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: resolvedTintColor.withValues(alpha: glassAlpha),
          shape: shape,
        ),
        child: Material(
          color: Colors.transparent,
          child: padding == null
              ? child
              : Padding(padding: padding!, child: child),
        ),
      ),
    );
  }
}

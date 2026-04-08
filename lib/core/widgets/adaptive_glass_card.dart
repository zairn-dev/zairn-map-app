import 'package:flutter/material.dart';

class AdaptiveGlassCard extends StatelessWidget {
  const AdaptiveGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.tintColor,
    this.borderColor,
    this.settings,
    this.glassAlpha,
    this.borderAlpha,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? tintColor;
  final Color? borderColor;
  final dynamic settings;
  final double? glassAlpha;
  final double? borderAlpha;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: (tintColor ?? colors.surface).withValues(alpha: glassAlpha ?? 0.95),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: (borderColor ?? colors.outlineVariant).withValues(alpha: borderAlpha ?? 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: padding != null
          ? Padding(padding: padding!, child: child)
          : child,
    );
  }
}

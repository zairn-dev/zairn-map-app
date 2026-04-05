import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../navigation/adaptive_liquid_glass.dart';

class AdaptiveGlassIconButton extends StatelessWidget {
  const AdaptiveGlassIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.semanticsLabel,
    this.size = 44,
    this.iconSize = 20,
    this.glassAlpha = 0.16,
    this.borderAlpha = 0.32,
    this.tintColor,
    this.borderColor,
    this.foregroundColor,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? semanticsLabel;
  final double size;
  final double iconSize;
  final double glassAlpha;
  final double borderAlpha;
  final Color? tintColor;
  final Color? borderColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enabled = onPressed != null;
    final resolvedTintColor = tintColor ?? colors.surface;
    final resolvedBorderColor = borderColor ?? colors.outlineVariant;
    final resolvedForegroundColor = foregroundColor ?? colors.onSurfaceVariant;
    final effectiveGlassAlpha = enabled ? glassAlpha : glassAlpha * 0.7;
    final effectiveBorderAlpha = enabled ? borderAlpha : borderAlpha * 0.65;
    final iconColor = resolvedForegroundColor.withValues(
      alpha: enabled ? 1 : 0.5,
    );
    final shape = LiquidOval(
      side: BorderSide(
        color: resolvedBorderColor.withValues(alpha: effectiveBorderAlpha),
      ),
    );

    Widget button = Semantics(
      button: true,
      enabled: enabled,
      label: semanticsLabel ?? tooltip,
      child: AdaptiveLiquidGlass(
        shape: shape,
        settings: LiquidGlassSettings(
          thickness: 12,
          blur: 4.5,
          glassColor: resolvedTintColor.withValues(alpha: effectiveGlassAlpha),
          lightIntensity: 0.5,
          ambientStrength: 0.2,
          saturation: 1.05,
          chromaticAberration: 0.002,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Ink(
              width: size,
              height: size,
              decoration: ShapeDecoration(
                color: resolvedTintColor.withValues(alpha: effectiveGlassAlpha),
                shape: shape,
              ),
              child: Center(
                child: IconTheme(
                  data: IconThemeData(color: iconColor, size: iconSize),
                  child: icon,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}

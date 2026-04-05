import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../navigation/adaptive_liquid_glass.dart';

class AdaptiveGlassPillButton extends StatelessWidget {
  const AdaptiveGlassPillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.tooltip,
    this.semanticsLabel,
    this.compact = true,
    this.expanded = false,
    this.glassAlpha = 0.16,
    this.borderAlpha = 0.3,
    this.tintColor,
    this.borderColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final String? tooltip;
  final String? semanticsLabel;
  final bool compact;
  final bool expanded;
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
    final resolvedForegroundColor = foregroundColor ?? colors.onSurface;
    final effectiveGlassAlpha = enabled ? glassAlpha : glassAlpha * 0.7;
    final effectiveBorderAlpha = enabled ? borderAlpha : borderAlpha * 0.65;
    final foreground = resolvedForegroundColor.withValues(
      alpha: enabled ? 1 : 0.5,
    );
    final shape = LiquidRoundedSuperellipse(
      borderRadius: compact ? 18 : 22,
      side: BorderSide(
        color: resolvedBorderColor.withValues(alpha: effectiveBorderAlpha),
      ),
    );

    final textStyle =
        (compact ? theme.textTheme.labelLarge : theme.textTheme.titleSmall)
            ?.copyWith(color: foreground, fontWeight: FontWeight.w600) ??
        TextStyle(color: foreground, fontWeight: FontWeight.w600);

    Widget button = Semantics(
      button: true,
      enabled: enabled,
      label: semanticsLabel ?? tooltip ?? label,
      child: AdaptiveLiquidGlass(
        shape: shape,
        settings: LiquidGlassSettings(
          thickness: 12,
          blur: 4.5,
          glassColor: resolvedTintColor.withValues(alpha: effectiveGlassAlpha),
          lightIntensity: 0.48,
          ambientStrength: 0.2,
          saturation: 1.05,
          chromaticAberration: 0.002,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(compact ? 18 : 22),
            ),
            onTap: onPressed,
            child: Ink(
              decoration: ShapeDecoration(
                color: resolvedTintColor.withValues(alpha: effectiveGlassAlpha),
                shape: shape,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: compact ? 36 : 42),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 12 : 16,
                    vertical: compact ? 8 : 10,
                  ),
                  child: IconTheme(
                    data: IconThemeData(
                      color: foreground,
                      size: compact ? 18 : 20,
                    ),
                    child: DefaultTextStyle(
                      style: textStyle,
                      child: Row(
                        mainAxisSize: expanded
                            ? MainAxisSize.max
                            : MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            icon!,
                            const SizedBox(width: 8),
                          ],
                          if (expanded)
                            Flexible(
                              child: Text(
                                label,
                                maxLines: compact ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            Text(
                              label,
                              maxLines: compact ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                  ),
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

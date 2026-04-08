import 'package:flutter/material.dart';

class AdaptiveGlassIconButton extends StatelessWidget {
  const AdaptiveGlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.semanticsLabel,
    this.size = 44,
    this.iconSize = 20,
    this.tintColor,
    this.foregroundColor,
    this.borderColor,
    this.glassAlpha,
    this.borderAlpha,
  });

  final Widget icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final String? semanticsLabel;
  final double size;
  final double iconSize;
  final Color? tintColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double? glassAlpha;
  final double? borderAlpha;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg = (tintColor ?? colors.surface).withValues(alpha: glassAlpha ?? 0.92);
    final fg = foregroundColor ?? colors.onSurfaceVariant;

    return Semantics(
      label: semanticsLabel,
      child: Material(
        color: bg,
        shape: CircleBorder(
          side: BorderSide(
            color: (borderColor ?? colors.outlineVariant).withValues(alpha: borderAlpha ?? 0.2),
          ),
        ),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Tooltip(
            message: tooltip ?? '',
            child: SizedBox(
              width: size,
              height: size,
              child: IconTheme(
                data: IconThemeData(color: fg, size: iconSize),
                child: icon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AdaptiveGlassPillButton extends StatelessWidget {
  const AdaptiveGlassPillButton({
    super.key,
    required this.onPressed,
    this.label,
    this.icon,
    this.compact = true,
    this.expanded = false,
    this.tintColor,
    this.foregroundColor,
    this.borderColor,
    this.glassAlpha,
    this.borderAlpha,
  });

  final VoidCallback? onPressed;
  final String? label;
  final Widget? icon;
  final bool compact;
  final bool expanded;
  final Color? tintColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double? glassAlpha;
  final double? borderAlpha;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg = (tintColor ?? colors.surface).withValues(alpha: glassAlpha ?? 0.92);
    final fg = foregroundColor ?? colors.onSurface;
    final radius = compact ? 18.0 : 22.0;

    final content = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          IconTheme(data: IconThemeData(color: fg, size: compact ? 18 : 20), child: icon!),
          if (label != null) SizedBox(width: compact ? 6 : 8),
        ],
        if (label != null)
          Text(
            label!,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
          ),
      ],
    );

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(
          color: (borderColor ?? colors.outlineVariant).withValues(alpha: borderAlpha ?? 0.2),
        ),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 18,
            vertical: compact ? 10 : 12,
          ),
          child: content,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AdaptiveGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AdaptiveGlassAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.centerTitle = false,
  });

  final Widget title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final resolvedLeading = leading ??
        (Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.15),
            ),
          ),
          child: NavigationToolbar(
            centerMiddle: centerTitle,
            leading: resolvedLeading,
            middle: DefaultTextStyle(
              style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.onSurface,
                  ) ??
                  TextStyle(color: colors.onSurface),
              child: title,
            ),
            trailing: actions != null
                ? Row(mainAxisSize: MainAxisSize.min, children: actions!)
                : null,
          ),
        ),
      ),
    );
  }
}

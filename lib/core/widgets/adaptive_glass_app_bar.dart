import 'package:flutter/material.dart';

import 'adaptive_glass_card.dart';
import 'adaptive_glass_icon_button.dart';

class AdaptiveGlassAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const AdaptiveGlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle = false,
  });

  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final canPop = Navigator.of(context).canPop();

    Widget? resolvedLeading = leading;
    if (resolvedLeading == null && automaticallyImplyLeading && canPop) {
      resolvedLeading = AdaptiveGlassIconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const BackButtonIcon(),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        size: 40,
        iconSize: 18,
      );
    }

    Widget? trailing;
    if (actions case final items? when items.isNotEmpty) {
      trailing = Row(mainAxisSize: MainAxisSize.min, children: items);
    }

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: AdaptiveGlassCard(
          borderRadius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          glassAlpha: 0.14,
          borderAlpha: 0.28,
          child: SizedBox(
            height: kToolbarHeight - 4,
            child: NavigationToolbar(
              centerMiddle: centerTitle,
              leading: resolvedLeading,
              middle: DefaultTextStyle(
                style:
                    theme.textTheme.titleLarge?.copyWith(
                      color: colors.onSurface,
                    ) ??
                    TextStyle(color: colors.onSurface),
                child: title,
              ),
              trailing: trailing,
            ),
          ),
        ),
      ),
    );
  }
}

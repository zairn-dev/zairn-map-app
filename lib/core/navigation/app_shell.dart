import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../features/posts/presentation/feed_screen.dart' show PostComposerSheet;
import '../../features/posts/providers/posts_provider.dart';
import '../../theme/app_theme.dart';
import 'adaptive_liquid_glass.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _switchTab(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  Future<void> _openComposer(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PostComposerSheet(),
    );

    if (created != true || !context.mounted) return;

    ref.invalidate(feedPostsProvider);
    ref.invalidate(locationFeedPostsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post created.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final currentIndex = navigationShell.currentIndex;
    final shellShape = LiquidRoundedSuperellipse(
      borderRadius: 28,
      side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.34)),
    );

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: AdaptiveLiquidGlass(
          rebuildKey: 'shell_bar',
          settings: LiquidGlassSettings(
            thickness: 14,
            blur: 5,
            glassColor: colors.surface.withValues(alpha: 0.14),
            lightIntensity: 0.55,
            ambientStrength: 0.18,
            saturation: 1.08,
            chromaticAberration: 0.003,
          ),
          shape: shellShape,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: colors.surface.withValues(alpha: 0.14),
              shape: shellShape,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    _NavTab(
                      icon: Icons.explore_outlined,
                      activeIcon: Icons.explore,
                      label: 'Map',
                      isActive: currentIndex == 0,
                      onTap: () => _switchTab(0),
                    ),
                    _NavTab(
                      icon: Icons.dynamic_feed_outlined,
                      activeIcon: Icons.dynamic_feed,
                      label: 'Feed',
                      isActive: currentIndex == 1,
                      onTap: () => _switchTab(1),
                    ),
                    // Center action button — context-dependent
                    _CenterAction(
                      currentIndex: currentIndex,
                      onCompose: () => _openComposer(context, ref),
                    ),
                    _NavTab(
                      icon: Icons.people_outline,
                      activeIcon: Icons.people,
                      label: 'Friends',
                      isActive: currentIndex == 2,
                      onTap: () => _switchTab(2),
                    ),
                    _NavTab(
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      label: 'Profile',
                      isActive: currentIndex == 3,
                      onTap: () => _switchTab(3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterAction extends StatelessWidget {
  const _CenterAction({
    required this.currentIndex,
    required this.onCompose,
  });

  final int currentIndex;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    // Map(0) or Feed(1) → compose post
    // Friends(2) → add friend (TODO: wire up)
    // Profile(3) → hidden
    final isVisible = currentIndex <= 2;
    final icon = currentIndex == 2 ? Icons.person_add : Icons.add;
    final onTap = currentIndex == 2 ? null : onCompose; // TODO: add friend action

    if (!isVisible) {
      return const SizedBox(width: 56);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.brandCyan, AppTheme.brandTeal],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.brandTeal.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = isActive ? colors.primary : colors.onSurfaceVariant;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'glass_mode_provider.dart';

class AdaptiveLiquidGlass extends ConsumerWidget {
  const AdaptiveLiquidGlass({
    super.key,
    required this.child,
    required this.shape,
    this.settings = const LiquidGlassSettings(),
    this.glassContainsChild = false,
    this.clipBehavior = Clip.antiAlias,
    this.rebuildKey,
  });

  final Widget child;
  final LiquidShape shape;
  final LiquidGlassSettings settings;
  final bool glassContainsChild;
  final Clip clipBehavior;
  final Object? rebuildKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useFakeGlass = ref.watch(resolvedUseFakeGlassProvider);
    final glass = LiquidGlass.withOwnLayer(
      fake: useFakeGlass,
      settings: settings,
      shape: shape,
      glassContainsChild: glassContainsChild,
      clipBehavior: clipBehavior,
      child: child,
    );

    if (rebuildKey == null) {
      return glass;
    }

    return KeyedSubtree(
      key: ValueKey(Object.hash(rebuildKey, useFakeGlass)),
      child: glass,
    );
  }
}

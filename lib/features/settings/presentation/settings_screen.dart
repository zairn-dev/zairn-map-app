import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/glass_mode_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/adaptive_glass_app_bar.dart';
import '../../../core/widgets/adaptive_glass_card.dart';
import '../../../core/widgets/adaptive_glass_pill_button.dart';
import '../../auth/data/auth_service.dart';
import '../data/settings_service.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _glassModeSubtitle(GlassModeOverride mode, bool autoUsesFakeGlass) {
    return switch (mode) {
      GlassModeOverride.auto =>
        autoUsesFakeGlass
            ? 'Auto is currently using fake glass on this device.'
            : 'Auto is currently using real liquid glass on this device.',
      GlassModeOverride.fake =>
        'Force the bottom bar to use the fallback renderer.',
      GlassModeOverride.real =>
        'Force the bottom bar to use the real liquid glass renderer.',
    };
  }

  String _glassModeHint(bool autoUsesFakeGlass) {
    return autoUsesFakeGlass
        ? 'Recommended for emulator work: keep Auto or Fake.'
        : 'Recommended for physical devices: compare Auto and Real.';
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authServiceProvider).signOut();
    if (!context.mounted) {
      return;
    }
    context.go(AppRoutes.auth);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final settingsAsync = ref.watch(userSettingsProvider);
    final glassMode =
        ref.watch(glassModeOverrideProvider).value ?? GlassModeOverride.auto;
    final autoUsesFakeGlass = ref.watch(autoUseFakeGlassProvider).value ?? true;

    return Scaffold(
      appBar: const AdaptiveGlassAppBar(title: Text('Settings')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Use this screen for ghost mode, notifications, emergency stop, and sign out. For now it is the entry point only.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            AdaptiveGlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.blur_on_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Bottom bar glass',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _glassModeSubtitle(glassMode, autoUsesFakeGlass),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<GlassModeOverride>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment<GlassModeOverride>(
                        value: GlassModeOverride.auto,
                        label: Text('Auto'),
                      ),
                      ButtonSegment<GlassModeOverride>(
                        value: GlassModeOverride.fake,
                        label: Text('Fake'),
                      ),
                      ButtonSegment<GlassModeOverride>(
                        value: GlassModeOverride.real,
                        label: Text('Real'),
                      ),
                    ],
                    selected: {glassMode},
                    onSelectionChanged: (selection) {
                      if (selection.isEmpty) {
                        return;
                      }
                      ref
                          .read(glassModeOverrideProvider.notifier)
                          .setMode(selection.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _glassModeHint(autoUsesFakeGlass),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AdaptiveGlassCard(
              child: settingsAsync.when(
                data: (settings) {
                  final ghostMode = settings?.ghostMode ?? false;
                  final ghostUntil = settings?.ghostUntil;
                  final subtitle = ghostUntil == null
                      ? 'Hide your location until you turn it off.'
                      : 'Ghost mode active until ${ghostUntil.toLocal()}.';

                  return Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.visibility_off_outlined),
                        title: const Text('Ghost mode'),
                        subtitle: Text(subtitle),
                        value: ghostMode,
                        onChanged: (enabled) async {
                          await ref
                              .read(settingsServiceProvider)
                              .updateGhostMode(
                                enabled: enabled,
                                until: enabled
                                    ? DateTime.now().add(
                                        const Duration(hours: 1),
                                      )
                                    : null,
                              );
                          ref.invalidate(userSettingsProvider);
                        },
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.shield_outlined),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Pause sharing',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Turn on ghost mode immediately and keep it on until you change it manually.',
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: AdaptiveGlassPillButton(
                                onPressed: () async {
                                  await ref
                                      .read(settingsServiceProvider)
                                      .updateGhostMode(enabled: true);
                                  ref.invalidate(userSettingsProvider);
                                },
                                label: 'Enable',
                                compact: false,
                                tintColor: colors.primaryContainer,
                                foregroundColor: colors.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stackTrace) => ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: const Text('Could not load settings'),
                  subtitle: Text('$error'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AdaptiveGlassPillButton(
              onPressed: () => _signOut(context, ref),
              icon: const Icon(Icons.logout),
              label: 'Sign out',
              compact: false,
              expanded: true,
              tintColor: colors.errorContainer,
              foregroundColor: colors.onErrorContainer,
            ),
          ],
        ),
      ),
    );
  }
}

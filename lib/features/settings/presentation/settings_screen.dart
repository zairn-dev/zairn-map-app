import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/adaptive_glass_app_bar.dart';
import '../../../core/widgets/adaptive_glass_card.dart';
import '../../../core/widgets/adaptive_glass_pill_button.dart';
import '../../auth/data/auth_service.dart';
import '../data/settings_service.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

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

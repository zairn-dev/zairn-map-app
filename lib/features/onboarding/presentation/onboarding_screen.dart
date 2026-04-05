import 'package:flutter/material.dart';

import '../../../core/widgets/adaptive_glass_app_bar.dart';
import '../../../core/widgets/adaptive_glass_card.dart';
import '../../../core/widgets/adaptive_glass_pill_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: const AdaptiveGlassAppBar(title: Text('Onboarding')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Privacy-first social map',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'The Flutter core starts with auth, map, friends, and settings. Intimacy and post visibility layers come next.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                const _OnboardingStep(
                  icon: Icons.tune,
                  title: 'Design visibility first',
                  description:
                      'Treat visibility as expression, not just an access toggle.',
                ),
                const SizedBox(height: 12),
                const _OnboardingStep(
                  icon: Icons.map_outlined,
                  title: 'Treat location as an extension',
                  description:
                      'Location posts are layered on top of the visibility model.',
                ),
                const SizedBox(height: 12),
                const _OnboardingStep(
                  icon: Icons.shield_outlined,
                  title: 'Lock in safety early',
                  description:
                      'High precision and long-lived exposure stay restricted by default.',
                ),
                const SizedBox(height: 24),
                AdaptiveGlassPillButton(
                  onPressed: onContinue,
                  icon: const Icon(Icons.arrow_forward),
                  label: 'Continue to app',
                  compact: false,
                  expanded: true,
                  tintColor: colors.primaryContainer,
                  foregroundColor: colors.onPrimaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AdaptiveGlassCard(
      child: ListTile(
        leading: Icon(icon, color: colors.primary),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(description),
        ),
      ),
    );
  }
}

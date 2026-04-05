import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/adaptive_glass_app_bar.dart';
import '../../../core/widgets/adaptive_glass_icon_button.dart';
import '../../../core/widgets/adaptive_glass_avatar.dart';
import '../../../core/widgets/adaptive_glass_card.dart';
import '../../../core/widgets/adaptive_glass_pill_button.dart';
import '../../auth/providers/auth_state_provider.dart';
import '../data/profile.dart';
import '../data/profile_service.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  bool _saving = false;
  String? _loadedUserId;

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  void _syncControllers(UserProfile? profile, String userId) {
    if (_loadedUserId == userId) {
      return;
    }

    _loadedUserId = userId;
    _displayNameController.text = profile?.displayName ?? '';
    _usernameController.text = profile?.username ?? '';
    _avatarUrlController.text = profile?.avatarUrl ?? '';
  }

  Future<void> _saveProfile(String userId) async {
    if (_saving) {
      return;
    }

    setState(() => _saving = true);

    try {
      final profile = UserProfile(
        userId: userId,
        displayName: _displayNameController.text,
        username: _usernameController.text,
        avatarUrl: _avatarUrlController.text,
      );

      await ref.read(profileServiceProvider).upsertProfile(profile);
      ref.invalidate(userProfileProvider(userId));

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved.')));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save profile: $error')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final session = ref.watch(currentSessionProvider);

    if (session == null) {
      return const SafeArea(child: Center(child: Text('No active session.')));
    }

    final profileAsync = ref.watch(userProfileProvider(session.user.id));

    return Scaffold(
      appBar: AdaptiveGlassAppBar(
        title: const Text('Profile'),
        actions: [
          AdaptiveGlassIconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoutes.settings),
            size: 40,
            iconSize: 18,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Use this screen for profile editing, public handle setup, adult verification status, and avatar updates.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            AdaptiveGlassCard(
              child: ListTile(
                leading: _ProfileAvatarPreview(
                  displayName: _displayNameController.text,
                  avatarUrl: _avatarUrlController.text,
                ),
                title: Text(session.user.email ?? 'Signed-in user'),
                subtitle: Text(session.user.id, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(height: 12),
            profileAsync.when(
              data: (profile) {
                _syncControllers(profile, session.user.id);
                return AdaptiveGlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 4),
                      TextField(
                        controller: _displayNameController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Display name',
                          hintText: 'How your friends see you',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Handle',
                          hintText: 'public-handle',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _avatarUrlController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Avatar URL',
                          hintText: 'https://...',
                        ),
                      ),
                      const SizedBox(height: 16),
                      AdaptiveGlassPillButton(
                        onPressed: _saving
                            ? null
                            : () => _saveProfile(session.user.id),
                        icon: const Icon(Icons.save_outlined),
                        label: _saving ? 'Saving...' : 'Save profile',
                        compact: false,
                        expanded: true,
                        tintColor: theme.colorScheme.primaryContainer,
                        foregroundColor: theme.colorScheme.onPrimaryContainer,
                      ),
                    ],
                  ),
                );
              },
              loading: () => const AdaptiveGlassCard(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => AdaptiveGlassCard(
                child: ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: const Text('Could not load profile'),
                  subtitle: Text('$error'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AdaptiveGlassCard(
              child: ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('Age verification'),
                trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatarPreview extends StatelessWidget {
  const _ProfileAvatarPreview({
    required this.displayName,
    required this.avatarUrl,
  });

  final String displayName;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final trimmedName = displayName.trim();
    final initial = trimmedName.isEmpty ? '?' : trimmedName.substring(0, 1);
    final normalizedUrl = avatarUrl.trim();

    return AdaptiveGlassAvatar(
      size: 40,
      child: normalizedUrl.isEmpty
          ? Text(
              initial.toUpperCase(),
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            )
          : ClipOval(
              child: Image.network(
                normalizedUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Text(
                  initial.toUpperCase(),
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
    );
  }
}

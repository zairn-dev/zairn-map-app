import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/adaptive_glass_app_bar.dart';
import '../../../core/widgets/adaptive_glass_avatar.dart';
import '../../../core/widgets/adaptive_glass_card.dart';
import '../../../core/widgets/adaptive_glass_icon_button.dart';
import '../../../core/widgets/adaptive_glass_pill_button.dart';
import '../../profile/data/profile.dart';
import '../data/friend_models.dart';
import '../data/friends_service.dart';
import '../providers/friends_provider.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _searchController = TextEditingController();
  final _intimacyDrafts = <String, double>{};
  final _savingIntimacy = <String>{};
  List<UserProfile> _searchResults = const [];
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _invalidateAll() {
    ref.invalidate(incomingFriendRequestsProvider);
    ref.invalidate(sentFriendRequestsProvider);
    ref.invalidate(friendsListProvider);
    ref.invalidate(blockedUsersProvider);
  }

  Future<void> _runSearch() async {
    if (_searching) {
      return;
    }

    setState(() => _searching = true);
    try {
      final results = await ref
          .read(friendsServiceProvider)
          .searchProfiles(_searchController.text);
      if (!mounted) {
        return;
      }
      setState(() => _searchResults = results);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Search failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    try {
      await action();
      _invalidateAll();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Action failed: $error')));
    }
  }

  Future<void> _saveIntimacy(FriendEntry item, double value) async {
    final roundedValue = value.round().clamp(0, 100).toInt();
    setState(() {
      _intimacyDrafts[item.userId] = roundedValue.toDouble();
      _savingIntimacy.add(item.userId);
    });

    try {
      await ref
          .read(friendsServiceProvider)
          .updateIntimacyScore(item.userId, roundedValue);
      ref.invalidate(friendsListProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Intimacy updated to $roundedValue.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _intimacyDrafts[item.userId] = item.intimacyScore.toDouble();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update intimacy: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingIntimacy.remove(item.userId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final incomingAsync = ref.watch(incomingFriendRequestsProvider);
    final sentAsync = ref.watch(sentFriendRequestsProvider);
    final friendsAsync = ref.watch(friendsListProvider);
    final blockedAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: const AdaptiveGlassAppBar(title: Text('Friends')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Search by handle or display name, send requests, accept incoming requests, and manage connected users from one place.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            AdaptiveGlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Find people',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 420;
                      if (stacked) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                labelText: 'Handle or display name',
                                hintText: 'Search profiles',
                              ),
                              onSubmitted: (_) => _runSearch(),
                            ),
                            const SizedBox(height: 12),
                            AdaptiveGlassPillButton(
                              onPressed: _searching ? null : _runSearch,
                              icon: const Icon(Icons.search),
                              label: _searching ? 'Searching...' : 'Search',
                              compact: false,
                              expanded: true,
                              tintColor: colors.primaryContainer,
                              foregroundColor: colors.onPrimaryContainer,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                labelText: 'Handle or display name',
                                hintText: 'Search profiles',
                              ),
                              onSubmitted: (_) => _runSearch(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          AdaptiveGlassPillButton(
                            onPressed: _searching ? null : _runSearch,
                            icon: const Icon(Icons.search),
                            label: _searching ? 'Searching...' : 'Search',
                            compact: false,
                            tintColor: colors.primaryContainer,
                            foregroundColor: colors.onPrimaryContainer,
                          ),
                        ],
                      );
                    },
                  ),
                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ..._searchResults.map(
                      (profile) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const AdaptiveGlassAvatar(
                          child: Icon(Icons.person_outline),
                        ),
                        title: Text(_profileTitle(profile)),
                        subtitle: Text('@${profile.username ?? 'no-handle'}'),
                        trailing: AdaptiveGlassPillButton(
                          onPressed: () => _runAction(
                            () => ref
                                .read(friendsServiceProvider)
                                .sendFriendRequest(profile.userId),
                            successMessage: 'Friend request sent.',
                          ),
                          label: 'Add',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _AsyncSection<FriendRequestItem>(
              title: 'Incoming requests',
              asyncValue: incomingAsync,
              emptyText: 'No incoming requests.',
              itemBuilder: (context, item) => ListTile(
                leading: const AdaptiveGlassAvatar(
                  child: Icon(Icons.mail_outline),
                ),
                title: Text(_requestTitle(item)),
                subtitle: Text(item.otherUserId),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    AdaptiveGlassIconButton(
                      tooltip: 'Accept',
                      onPressed: () => _runAction(
                        () => ref
                            .read(friendsServiceProvider)
                            .acceptFriendRequest(item.request.id),
                        successMessage: 'Friend request accepted.',
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      tintColor: colors.primaryContainer,
                      foregroundColor: colors.onPrimaryContainer,
                    ),
                    AdaptiveGlassIconButton(
                      tooltip: 'Reject',
                      onPressed: () => _runAction(
                        () => ref
                            .read(friendsServiceProvider)
                            .rejectFriendRequest(item.request.id),
                        successMessage: 'Friend request rejected.',
                      ),
                      icon: const Icon(Icons.cancel_outlined),
                      tintColor: colors.errorContainer,
                      foregroundColor: colors.onErrorContainer,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _AsyncSection<FriendRequestItem>(
              title: 'Sent requests',
              asyncValue: sentAsync,
              emptyText: 'No pending sent requests.',
              itemBuilder: (context, item) => ListTile(
                leading: const AdaptiveGlassAvatar(
                  child: Icon(Icons.schedule_send),
                ),
                title: Text(_requestTitle(item)),
                subtitle: Text(item.otherUserId),
                trailing: AdaptiveGlassPillButton(
                  onPressed: () => _runAction(
                    () => ref
                        .read(friendsServiceProvider)
                        .cancelFriendRequest(item.request.id),
                    successMessage: 'Friend request canceled.',
                  ),
                  label: 'Cancel',
                ),
              ),
            ),
            const SizedBox(height: 16),
            _AsyncSection<FriendEntry>(
              title: 'Connected users',
              asyncValue: friendsAsync,
              emptyText: 'No connected users yet.',
              itemBuilder: (context, item) {
                final score =
                    (_intimacyDrafts[item.userId] ??
                            item.intimacyScore.toDouble())
                        .round();
                final isSaving = _savingIntimacy.contains(item.userId);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        leading: const AdaptiveGlassAvatar(
                          child: Icon(Icons.people_outline),
                        ),
                        contentPadding: EdgeInsets.zero,
                        title: Text(_entryTitle(item)),
                        subtitle: Text(_entrySubtitle(item)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Intimacy ${_intimacyLabel(score)}',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '$score',
                                  style: theme.textTheme.labelMedium,
                                ),
                              ],
                            ),
                            Slider(
                              value: score.toDouble(),
                              min: 0,
                              max: 100,
                              divisions: 100,
                              label: '$score',
                              onChanged: isSaving
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _intimacyDrafts[item.userId] = value;
                                      });
                                    },
                              onChangeEnd: isSaving
                                  ? null
                                  : (value) => _saveIntimacy(item, value),
                            ),
                            Wrap(
                              alignment: WrapAlignment.end,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (isSaving)
                                  Text(
                                    'Saving...',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                AdaptiveGlassPillButton(
                                  onPressed: () => _runAction(
                                    () => ref
                                        .read(friendsServiceProvider)
                                        .removeFriend(item.userId),
                                    successMessage: 'Friend removed.',
                                  ),
                                  label: 'Remove',
                                ),
                                AdaptiveGlassPillButton(
                                  onPressed: () => _runAction(
                                    () => ref
                                        .read(friendsServiceProvider)
                                        .blockUser(item.userId),
                                    successMessage: 'User blocked.',
                                  ),
                                  label: 'Block',
                                  tintColor: colors.errorContainer,
                                  foregroundColor: colors.onErrorContainer,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _AsyncSection<FriendEntry>(
              title: 'Blocked users',
              asyncValue: blockedAsync,
              emptyText: 'No blocked users.',
              itemBuilder: (context, item) => ListTile(
                leading: const AdaptiveGlassAvatar(child: Icon(Icons.block)),
                title: Text(_entryTitle(item)),
                subtitle: Text(item.userId),
                trailing: AdaptiveGlassPillButton(
                  onPressed: () => _runAction(
                    () => ref
                        .read(friendsServiceProvider)
                        .unblockUser(item.userId),
                    successMessage: 'User unblocked.',
                  ),
                  label: 'Unblock',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _profileTitle(UserProfile profile) {
    return profile.displayName ?? profile.username ?? profile.userId;
  }

  String _requestTitle(FriendRequestItem item) {
    return item.profile?.displayName ??
        item.profile?.username ??
        item.otherUserId;
  }

  String _entryTitle(FriendEntry item) {
    return item.profile?.displayName ?? item.profile?.username ?? item.userId;
  }

  String _entrySubtitle(FriendEntry item) {
    final handle = item.profile?.username;
    if (handle == null || handle.isEmpty) {
      return item.userId;
    }
    return '@$handle';
  }

  String _intimacyLabel(int score) {
    if (score >= 85) {
      return 'Inner';
    }
    if (score >= 65) {
      return 'Close';
    }
    if (score >= 45) {
      return 'Friend';
    }
    if (score >= 25) {
      return 'Casual';
    }
    return 'Guarded';
  }
}

class _AsyncSection<T> extends StatelessWidget {
  const _AsyncSection({
    required this.title,
    required this.asyncValue,
    required this.emptyText,
    required this.itemBuilder,
  });

  final String title;
  final AsyncValue<List<T>> asyncValue;
  final String emptyText;
  final Widget Function(BuildContext context, T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdaptiveGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          asyncValue.when(
            data: (items) {
              if (items.isEmpty) {
                return Text(emptyText);
              }
              return Column(
                children: items
                    .map((item) => itemBuilder(context, item))
                    .toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stackTrace) => ListTile(
              leading: const Icon(Icons.error_outline),
              title: const Text('Failed to load'),
              subtitle: Text('$error'),
            ),
          ),
        ],
      ),
    );
  }
}

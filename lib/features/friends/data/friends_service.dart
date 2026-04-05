import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';
import '../../profile/data/profile.dart';
import '../../profile/data/profile_service.dart';
import 'friend_models.dart';
import 'friend_request_record.dart';

final friendsServiceProvider = Provider<FriendsService>((ref) {
  return FriendsService(profileService: ref.watch(profileServiceProvider));
});

class FriendsService {
  const FriendsService({required this.profileService});

  final ProfileService profileService;
  static const int defaultIntimacyScore = 20;

  String get _currentUserId {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      throw StateError('Not authenticated');
    }
    return user.id;
  }

  Future<List<UserProfile>> searchProfiles(String query) async {
    final sanitized = query
        .replaceAll(RegExp(r'[%_,.()"\\]'), '')
        .replaceAll("'", '')
        .trim();
    if (sanitized.isEmpty) {
      return const [];
    }

    final currentUserId = _currentUserId;
    final response = await SupabaseService.client
        .from('profiles')
        .select('user_id, username, display_name, avatar_url')
        .or('username.ilike.%$sanitized%,display_name.ilike.%$sanitized%')
        .limit(20);

    return (response as List<dynamic>)
        .map((row) => UserProfile.fromMap(row as Map<String, dynamic>))
        .where((profile) => profile.userId != currentUserId)
        .toList();
  }

  Future<void> sendFriendRequest(String toUserId) async {
    final fromUserId = _currentUserId;
    if (toUserId == fromUserId) {
      throw ArgumentError('Cannot send a friend request to yourself.');
    }

    await SupabaseService.client.from('friend_requests').insert({
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
    });
  }

  Future<List<FriendRequestItem>> getIncomingRequests() async {
    final userId = _currentUserId;
    final response = await SupabaseService.client
        .from('friend_requests')
        .select('id, from_user_id, to_user_id, status, created_at')
        .eq('to_user_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    final requests = (response as List<dynamic>)
        .map((row) => FriendRequestRecord.fromMap(row as Map<String, dynamic>))
        .toList();

    final profiles = await profileService.getProfilesByIds(
      requests.map((request) => request.fromUserId).toSet().toList(),
    );
    final profilesById = {
      for (final profile in profiles) profile.userId: profile,
    };

    return requests
        .map(
          (request) => FriendRequestItem(
            request: request,
            otherUserId: request.fromUserId,
            profile: profilesById[request.fromUserId],
          ),
        )
        .toList();
  }

  Future<List<FriendRequestItem>> getSentRequests() async {
    final userId = _currentUserId;
    final response = await SupabaseService.client
        .from('friend_requests')
        .select('id, from_user_id, to_user_id, status, created_at')
        .eq('from_user_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    final requests = (response as List<dynamic>)
        .map((row) => FriendRequestRecord.fromMap(row as Map<String, dynamic>))
        .toList();

    final profiles = await profileService.getProfilesByIds(
      requests.map((request) => request.toUserId).toSet().toList(),
    );
    final profilesById = {
      for (final profile in profiles) profile.userId: profile,
    };

    return requests
        .map(
          (request) => FriendRequestItem(
            request: request,
            otherUserId: request.toUserId,
            profile: profilesById[request.toUserId],
          ),
        )
        .toList();
  }

  Future<void> acceptFriendRequest(int requestId) async {
    await SupabaseService.client.rpc(
      'accept_friend_request',
      params: {'p_request_id': requestId},
    );
  }

  Future<void> rejectFriendRequest(int requestId) async {
    final userId = _currentUserId;
    await SupabaseService.client
        .from('friend_requests')
        .update({
          'status': 'rejected',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId)
        .eq('to_user_id', userId);
  }

  Future<void> cancelFriendRequest(int requestId) async {
    final userId = _currentUserId;
    await SupabaseService.client
        .from('friend_requests')
        .delete()
        .eq('id', requestId)
        .eq('from_user_id', userId);
  }

  Future<List<FriendEntry>> getFriends() async {
    final userId = _currentUserId;
    final response = await SupabaseService.client
        .from('friend_requests')
        .select('from_user_id, to_user_id')
        .eq('status', 'accepted')
        .or('from_user_id.eq.$userId,to_user_id.eq.$userId');

    final rows = response as List<dynamic>;
    final friendIds = rows
        .map((row) => row as Map<String, dynamic>)
        .map(
          (row) => row['from_user_id'] == userId
              ? row['to_user_id'] as String
              : row['from_user_id'] as String,
        )
        .toSet()
        .toList();

    final intimacyScores = await _getIntimacyScores(friendIds);
    final profiles = await profileService.getProfilesByIds(friendIds);
    final profilesById = {
      for (final profile in profiles) profile.userId: profile,
    };

    return friendIds
        .map(
          (friendId) => FriendEntry(
            userId: friendId,
            profile: profilesById[friendId],
            intimacyScore:
                intimacyScores[friendId] ?? FriendsService.defaultIntimacyScore,
          ),
        )
        .toList();
  }

  Future<Map<String, int>> _getIntimacyScores(List<String> friendIds) async {
    if (friendIds.isEmpty) {
      return const {};
    }

    try {
      final response = await SupabaseService.client
          .from('relationship_settings')
          .select('target_id, intimacy_score')
          .eq('owner_id', _currentUserId)
          .inFilter('target_id', friendIds);

      final rows = response as List<dynamic>;
      return {
        for (final row in rows)
          (row as Map<String, dynamic>)['target_id'] as String:
              ((row['intimacy_score'] as num?)?.toInt() ??
              FriendsService.defaultIntimacyScore),
      };
    } on PostgrestException catch (error) {
      if (error.message.contains('relationship_settings')) {
        return const {};
      }
      rethrow;
    }
  }

  Future<void> updateIntimacyScore(String friendId, int intimacyScore) async {
    if (friendId == _currentUserId) {
      throw ArgumentError('Cannot set intimacy for yourself.');
    }
    if (intimacyScore < 0 || intimacyScore > 100) {
      throw ArgumentError('Intimacy score must be between 0 and 100.');
    }

    await SupabaseService.client.rpc(
      'set_relationship_intimacy',
      params: {'p_target_id': friendId, 'p_intimacy_score': intimacyScore},
    );
  }

  Future<void> removeFriend(String friendId) async {
    await SupabaseService.client.rpc(
      'remove_friend',
      params: {'p_friend_id': friendId},
    );
  }

  Future<void> blockUser(String blockedUserId) async {
    await SupabaseService.client.rpc(
      'block_user_atomic',
      params: {'p_blocked_id': blockedUserId},
    );
  }

  Future<void> unblockUser(String blockedUserId) async {
    final userId = _currentUserId;
    await SupabaseService.client
        .from('blocked_users')
        .delete()
        .eq('blocker_id', userId)
        .eq('blocked_id', blockedUserId);
  }

  Future<List<FriendEntry>> getBlockedUsers() async {
    final userId = _currentUserId;
    final response = await SupabaseService.client
        .from('blocked_users')
        .select('blocked_id')
        .eq('blocker_id', userId);

    final blockedIds = (response as List<dynamic>)
        .map((row) => (row as Map<String, dynamic>)['blocked_id'] as String)
        .toList();

    final profiles = await profileService.getProfilesByIds(blockedIds);
    final profilesById = {
      for (final profile in profiles) profile.userId: profile,
    };

    return blockedIds
        .map(
          (blockedId) =>
              FriendEntry(userId: blockedId, profile: profilesById[blockedId]),
        )
        .toList();
  }
}

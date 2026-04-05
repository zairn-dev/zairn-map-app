import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';
import 'profile.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return const ProfileService();
});

class ProfileService {
  const ProfileService();

  Future<UserProfile?> getProfile(String userId) async {
    final response = await SupabaseService.client
        .from('profiles')
        .select('user_id, username, display_name, avatar_url')
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return UserProfile.fromMap(response);
  }

  Future<UserProfile> upsertProfile(UserProfile profile) async {
    final response = await SupabaseService.client
        .from('profiles')
        .upsert(profile.toUpsertMap())
        .select('user_id, username, display_name, avatar_url')
        .single();

    return UserProfile.fromMap(response);
  }

  Future<List<UserProfile>> getProfilesByIds(List<String> userIds) async {
    if (userIds.isEmpty) {
      return const [];
    }

    final response = await SupabaseService.client
        .from('profiles')
        .select('user_id, username, display_name, avatar_url')
        .inFilter('user_id', userIds);

    return (response as List<dynamic>)
        .map((row) => UserProfile.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}

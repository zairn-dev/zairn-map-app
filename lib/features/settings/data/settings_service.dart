import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';
import 'user_settings.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return const SettingsService();
});

class SettingsService {
  const SettingsService();

  String get _currentUserId {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      throw StateError('Not authenticated');
    }
    return user.id;
  }

  Future<UserSettingsRecord?> getSettings() async {
    final response = await SupabaseService.client
        .from('user_settings')
        .select('user_id, ghost_mode, ghost_until, location_update_interval')
        .eq('user_id', _currentUserId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return UserSettingsRecord.fromMap(response);
  }

  Future<UserSettingsRecord> updateGhostMode({
    required bool enabled,
    DateTime? until,
  }) async {
    final response = await SupabaseService.client
        .from('user_settings')
        .upsert({
          'user_id': _currentUserId,
          'ghost_mode': enabled,
          'ghost_until': enabled ? until?.toIso8601String() : null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select('user_id, ghost_mode, ghost_until, location_update_interval')
        .single();

    return UserSettingsRecord.fromMap(response);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../services/supabase_service.dart';
import '../../profile/data/profile_service.dart';
import 'map_models.dart';

final mapServiceProvider = Provider<MapService>((ref) {
  return MapService(profileService: ref.watch(profileServiceProvider));
});

class MapService {
  const MapService({required this.profileService});

  final ProfileService profileService;

  String get _currentUserId {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      throw StateError('Not authenticated');
    }
    return user.id;
  }

  Future<MapSnapshot> getMapSnapshot() async {
    final currentUserId = _currentUserId;

    final myLocationResponse = await SupabaseService.client
        .from('locations_current')
        .select('user_id, lat, lon, accuracy, updated_at')
        .eq('user_id', currentUserId)
        .maybeSingle();

    final visibleResponse = await SupabaseService.client
        .from('locations_current')
        .select('user_id, lat, lon, accuracy, updated_at')
        .order('updated_at', ascending: false);

    final myLocation = myLocationResponse == null
        ? null
        : LocationRecord.fromMap(myLocationResponse);

    final visibleRows = (visibleResponse as List<dynamic>)
        .map((row) => LocationRecord.fromMap(row as Map<String, dynamic>))
        .where((row) => row.userId != currentUserId)
        .toList();

    final profiles = await profileService.getProfilesByIds(
      visibleRows.map((row) => row.userId).toSet().toList(),
    );
    final profilesById = {
      for (final profile in profiles) profile.userId: profile,
    };

    return MapSnapshot(
      myLocation: myLocation,
      visibleFriends: visibleRows
          .map(
            (row) => VisibleFriendLocation(
              location: row,
              profile: profilesById[row.userId],
            ),
          )
          .toList(),
    );
  }

  Future<void> shareCenterPoint(LatLng target) async {
    final ghostModeActive = await _isGhostModeActive();
    if (ghostModeActive) {
      throw StateError(
        'Ghost mode is active. Turn it off before sharing a location.',
      );
    }

    await SupabaseService.client.from('locations_current').upsert({
      'user_id': _currentUserId,
      'lat': target.latitude,
      'lon': target.longitude,
      'accuracy': 200,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<bool> _isGhostModeActive() async {
    final response = await SupabaseService.client
        .from('user_settings')
        .select('ghost_mode, ghost_until')
        .eq('user_id', _currentUserId)
        .maybeSingle();

    if (response == null) {
      return false;
    }

    final ghostMode = (response['ghost_mode'] as bool?) ?? false;
    if (!ghostMode) {
      return false;
    }

    final ghostUntilRaw = response['ghost_until'];
    if (ghostUntilRaw == null) {
      return true;
    }

    final ghostUntil = switch (ghostUntilRaw) {
      final DateTime value => value,
      final String value => DateTime.tryParse(value),
      _ => null,
    };
    if (ghostUntil == null) {
      return true;
    }

    return ghostUntil.isAfter(DateTime.now());
  }
}

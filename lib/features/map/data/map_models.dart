import 'package:maplibre_gl/maplibre_gl.dart';

import '../../profile/data/profile.dart';

class LocationRecord {
  const LocationRecord({
    required this.userId,
    required this.lat,
    required this.lon,
    required this.updatedAt,
    this.accuracy,
  });

  final String userId;
  final double lat;
  final double lon;
  final double? accuracy;
  final DateTime updatedAt;

  LatLng get point => LatLng(lat, lon);

  factory LocationRecord.fromMap(Map<String, dynamic> map) {
    return LocationRecord(
      userId: map['user_id'] as String,
      lat: (map['lat'] as num).toDouble(),
      lon: (map['lon'] as num).toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      updatedAt: _parseDateTime(map['updated_at']),
    );
  }

  static DateTime _parseDateTime(Object? value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class VisibleFriendLocation {
  const VisibleFriendLocation({required this.location, this.profile});

  final LocationRecord location;
  final UserProfile? profile;

  String get title =>
      profile?.displayName ?? profile?.username ?? location.userId;
}

class MapSnapshot {
  const MapSnapshot({this.myLocation, this.visibleFriends = const []});

  final LocationRecord? myLocation;
  final List<VisibleFriendLocation> visibleFriends;
}

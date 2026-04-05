class UserSettingsRecord {
  const UserSettingsRecord({
    required this.userId,
    required this.ghostMode,
    this.ghostUntil,
    required this.locationUpdateInterval,
  });

  final String userId;
  final bool ghostMode;
  final DateTime? ghostUntil;
  final int locationUpdateInterval;

  factory UserSettingsRecord.fromMap(Map<String, dynamic> map) {
    return UserSettingsRecord(
      userId: map['user_id'] as String,
      ghostMode: (map['ghost_mode'] as bool?) ?? false,
      ghostUntil: map['ghost_until'] == null
          ? null
          : DateTime.tryParse(map['ghost_until'] as String),
      locationUpdateInterval: (map['location_update_interval'] as int?) ?? 30,
    );
  }
}

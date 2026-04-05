class UserProfile {
  const UserProfile({
    required this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  final String userId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['user_id'] as String,
      username: map['username'] as String?,
      displayName: map['display_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toUpsertMap() {
    return {
      'user_id': userId,
      'username': _nullIfBlank(username),
      'display_name': _nullIfBlank(displayName),
      'avatar_url': _nullIfBlank(avatarUrl),
    };
  }

  UserProfile copyWith({
    String? username,
    String? displayName,
    String? avatarUrl,
  }) {
    return UserProfile(
      userId: userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  static String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}

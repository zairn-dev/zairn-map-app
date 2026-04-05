enum PostViewerTier { hidden, partial, full }

class FeedPost {
  const FeedPost({
    required this.postId,
    required this.authorId,
    this.authorUsername,
    this.authorDisplayName,
    this.text,
    this.imageUrl,
    required this.visibilityValue,
    required this.expiresAt,
    required this.createdAt,
    required this.viewerTier,
    required this.isAuthor,
    this.lat,
    this.lon,
    this.locationRadiusM,
    this.locationBlurLevel,
  });

  final String postId;
  final String authorId;
  final String? authorUsername;
  final String? authorDisplayName;
  final String? text;
  final String? imageUrl;
  final int visibilityValue;
  final DateTime expiresAt;
  final DateTime createdAt;
  final PostViewerTier viewerTier;
  final bool isAuthor;
  final double? lat;
  final double? lon;
  final int? locationRadiusM;
  final int? locationBlurLevel;

  String get authorLabel => authorDisplayName ?? authorUsername ?? authorId;
  bool get hasLocation =>
      lat != null &&
      lon != null &&
      locationRadiusM != null &&
      locationBlurLevel != null;

  factory FeedPost.fromMap(Map<String, dynamic> map) {
    return FeedPost(
      postId: map['post_id'] as String,
      authorId: map['author_id'] as String,
      authorUsername: map['author_username'] as String?,
      authorDisplayName: map['author_display_name'] as String?,
      text: map['text'] as String?,
      imageUrl: map['image_url'] as String?,
      visibilityValue: ((map['visibility_value'] as num?) ?? 50).toInt(),
      expiresAt: _parseDateTime(map['expires_at']),
      createdAt: _parseDateTime(map['created_at']),
      viewerTier: _parseViewerTier(map['viewer_tier'] as String?),
      isAuthor: (map['is_author'] as bool?) ?? false,
      lat: (map['lat'] as num?)?.toDouble(),
      lon: (map['lon'] as num?)?.toDouble(),
      locationRadiusM: (map['location_radius_m'] as num?)?.toInt(),
      locationBlurLevel: (map['location_blur_level'] as num?)?.toInt(),
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

  static PostViewerTier _parseViewerTier(String? value) {
    return switch (value) {
      'full' => PostViewerTier.full,
      'partial' => PostViewerTier.partial,
      _ => PostViewerTier.hidden,
    };
  }
}

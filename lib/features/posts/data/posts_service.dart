import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';
import 'post_models.dart';

final postsServiceProvider = Provider<PostsService>((ref) {
  return const PostsService();
});

class PostsService {
  const PostsService();

  static const _postImagesBucket = 'post-images';
  static const _maxImageBytes = 8 * 1024 * 1024;
  static const _allowedImageExtensions = <String>{
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
  };

  String get _currentUserId {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      throw StateError('Not authenticated');
    }
    return user.id;
  }

  Future<List<FeedPost>> getFeed({int limit = 50}) async {
    final response = await SupabaseService.client.rpc(
      'get_post_feed',
      params: {'p_limit': limit},
    );

    if (response == null) {
      return const [];
    }

    return (response as List<dynamic>)
        .map((row) => FeedPost.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> createPost({
    required String text,
    required int visibilityValue,
    required DateTime expiresAt,
    Uint8List? imageBytes,
    String? imageName,
    String? imageContentType,
    bool attachSharedLocation = false,
    int? locationRadiusM,
    int? locationBlurLevel,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && imageBytes == null) {
      throw ArgumentError('Post must contain text or an image.');
    }
    if (visibilityValue < 0 || visibilityValue > 100) {
      throw ArgumentError('Visibility value must be between 0 and 100.');
    }

    String? imageUrl;
    if (imageBytes != null) {
      imageUrl = await _uploadPostImage(
        bytes: imageBytes,
        fileName: imageName,
        contentType: imageContentType,
      );
    }

    Map<String, dynamic>? locationPayload;
    if (attachSharedLocation) {
      locationPayload = await _buildLocationPayload(
        radiusM: locationRadiusM,
        blurLevel: locationBlurLevel,
      );
    }

    try {
      await SupabaseService.client.from('posts').insert({
        'author_id': _currentUserId,
        'text': trimmed.isEmpty ? null : trimmed,
        'image_url': imageUrl,
        'visibility_value': visibilityValue,
        'expires_at': expiresAt.toIso8601String(),
        ...?locationPayload,
      });
    } catch (error) {
      if (imageUrl != null) {
        await _deletePostImage(imageUrl);
      }
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    final existing = await SupabaseService.client
        .from('posts')
        .select('image_url')
        .eq('id', postId)
        .eq('author_id', _currentUserId)
        .maybeSingle();

    await SupabaseService.client
        .from('posts')
        .delete()
        .eq('id', postId)
        .eq('author_id', _currentUserId);

    final imageUrl = existing?['image_url'] as String?;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      await _deletePostImage(imageUrl);
    }
  }

  Future<String> _uploadPostImage({
    required Uint8List bytes,
    String? fileName,
    String? contentType,
  }) async {
    if (bytes.isEmpty) {
      throw ArgumentError('Image data is empty.');
    }
    if (bytes.length > _maxImageBytes) {
      throw ArgumentError('Image is too large. Max size is 8MB.');
    }

    final extension = _resolveExtension(fileName, contentType);
    final effectiveContentType = _resolveContentType(extension, contentType);
    final safeBaseName = _safeBaseName(fileName);
    final filePath =
        '$_currentUserId/${DateTime.now().millisecondsSinceEpoch}_$safeBaseName.$extension';

    await SupabaseService.client.storage
        .from(_postImagesBucket)
        .uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(
            contentType: effectiveContentType,
            upsert: false,
          ),
        );

    return SupabaseService.client.storage
        .from(_postImagesBucket)
        .getPublicUrl(filePath);
  }

  Future<void> _deletePostImage(String publicUrl) async {
    final filePath = _extractStoragePath(publicUrl);
    if (filePath == null) {
      return;
    }

    try {
      await SupabaseService.client.storage.from(_postImagesBucket).remove([
        filePath,
      ]);
    } on StorageException {
      // Best-effort cleanup. Missing files should not block post operations.
    }
  }

  String _resolveExtension(String? fileName, String? contentType) {
    final name = fileName ?? '';
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex >= 0 && dotIndex < name.length - 1) {
      final extension = name.substring(dotIndex + 1).toLowerCase();
      if (_allowedImageExtensions.contains(extension)) {
        return extension == 'jpeg' ? 'jpg' : extension;
      }
    }

    return switch (contentType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/heic' => 'heic',
      'image/heif' => 'heif',
      _ => 'jpg',
    };
  }

  String _resolveContentType(String extension, String? contentType) {
    if (contentType != null && contentType.startsWith('image/')) {
      return contentType;
    }

    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => 'image/jpeg',
    };
  }

  String _safeBaseName(String? fileName) {
    final name = fileName ?? 'post';
    final dotIndex = name.lastIndexOf('.');
    final base = dotIndex > 0 ? name.substring(0, dotIndex) : name;
    final sanitized = base.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    if (sanitized.isEmpty) {
      return 'post';
    }
    return sanitized;
  }

  String? _extractStoragePath(String publicUrl) {
    final uri = Uri.tryParse(publicUrl);
    if (uri == null) {
      return null;
    }

    final segments = uri.pathSegments;
    final bucketIndex = segments.indexOf(_postImagesBucket);
    if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) {
      return null;
    }

    return segments.sublist(bucketIndex + 1).join('/');
  }

  Future<Map<String, dynamic>> _buildLocationPayload({
    int? radiusM,
    int? blurLevel,
  }) async {
    final response = await SupabaseService.client
        .from('locations_current')
        .select('lat, lon')
        .eq('user_id', _currentUserId)
        .maybeSingle();

    if (response == null) {
      throw StateError(
        'No shared location found. Share your point on the map before attaching it to a post.',
      );
    }

    final effectiveRadius = radiusM ?? 200;
    final effectiveBlur = blurLevel ?? 1;

    if (effectiveRadius <= 0) {
      throw ArgumentError('Location radius must be greater than 0.');
    }
    if (effectiveBlur < 0 || effectiveBlur > 3) {
      throw ArgumentError('Location blur level must be between 0 and 3.');
    }

    return {
      'lat': (response['lat'] as num).toDouble(),
      'lon': (response['lon'] as num).toDouble(),
      'location_radius_m': effectiveRadius,
      'location_blur_level': effectiveBlur,
    };
  }
}

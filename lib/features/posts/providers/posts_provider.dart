import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/post_models.dart';
import '../data/posts_service.dart';

final feedPostsProvider = FutureProvider<List<FeedPost>>((ref) async {
  final service = ref.watch(postsServiceProvider);
  return service.getFeed();
});

final locationFeedPostsProvider = FutureProvider<List<FeedPost>>((ref) async {
  final posts = await ref.watch(feedPostsProvider.future);
  return posts.where((post) => post.hasLocation).toList();
});

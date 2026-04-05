import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/friend_models.dart';
import '../data/friends_service.dart';

final incomingFriendRequestsProvider = FutureProvider<List<FriendRequestItem>>((
  ref,
) async {
  final service = ref.watch(friendsServiceProvider);
  return service.getIncomingRequests();
});

final sentFriendRequestsProvider = FutureProvider<List<FriendRequestItem>>((
  ref,
) async {
  final service = ref.watch(friendsServiceProvider);
  return service.getSentRequests();
});

final friendsListProvider = FutureProvider<List<FriendEntry>>((ref) async {
  final service = ref.watch(friendsServiceProvider);
  return service.getFriends();
});

final blockedUsersProvider = FutureProvider<List<FriendEntry>>((ref) async {
  final service = ref.watch(friendsServiceProvider);
  return service.getBlockedUsers();
});

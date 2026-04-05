import '../../profile/data/profile.dart';
import 'friend_request_record.dart';

class FriendRequestItem {
  const FriendRequestItem({
    required this.request,
    required this.otherUserId,
    this.profile,
  });

  final FriendRequestRecord request;
  final String otherUserId;
  final UserProfile? profile;
}

class FriendEntry {
  const FriendEntry({
    required this.userId,
    this.profile,
    this.intimacyScore = 20,
  });

  final String userId;
  final UserProfile? profile;
  final int intimacyScore;
}

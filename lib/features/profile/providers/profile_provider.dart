import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile.dart';
import '../data/profile_service.dart';

final userProfileProvider = FutureProvider.family<UserProfile?, String>((
  ref,
  userId,
) async {
  final service = ref.watch(profileServiceProvider);
  return service.getProfile(userId);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_service.dart';
import '../data/user_settings.dart';

final userSettingsProvider = FutureProvider<UserSettingsRecord?>((ref) async {
  final service = ref.watch(settingsServiceProvider);
  return service.getSettings();
});

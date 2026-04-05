import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GlassModeOverride { auto, fake, real }

extension GlassModeOverrideX on GlassModeOverride {
  String get label => switch (this) {
    GlassModeOverride.auto => 'Auto',
    GlassModeOverride.fake => 'Fake',
    GlassModeOverride.real => 'Real',
  };
}

const _glassModePreferenceKey = 'debug.glass_mode_override';

final autoUseFakeGlassProvider = FutureProvider<bool>((ref) async {
  if (kIsWeb) {
    return true;
  }

  final deviceInfo = DeviceInfoPlugin();

  try {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        !(await deviceInfo.androidInfo).isPhysicalDevice,
      TargetPlatform.iOS => !(await deviceInfo.iosInfo).isPhysicalDevice,
      TargetPlatform.macOS => false,
      _ => true,
    };
  } catch (_) {
    return true;
  }
});

final glassModeOverrideProvider =
    AsyncNotifierProvider<GlassModeOverrideNotifier, GlassModeOverride>(
      GlassModeOverrideNotifier.new,
    );

final resolvedUseFakeGlassProvider = Provider<bool>((ref) {
  final autoUseFakeGlass = ref.watch(autoUseFakeGlassProvider).value ?? true;
  final glassMode =
      ref.watch(glassModeOverrideProvider).value ?? GlassModeOverride.auto;

  return switch (glassMode) {
    GlassModeOverride.auto => autoUseFakeGlass,
    GlassModeOverride.fake => true,
    GlassModeOverride.real => false,
  };
});

class GlassModeOverrideNotifier extends AsyncNotifier<GlassModeOverride> {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  @override
  Future<GlassModeOverride> build() async {
    final storedValue = await _preferences.getString(_glassModePreferenceKey);

    return GlassModeOverride.values.firstWhere(
      (mode) => mode.name == storedValue,
      orElse: () => GlassModeOverride.auto,
    );
  }

  Future<void> setMode(GlassModeOverride mode) async {
    state = AsyncData(mode);
    await _preferences.setString(_glassModePreferenceKey, mode.name);
  }
}

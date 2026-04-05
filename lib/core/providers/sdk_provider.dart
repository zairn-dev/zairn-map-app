import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zairn_sdk/zairn_sdk.dart';

import '../config/app_config.dart';

/// Global ZairnSdk instance provider.
final sdkProvider = Provider<ZairnSdk>((ref) {
  throw UnimplementedError(
    'sdkProvider must be overridden after ZairnSdk.create()',
  );
});

/// Creates and returns a configured ZairnSdk instance.
Future<ZairnSdk> initializeSdk() async {
  return ZairnSdk.create(
    config: ZairnConfig(
      supabaseUrl: AppConfig.supabaseUrl,
      supabaseAnonKey: AppConfig.supabaseAnonKey,
      suppressRealtimeRlsWarning: true,
    ),
  );
}

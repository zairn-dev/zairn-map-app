import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app/zairn_app.dart';
import 'core/providers/sdk_provider.dart';
import 'services/supabase_service.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await SupabaseService.initialize();
  final sdk = await initializeSdk();

  FlutterNativeSplash.remove();

  runApp(
    ProviderScope(
      overrides: [
        sdkProvider.overrideWithValue(sdk),
      ],
      child: const ZairnApp(),
    ),
  );
}

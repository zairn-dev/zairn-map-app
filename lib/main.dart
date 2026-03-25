import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'screens/map_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const ZairnMapApp());
}

class ZairnMapApp extends StatefulWidget {
  const ZairnMapApp({super.key});

  @override
  State<ZairnMapApp> createState() => _ZairnMapAppState();
}

class _ZairnMapAppState extends State<ZairnMapApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Remove native splash once Flutter is rendered
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zairn',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: _showSplash
          ? SplashScreen(
              onComplete: () => setState(() => _showSplash = false),
            )
          : const MapScreen(),
    );
  }
}

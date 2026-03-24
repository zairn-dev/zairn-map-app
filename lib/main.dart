import 'package:flutter/material.dart';
import 'screens/map_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ZairnMapApp());
}

class ZairnMapApp extends StatelessWidget {
  const ZairnMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zairn Map',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:maplibre_gl/maplibre_gl.dart';

import '../theme/app_theme.dart';

enum MapStyle { wafuu, standard }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapLibreMapController? _mapController;
  bool _isLocating = false;
  MapStyle _currentStyle = MapStyle.wafuu;
  bool _terrainEnabled = false;
  String? _wafuuStyle;
  String? _wafuuTerrainStyle;
  String? _standardStyle;
  ui.FragmentShader? _vignetteShader;

  static const LatLng _initialCenter = LatLng(35.6812, 139.7671);
  static const double _initialZoom = 12.0;

  @override
  void initState() {
    super.initState();
    _loadStyles();
    _loadShader();
  }

  Future<void> _loadStyles() async {
    if (kIsWeb) {
      final wafuu = await rootBundle.loadString('assets/map_style_wafuu_raster.json');
      final standard = await rootBundle.loadString('assets/map_style_standard_raster.json');
      setState(() {
        _wafuuStyle = wafuu;
        _wafuuTerrainStyle = wafuu;
        _standardStyle = standard;
      });
    } else {
      final wafuu = await rootBundle.loadString('assets/map_style_wafuu.json');
      final wafuuTerrain = await rootBundle.loadString('assets/map_style_wafuu_terrain.json');
      setState(() {
        _wafuuStyle = wafuu;
        _wafuuTerrainStyle = wafuuTerrain;
        _standardStyle = 'https://tiles.openfreemap.org/styles/liberty';
      });
    }
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset('shaders/vignette.frag');
      setState(() => _vignetteShader = program.fragmentShader());
    } catch (_) {}
  }

  String? get _styleString {
    if (_currentStyle == MapStyle.wafuu) {
      return _terrainEnabled ? _wafuuTerrainStyle : _wafuuStyle;
    }
    return _standardStyle;
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
  }

  void _toggleStyle() {
    setState(() {
      _currentStyle = _currentStyle == MapStyle.wafuu
          ? MapStyle.standard
          : MapStyle.wafuu;
    });
  }

  void _toggleTerrain() {
    setState(() => _terrainEnabled = !_terrainEnabled);
  }

  Future<void> _goToCurrentLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          const CameraPosition(target: _initialCenter, zoom: 15.0),
        ),
      );
    } finally {
      setState(() => _isLocating = false);
    }
  }

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleString;
    if (style == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isWafuu = _currentStyle == MapStyle.wafuu;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──
          MapLibreMap(
            key: ValueKey('${_currentStyle}_${_terrainEnabled}_$kIsWeb'),
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: _initialCenter,
              zoom: _initialZoom,
            ),
            styleString: style,
            myLocationEnabled: !kIsWeb,
            myLocationTrackingMode: MyLocationTrackingMode.none,
            trackCameraPosition: true,
          ),

          // ── Vignette overlay ──
          if (isWafuu && _vignetteShader != null && !kIsWeb)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _VignettePainter(shader: _vignetteShader!),
                ),
              ),
            ),

          // ── Right controls ──
          Positioned(
            right: AppSpacing.md,
            bottom: AppSpacing.xl + MediaQuery.of(context).padding.bottom,
            child: Column(
              children: [
                if (isWafuu && !kIsWeb) ...[
                  _MapControl(
                    icon: Icons.terrain,
                    onPressed: _toggleTerrain,
                    active: _terrainEnabled,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                _MapControl(
                  icon: Icons.add,
                  onPressed: _zoomIn,
                ),
                const SizedBox(height: AppSpacing.sm),
                _MapControl(
                  icon: Icons.remove,
                  onPressed: _zoomOut,
                ),
                const SizedBox(height: AppSpacing.sm),
                _MapControl(
                  icon: _isLocating ? Icons.hourglass_top : Icons.my_location,
                  onPressed: _goToCurrentLocation,
                  accent: true,
                ),
              ],
            ),
          ),

          // ── Style toggle ──
          Positioned(
            right: AppSpacing.md,
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            child: _MapControl(
              icon: Icons.layers,
              onPressed: _toggleStyle,
            ),
          ),

          // ── Title badge ──
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            left: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Zairn',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────
// Map control button
// Uses: surface / primaryContainer (active)
// ──────────────────────────────────────
class _MapControl extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool active;
  final bool accent;

  const _MapControl({
    required this.icon,
    required this.onPressed,
    this.active = false,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Color bg;
    Color fg;
    if (active) {
      bg = colors.primaryContainer;
      fg = colors.onPrimaryContainer;
    } else if (accent) {
      bg = colors.primary;
      fg = colors.onPrimary;
    } else {
      bg = colors.surface;
      fg = colors.onSurfaceVariant;
    }

    return Material(
      elevation: 2,
      shadowColor: colors.shadow.withValues(alpha: 0.3),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      color: bg,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md - 4),
          child: Icon(icon, size: 22, color: fg),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────
// Vignette shader painter
// ──────────────────────────────────────
class _VignettePainter extends CustomPainter {
  final ui.FragmentShader shader;

  _VignettePainter({required this.shader});

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant _VignettePainter oldDelegate) => false;
}

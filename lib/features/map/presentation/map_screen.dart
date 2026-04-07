import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/navigation/adaptive_liquid_glass.dart';
import '../../../core/widgets/adaptive_glass_card.dart';
import '../../../core/widgets/adaptive_glass_pill_button.dart';
import '../../../services/glyph_server.dart';
import '../../posts/data/post_models.dart';
import '../../posts/providers/posts_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../data/map_models.dart';
import '../data/map_service.dart';
import '../providers/map_provider.dart';
import '../../../theme/app_theme.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  static const _remoteGlyphsUrl =
      'https://otanl.github.io/zairn-glyphs/{fontstack}/{range}.pbf';

  final GlyphServer _glyphServer = GlyphServer();
  MapLibreMapController? _mapController;
  bool _isLocating = false;
  bool _isRefreshing = false;
  bool _isSharing = false;
  bool _styleLoaded = false;
  bool _didCenterOnSharedLocation = false;
  bool _panelExpanded = false;
  String? _wafuuStyle;
  ui.FragmentShader? _vignetteShader;
  late final AnimationController _pulseController;
  LatLng _cameraTarget = _initialCenter;
  MapFocusTarget? _pendingFocusTarget;
  String? _handledFocusRequestId;
  final Map<String, FeedPost> _locationPostsById = {};
  FeedPost? _selectedLocationPost;

  static const LatLng _initialCenter = LatLng(35.6812, 139.7671);
  static const double _initialZoom = 12.0;

  @override
  void initState() {
    super.initState();
    _loadStyles();
    _loadShader();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _mapController?.onCircleTapped.remove(_handleCircleTapped);
    unawaited(_glyphServer.stop());
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadStyles() async {
    if (kIsWeb) {
      final wafuu = await rootBundle.loadString(
        'assets/map_style_wafuu_raster.json',
      );
      if (!mounted) {
        return;
      }
      setState(() => _wafuuStyle = wafuu);
    } else {
      final wafuu = await rootBundle.loadString('assets/map_style_wafuu.json');
      var resolvedStyle = wafuu;
      try {
        await _glyphServer.start();
        resolvedStyle = wafuu.replaceAll(
          _remoteGlyphsUrl,
          _glyphServer.glyphsUrl,
        );
      } catch (_) {
        resolvedStyle = wafuu;
      }
      if (!mounted) {
        return;
      }
      setState(() => _wafuuStyle = resolvedStyle);
    }
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/vignette.frag',
      );
      setState(() => _vignetteShader = program.fragmentShader());
    } catch (_) {}
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController?.onCircleTapped.remove(_handleCircleTapped);
    _mapController = controller;
    controller.onCircleTapped.add(_handleCircleTapped);
    _styleLoaded = false;
  }

  void _handleCircleTapped(Circle circle) {
    final data = circle.data;
    if (data == null || data['kind'] != 'post') {
      if (_selectedLocationPost != null) {
        setState(() => _selectedLocationPost = null);
      }
      return;
    }

    final postId = data['postId'] as String?;
    if (postId == null) {
      return;
    }
    final post = _locationPostsById[postId];
    if (post == null) {
      return;
    }

    setState(() => _selectedLocationPost = post);
  }

  void _onCameraIdle() {
    final target = _mapController?.cameraPosition?.target;
    if (target == null) {
      return;
    }

    setState(() => _cameraTarget = target);
  }

  void _onStyleLoaded() {
    _styleLoaded = true;
    unawaited(
      _syncAnnotations(
        snapshot: ref.read(mapSnapshotProvider).asData?.value,
        locationPosts: ref.read(locationFeedPostsProvider).asData?.value,
      ),
    );
    unawaited(_consumePendingFocusTarget());
  }

  Future<void> _focusOnTarget(MapFocusTarget target) async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded) {
      _pendingFocusTarget = target;
      return;
    }

    _pendingFocusTarget = null;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target.point, zoom: target.zoom),
      ),
    );
  }

  Future<void> _consumePendingFocusTarget() async {
    final target = _pendingFocusTarget;
    if (target == null) {
      return;
    }
    await _focusOnTarget(target);
  }

  Future<void> _goToCurrentLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      final snapshot = ref.read(mapSnapshotProvider).asData?.value;
      final target = snapshot?.myLocation?.point ?? _cameraTarget;
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 15.0),
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

  Future<void> _refreshMapData() async {
    if (_isRefreshing) {
      return;
    }

    setState(() => _isRefreshing = true);
    try {
      ref.invalidate(mapSnapshotProvider);
      ref.invalidate(feedPostsProvider);
      ref.invalidate(locationFeedPostsProvider);
      await ref.read(mapSnapshotProvider.future);
      await ref.read(locationFeedPostsProvider.future);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Refresh failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _shareCenterPoint() async {
    if (_isSharing) {
      return;
    }

    setState(() => _isSharing = true);
    try {
      await ref.read(mapServiceProvider).shareCenterPoint(_cameraTarget);
      ref.invalidate(mapSnapshotProvider);
      ref.invalidate(userSettingsProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Center point shared.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Share failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _syncAnnotations({
    required MapSnapshot? snapshot,
    required List<FeedPost>? locationPosts,
  }) async {
    final controller = _mapController;
    if (!_styleLoaded || controller == null) {
      return;
    }

    try {
      await controller.clearCircles();
      _locationPostsById
        ..clear()
        ..addEntries(
          (locationPosts ?? const <FeedPost>[]).map(
            (post) => MapEntry(post.postId, post),
          ),
        );
      if (_selectedLocationPost != null &&
          !_locationPostsById.containsKey(_selectedLocationPost!.postId) &&
          mounted) {
        setState(() => _selectedLocationPost = null);
      }
      if (snapshot == null) {
        return;
      }

      final circles = <CircleOptions>[
        if (snapshot.myLocation != null)
          CircleOptions(
            geometry: snapshot.myLocation!.point,
            circleRadius: 8,
            circleColor: '#FF9800',
            circleOpacity: 0.95,
            circleStrokeWidth: 3,
            circleStrokeColor: '#FFFFFF',
          ),
        ...snapshot.visibleFriends.map(
          (friend) => CircleOptions(
            geometry: friend.location.point,
            circleRadius: 7,
            circleColor: '#00E5CC',
            circleOpacity: 0.9,
            circleStrokeWidth: 2,
            circleStrokeColor: '#00332E',
          ),
        ),
        ...?locationPosts?.map(
          (post) => CircleOptions(
            geometry: LatLng(post.lat!, post.lon!),
            circleRadius: _postCircleRadius(post),
            circleColor: _postCircleColor(post),
            circleOpacity: _postCircleOpacity(post),
            circleBlur: _postCircleBlur(post),
            circleStrokeWidth: 2,
            circleStrokeColor: '#FFFFFF',
          ),
        ),
      ];
      final circleData = <Map<String, dynamic>>[
        if (snapshot.myLocation != null) {'kind': 'self'},
        ...snapshot.visibleFriends.map(
          (friend) => {'kind': 'friend', 'userId': friend.location.userId},
        ),
        ...?locationPosts?.map(
          (post) => {'kind': 'post', 'postId': post.postId},
        ),
      ];

      if (circles.isEmpty) {
        return;
      }

      await controller.addCircles(circles, circleData);
    } catch (_) {}
  }

  Future<void> _maybeCenterOnSharedLocation(MapSnapshot snapshot) async {
    final controller = _mapController;
    if (_didCenterOnSharedLocation ||
        snapshot.myLocation == null ||
        controller == null) {
      return;
    }

    _didCenterOnSharedLocation = true;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: snapshot.myLocation!.point, zoom: 14.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<MapSnapshot>>(mapSnapshotProvider, (previous, next) {
      next.whenData((snapshot) {
        unawaited(
          _syncAnnotations(
            snapshot: snapshot,
            locationPosts: ref.read(locationFeedPostsProvider).asData?.value,
          ),
        );
        unawaited(_maybeCenterOnSharedLocation(snapshot));
      });
    });
    ref.listen<AsyncValue<List<FeedPost>>>(locationFeedPostsProvider, (
      previous,
      next,
    ) {
      next.whenData((posts) {
        unawaited(
          _syncAnnotations(
            snapshot: ref.read(mapSnapshotProvider).asData?.value,
            locationPosts: posts,
          ),
        );
      });
    });

    final style = _wafuuStyle;
    if (style == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final mapSnapshotAsync = ref.watch(mapSnapshotProvider);
    final locationPostsAsync = ref.watch(locationFeedPostsProvider);
    final requestedFocus = ref.watch(mapFocusTargetProvider);
    final settings = ref.watch(userSettingsProvider).asData?.value;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final topPad = MediaQuery.paddingOf(context).top;
    final ghostUntil = settings?.ghostUntil;
    final ghostModeActive =
        (settings?.ghostMode ?? false) &&
        (ghostUntil == null || ghostUntil.isAfter(DateTime.now()));
    final selectedLocationPost = _selectedLocationPost;
    final controlsBottom =
        (selectedLocationPost == null ? 100 : 244) + bottomPad;

    if (requestedFocus != null &&
        requestedFocus.requestId != _handledFocusRequestId) {
      _handledFocusRequestId = requestedFocus.requestId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ref.read(mapFocusTargetProvider.notifier).clear();
        unawaited(_focusOnTarget(requestedFocus));
      });
    }

    return LiquidGlassLayer(
      settings: const LiquidGlassSettings(
        thickness: 14,
        blur: 12,
        glassColor: Color(0x20FFFFFF),
        refractiveIndex: 1.08,
      ),
      child: Stack(
        children: [
          MapLibreMap(
            key: ValueKey('map_$kIsWeb'),
          onMapCreated: _onMapCreated,
          onCameraIdle: _onCameraIdle,
          onMapClick: (_, __) {
            if (_selectedLocationPost != null) {
              setState(() => _selectedLocationPost = null);
            }
          },
          onStyleLoadedCallback: _onStyleLoaded,
          initialCameraPosition: const CameraPosition(
            target: _initialCenter,
            zoom: _initialZoom,
          ),
          styleString: style,
          annotationOrder: const [AnnotationType.circle],
          annotationConsumeTapEvents: const [AnnotationType.circle],
          myLocationEnabled: false,
          myLocationTrackingMode: MyLocationTrackingMode.none,
          trackCameraPosition: true,
        ),
        if (_vignetteShader != null && !kIsWeb)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _VignettePainter(shader: _vignetteShader!),
              ),
            ),
          ),
        Center(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final pulse =
                    (math.sin(_pulseController.value * 2 * math.pi) + 1) / 2;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 32 + pulse * 16,
                      height: 32 + pulse * 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.brandCyan.withValues(
                          alpha: 0.15 * (1 - pulse),
                        ),
                      ),
                    ),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.brandCyan, AppTheme.brandTeal],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.brandCyan.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        Positioned(
          right: AppSpacing.md,
          bottom: controlsBottom,
          child: Column(
            children: [
              _GlassButton(
                icon: _isRefreshing ? Icons.sync : Icons.refresh,
                onPressed: _refreshMapData,
              ),
              const SizedBox(height: AppSpacing.sm),
              _GlassButton(icon: Icons.add, onPressed: _zoomIn),
              const SizedBox(height: AppSpacing.sm),
              _GlassButton(icon: Icons.remove, onPressed: _zoomOut),
              const SizedBox(height: AppSpacing.sm),
              _GradientButton(
                icon: _isLocating ? Icons.hourglass_top : Icons.my_location,
                onPressed: _goToCurrentLocation,
              ),
            ],
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          top: topPad + AppSpacing.sm,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: _GlassPanel(
              expanded: _panelExpanded,
              child: _buildPanel(
                context: context,
                mapSnapshotAsync: mapSnapshotAsync,
                locationPostsAsync: locationPostsAsync,
                ghostModeActive: ghostModeActive,
                panelExpanded: _panelExpanded,
                onTogglePanel: () {
                  setState(() => _panelExpanded = !_panelExpanded);
                },
              ),
            ),
          ),
        ),
        if (selectedLocationPost != null)
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: 92 + bottomPad,
            child: _SelectedLocationPostCard(
              post: selectedLocationPost,
              onClose: () => setState(() => _selectedLocationPost = null),
              onFocus: () => unawaited(
                _focusOnTarget(
                  MapFocusTarget(
                    requestId:
                        '${selectedLocationPost.postId}:${DateTime.now().microsecondsSinceEpoch}',
                    point: LatLng(
                      selectedLocationPost.lat!,
                      selectedLocationPost.lon!,
                    ),
                    zoom: _focusZoomFor(selectedLocationPost),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel({
    required BuildContext context,
    required AsyncValue<MapSnapshot> mapSnapshotAsync,
    required AsyncValue<List<FeedPost>> locationPostsAsync,
    required bool ghostModeActive,
    required bool panelExpanded,
    required VoidCallback onTogglePanel,
  }) {
    final colors = Theme.of(context).colorScheme;

    if (mapSnapshotAsync.hasError) {
      return _ErrorPanel(
        title: 'Map data failed to load',
        message: '${mapSnapshotAsync.error}',
        onRetry: _refreshMapData,
      );
    }
    if (locationPostsAsync.hasError) {
      return _ErrorPanel(
        title: 'Location posts failed to load',
        message: '${locationPostsAsync.error}',
        onRetry: _refreshMapData,
      );
    }
    if (mapSnapshotAsync.isLoading || locationPostsAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final snapshot = mapSnapshotAsync.asData!.value;
    final locationPosts = locationPostsAsync.asData!.value;

    return _CompactMapStatusPanel(
      cameraTarget: _cameraTarget,
      snapshot: snapshot,
      locationPosts: locationPosts,
      onSelectLocationPost: (post) {
        setState(() => _selectedLocationPost = post);
        unawaited(
          _focusOnTarget(
            MapFocusTarget(
              requestId:
                  '${post.postId}:${DateTime.now().microsecondsSinceEpoch}',
              point: LatLng(post.lat!, post.lon!),
              zoom: _focusZoomFor(post),
            ),
          ),
        );
      },
      ghostModeActive: ghostModeActive,
      expanded: panelExpanded,
      isSharing: _isSharing,
      onRefresh: _refreshMapData,
      onShareCenter: _shareCenterPoint,
      onToggle: onTogglePanel,
      panelTextColor: colors.onSurfaceVariant,
    );
  }

  double _postCircleRadius(FeedPost post) {
    final base = switch (post.viewerTier) {
      PostViewerTier.full => 10.0,
      PostViewerTier.partial => 12.0,
      PostViewerTier.hidden => 9.0,
    };
    final radiusBoost = switch (post.locationRadiusM ?? 0) {
      >= 1000 => 4.0,
      >= 500 => 3.0,
      >= 200 => 2.0,
      _ => 1.0,
    };
    return base + radiusBoost;
  }

  String _postCircleColor(FeedPost post) {
    return switch (post.viewerTier) {
      PostViewerTier.full => '#FF2D78',
      PostViewerTier.partial => '#FFAB00',
      PostViewerTier.hidden => '#B0BEC5',
    };
  }

  double _postCircleOpacity(FeedPost post) {
    return switch (post.viewerTier) {
      PostViewerTier.full => 0.85,
      PostViewerTier.partial => 0.72,
      PostViewerTier.hidden => 0.5,
    };
  }

  double _postCircleBlur(FeedPost post) {
    final blurLevel = post.locationBlurLevel ?? 0;
    return switch (blurLevel) {
      0 => 0.08,
      1 => 0.2,
      2 => 0.34,
      _ => 0.46,
    };
  }

  double _focusZoomFor(FeedPost post) {
    final radius = post.locationRadiusM ?? 200;
    if (radius >= 1000) {
      return 12.8;
    }
    if (radius >= 500) {
      return 13.4;
    }
    if (radius >= 200) {
      return 14.2;
    }
    return 15.0;
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onPressed,
      child: LiquidGlass(
        shape: const LiquidOval(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, size: 22, color: colors.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.primaryContainer,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, size: 22, color: colors.onPrimaryContainer),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child, required this.expanded});

  final Widget child;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = expanded ? 18.0 : 999.0;

    final shape = LiquidRoundedSuperellipse(
      borderRadius: radius,
      side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.32)),
    );

    return LiquidGlass(
      shape: shape,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: colors.surface.withValues(alpha: 0.12),
          shape: shape,
        ),
        child: child,
      ),
    );
  }
}

class _MapStatusPanel extends StatelessWidget {
  const _MapStatusPanel({
    required this.cameraTarget,
    required this.snapshot,
    required this.locationPosts,
    required this.ghostModeActive,
    required this.isSharing,
    required this.onRefresh,
    required this.onShareCenter,
    required this.panelTextColor,
  });

  final LatLng cameraTarget;
  final MapSnapshot snapshot;
  final List<FeedPost> locationPosts;
  final bool ghostModeActive;
  final bool isSharing;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onShareCenter;
  final Color panelTextColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final visibleFriends = snapshot.visibleFriends;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _InfoPill(label: 'Center', value: _formatLatLng(cameraTarget)),
              _InfoPill(
                label: 'My share',
                value: snapshot.myLocation == null
                    ? 'not shared'
                    : _formatTime(snapshot.myLocation!.updatedAt),
              ),
              _InfoPill(
                label: 'Visible',
                value: '${visibleFriends.length} people',
              ),
              _InfoPill(
                label: 'Posts',
                value: '${locationPosts.length} active',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (ghostModeActive)
            AdaptiveGlassCard(
              borderRadius: 12,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 4,
                vertical: AppSpacing.sm,
              ),
              glassAlpha: 0.16,
              borderAlpha: 0.24,
              child: Text(
                'Ghost mode is on. Turn it off in Settings to share from the map.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: panelTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (ghostModeActive) const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AdaptiveGlassPillButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: 'Refresh',
                compact: false,
              ),
              AdaptiveGlassPillButton(
                onPressed: ghostModeActive || isSharing ? null : onShareCenter,
                icon: Icon(isSharing ? Icons.hourglass_top : Icons.publish),
                label: ghostModeActive
                    ? 'Share disabled'
                    : isSharing
                    ? 'Sharing...'
                    : 'Share point',
                compact: false,
                tintColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Visible friends',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (visibleFriends.isEmpty)
            Text(
              'No visible friends yet. Accept a friend request and share a point to test the flow.',
              style: theme.textTheme.bodyMedium,
            )
          else
            ...visibleFriends
                .take(3)
                .map(
                  (friend) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.brandCyan,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            friend.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          _formatTime(friend.location.updatedAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          if (visibleFriends.length > 3)
            Text(
              '+${visibleFriends.length - 3} more visible friends',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Location posts',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (locationPosts.isEmpty)
            Text(
              'No active location posts. Create one from Feed after sharing your point here.',
              style: theme.textTheme.bodyMedium,
            )
          else
            ...locationPosts
                .take(3)
                .map(
                  (post) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _postColor(post),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.authorLabel,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${post.locationRadiusM}m / ${_blurLabel(post.locationBlurLevel ?? 0)} / ${_tierLabel(post.viewerTier)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatTime(post.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          if (locationPosts.length > 3)
            Text(
              '+${locationPosts.length - 3} more location posts',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  static String _formatLatLng(LatLng target) {
    return '${target.latitude.toStringAsFixed(4)}, ${target.longitude.toStringAsFixed(4)}';
  }

  static String _formatTime(DateTime value) {
    final delta = DateTime.now().difference(value);
    if (delta.inMinutes < 1) {
      return 'just now';
    }
    if (delta.inHours < 1) {
      return '${delta.inMinutes}m ago';
    }
    if (delta.inDays < 1) {
      return '${delta.inHours}h ago';
    }
    return '${delta.inDays}d ago';
  }

  static String _blurLabel(int level) {
    return switch (level) {
      0 => 'exact',
      1 => 'soft',
      2 => 'area',
      _ => 'wide',
    };
  }

  static String _tierLabel(PostViewerTier tier) {
    return switch (tier) {
      PostViewerTier.full => 'full',
      PostViewerTier.partial => 'partial',
      PostViewerTier.hidden => 'hidden',
    };
  }

  static Color _postColor(FeedPost post) {
    return switch (post.viewerTier) {
      PostViewerTier.full => AppTheme.brandPink,
      PostViewerTier.partial => AppTheme.brandAmber,
      PostViewerTier.hidden => const Color(0xFF78909C),
    };
  }
}

class _CompactMapStatusPanel extends StatelessWidget {
  const _CompactMapStatusPanel({
    required this.cameraTarget,
    required this.snapshot,
    required this.locationPosts,
    required this.onSelectLocationPost,
    required this.ghostModeActive,
    required this.expanded,
    required this.isSharing,
    required this.onRefresh,
    required this.onShareCenter,
    required this.onToggle,
    required this.panelTextColor,
  });

  final LatLng cameraTarget;
  final MapSnapshot snapshot;
  final List<FeedPost> locationPosts;
  final ValueChanged<FeedPost> onSelectLocationPost;
  final bool ghostModeActive;
  final bool expanded;
  final bool isSharing;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onShareCenter;
  final VoidCallback onToggle;
  final Color panelTextColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final visibleFriends = snapshot.visibleFriends;
    final shareSummary = snapshot.myLocation == null
        ? 'Not shared yet'
        : 'Shared ${_MapStatusPanel._formatTime(snapshot.myLocation!.updatedAt)}';
    final summaryLabel =
        '${visibleFriends.length} visible / ${locationPosts.length} posts';
    final panelPadding = expanded
        ? const EdgeInsets.fromLTRB(12, 8, 12, 10)
        : const EdgeInsets.fromLTRB(12, 7, 10, 7);

    return Padding(
      padding: panelPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _CompactPanelToggleButton(
                expanded: expanded,
                onPressed: onToggle,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${visibleFriends.length} visible · ${locationPosts.length} posts',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (expanded) ...[
                      const SizedBox(height: 2),
                      Text(
                        shareSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: panelTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (ghostModeActive) ...[
                const SizedBox(width: 6),
                _CompactStatusBadge(
                  label: 'Ghost',
                  color: colors.surfaceContainerHighest,
                  textColor: colors.onSurfaceVariant,
                ),
              ],
              const SizedBox(width: 6),
              _CompactPanelActionChip(
                icon: isSharing ? Icons.hourglass_top : Icons.publish,
                label: ghostModeActive
                    ? 'Locked'
                    : isSharing
                    ? '...'
                    : 'Share',
                enabled: !ghostModeActive && !isSharing,
                onPressed: ghostModeActive || isSharing ? null : onShareCenter,
              ),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _InfoPill(
                  label: 'My share',
                  value: snapshot.myLocation == null
                      ? 'not shared'
                      : _MapStatusPanel._formatTime(
                          snapshot.myLocation!.updatedAt,
                        ),
                ),
                _InfoPill(
                  label: 'Visible',
                  value: '${visibleFriends.length} people',
                ),
                _InfoPill(
                  label: 'Posts',
                  value: '${locationPosts.length} active',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AdaptiveGlassPillButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: 'Refresh',
                ),
                Tooltip(
                  message: summaryLabel,
                  child: Text(
                    _MapStatusPanel._formatLatLng(cameraTarget),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (ghostModeActive) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sharing is paused. Turn it back on in Settings.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: panelTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Location posts',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (locationPosts.isEmpty)
              Text(
                'No active location posts.',
                style: theme.textTheme.bodyMedium,
              )
            else
              ...locationPosts
                  .take(2)
                  .map(
                    (post) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Material(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => onSelectLocationPost(post),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _MapStatusPanel._postColor(post),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post.authorLabel,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${post.locationRadiusM}m / ${_MapStatusPanel._blurLabel(post.locationBlurLevel ?? 0)} / ${_MapStatusPanel._tierLabel(post.viewerTier)}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: colors.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  _MapStatusPanel._formatTime(post.createdAt),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
            if (locationPosts.length > 2)
              Text(
                '+${locationPosts.length - 2} more location posts',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CompactPanelToggleButton extends StatelessWidget {
  const _CompactPanelToggleButton({
    required this.expanded,
    required this.onPressed,
  });

  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            size: 18,
            color: colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _CompactPanelActionChip extends StatelessWidget {
  const _CompactPanelActionChip({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Opacity(
      opacity: enabled ? 1 : 0.65,
      child: Material(
        color: enabled
            ? colors.primaryContainer
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: enabled
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: enabled
                        ? colors.onPrimaryContainer
                        : colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactStatusBadge extends StatelessWidget {
  const _CompactStatusBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return AdaptiveGlassCard(
      borderRadius: 999,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      glassAlpha: 0.22,
      borderAlpha: 0.22,
      tintColor: color,
      borderColor: color,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AdaptiveGlassPillButton(
            onPressed: onRetry,
            label: 'Retry',
            compact: false,
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AdaptiveGlassCard(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      glassAlpha: 0.18,
      borderAlpha: 0.28,
      tintColor: colors.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedLocationPostCard extends ConsumerWidget {
  const _SelectedLocationPostCard({
    required this.post,
    required this.onClose,
    required this.onFocus,
  });

  final FeedPost post;
  final VoidCallback onClose;
  final VoidCallback onFocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final profileAsync = ref.watch(userProfileProvider(post.authorId));
    final avatarUrl = profileAsync.asData?.value?.avatarUrl;
    final shape = LiquidRoundedSuperellipse(
      borderRadius: 20,
      side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.42)),
    );

    return LiquidGlass(
      shape: shape,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: colors.surface.withValues(alpha: 0.14),
          shape: shape,
        ),
        child: Material(
          color: Colors.transparent,
        child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MapPostAvatar(
                      label: post.authorLabel,
                      avatarUrl: avatarUrl,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorLabel,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_MapStatusPanel._formatTime(post.createdAt)}  •  ${post.locationRadiusM}m',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                      iconSize: 18,
                    ),
                  ],
                ),
                if (post.text != null && post.text!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    post.text!,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                  ),
                ],
                if (post.imageUrl != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 96,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (post.viewerTier == PostViewerTier.partial)
                            ImageFiltered(
                              imageFilter: ui.ImageFilter.blur(
                                sigmaX: 12,
                                sigmaY: 12,
                              ),
                              child: Image.network(
                                post.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: colors.surfaceContainerHighest,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.broken_image_outlined,
                                      ),
                                    ),
                              ),
                            )
                          else
                            Image.network(
                              post.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: colors.surfaceContainerHighest,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                    ),
                                  ),
                            ),
                          if (post.viewerTier == PostViewerTier.partial)
                            Container(
                              alignment: Alignment.center,
                              color: colors.scrim.withValues(alpha: 0.12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.inverseSurface.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Partial image',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: colors.onInverseSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _FeedMetaChip(label: _tierLabel(post.viewerTier)),
                    _FeedMetaChip(
                      label:
                          '${post.locationRadiusM}m / ${_MapStatusPanel._blurLabel(post.locationBlurLevel ?? 0)}',
                    ),
                    _FeedMetaChip(label: 'Open ${post.visibilityValue}'),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AdaptiveGlassPillButton(
                        onPressed: onFocus,
                        icon: const Icon(Icons.center_focus_strong),
                        label: 'Center on map',
                        compact: false,
                        expanded: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _tierLabel(PostViewerTier tier) {
    return switch (tier) {
      PostViewerTier.full => 'Full',
      PostViewerTier.partial => 'Partial',
      PostViewerTier.hidden => 'Hidden',
    };
  }
}

class _MapPostAvatar extends StatelessWidget {
  const _MapPostAvatar({required this.label, this.avatarUrl});

  final String label;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final trimmed = label.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : trimmed.substring(0, 1).toUpperCase();

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.secondaryContainer,
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl != null && avatarUrl!.trim().isNotEmpty
          ? Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  initial,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onSecondaryContainer,
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                initial,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.onSecondaryContainer,
                ),
              ),
            ),
    );
  }
}

class _FeedMetaChip extends StatelessWidget {
  const _FeedMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AdaptiveGlassCard(
      borderRadius: 999,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      glassAlpha: 0.22,
      borderAlpha: 0.24,
      tintColor: colors.secondaryContainer,
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: colors.onSecondaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _VignettePainter extends CustomPainter {
  _VignettePainter({required this.shader});

  final ui.FragmentShader shader;

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _VignettePainter oldDelegate) => false;
}

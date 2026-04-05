import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../data/map_models.dart';
import '../data/map_service.dart';

final mapSnapshotProvider = FutureProvider<MapSnapshot>((ref) async {
  final service = ref.watch(mapServiceProvider);
  return service.getMapSnapshot();
});

class MapFocusTarget {
  const MapFocusTarget({
    required this.requestId,
    required this.point,
    required this.zoom,
  });

  final String requestId;
  final LatLng point;
  final double zoom;
}

class MapFocusTargetNotifier extends Notifier<MapFocusTarget?> {
  @override
  MapFocusTarget? build() => null;

  void setTarget(MapFocusTarget target) {
    state = target;
  }

  void clear() {
    state = null;
  }
}

final mapFocusTargetProvider =
    NotifierProvider<MapFocusTargetNotifier, MapFocusTarget?>(
      MapFocusTargetNotifier.new,
    );

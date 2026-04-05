import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zairn_sdk/zairn_sdk.dart';

import 'sdk_provider.dart';

/// Background location tracking state and controller.
final backgroundLocationProvider =
    NotifierProvider<BackgroundLocationNotifier, LocationTrackingState>(
  BackgroundLocationNotifier.new,
);

/// Friend locations from realtime subscription.
final friendLocationsProvider =
    StreamProvider<List<LocationCurrent>>((ref) {
  final sdk = ref.watch(sdkProvider);
  final controller = StreamController<List<LocationCurrent>>();

  sdk.getFriendsLocations().then(
    (locations) => controller.add(locations),
    onError: (e) => controller.addError(e),
  );

  final subscription = sdk.subscribeLocations(
    (location) async {
      try {
        final locations = await sdk.getFriendsLocations();
        controller.add(locations);
      } catch (e) {
        controller.addError(e);
      }
    },
  );

  ref.onDispose(() {
    subscription.unsubscribe();
    controller.close();
  });

  return controller.stream;
});

class LocationTrackingState {
  final bool isTracking;
  final LocationUpdate? lastUpdate;

  const LocationTrackingState({
    this.isTracking = false,
    this.lastUpdate,
  });

  LocationTrackingState copyWith({
    bool? isTracking,
    LocationUpdate? lastUpdate,
  }) {
    return LocationTrackingState(
      isTracking: isTracking ?? this.isTracking,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

class BackgroundLocationNotifier extends Notifier<LocationTrackingState> {
  final BackgroundLocationService _locationService = BackgroundLocationService();

  @override
  LocationTrackingState build() => const LocationTrackingState();

  Future<bool> requestPermission() async {
    return _locationService.requestPermission();
  }

  Future<void> startTracking() async {
    final sdk = ref.read(sdkProvider);

    await _locationService.start(
      onLocation: (update) {
        state = state.copyWith(lastUpdate: update);
        sdk.sendLocation(update);
      },
      intervalMs: 60000,
      distanceFilter: 10,
    );

    state = state.copyWith(isTracking: true);
  }

  Future<void> stopTracking() async {
    _locationService.stop();
    state = state.copyWith(isTracking: false);
  }
}

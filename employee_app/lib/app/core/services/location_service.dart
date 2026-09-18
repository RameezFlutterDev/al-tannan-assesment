import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum LocationFailureReason {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

class LocationResult {
  const LocationResult.success(this.position) : failureReason = null;
  const LocationResult.failure(LocationFailureReason reason)
      : failureReason = reason,
        position = null;

  final Position? position;
  final LocationFailureReason? failureReason;

  bool get isSuccess => position != null;
}

/// Thin wrapper around `geolocator`: handles the permission/service-enabled
/// flow and returns one of [LocationFailureReason] for every way it can go
/// wrong, so the UI can show a specific, actionable message per the
/// assessment's required "permission-denied" / "GPS unavailable" states.
class LocationService {
  /// Triggers the OS permission dialog on app launch, so it's already
  /// resolved by the time the user taps a check-in/check-out action instead
  /// of appearing then. Permission and the location-service (GPS) toggle are
  /// independent on Android, so this deliberately does NOT gate on
  /// [Geolocator.isLocationServiceEnabled] — [getCurrentPosition] surfaces
  /// that separately, with an actionable message, at the point the user
  /// actually needs a fix.
  Future<void> requestPermissionOnLaunch() async {
    if (await Geolocator.checkPermission() == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  Future<LocationResult> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult.failure(LocationFailureReason.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationResult.failure(LocationFailureReason.permissionDenied);
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationResult.failure(
        LocationFailureReason.permissionDeniedForever,
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return LocationResult.success(position);
    } on TimeoutException catch (_) {
      return const LocationResult.failure(LocationFailureReason.timeout);
    } catch (_) {
      return const LocationResult.failure(LocationFailureReason.unknown);
    }
  }
}

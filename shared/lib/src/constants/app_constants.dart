/// Cross-cutting defaults and thresholds. Every value here is intentionally
/// a *default*, not a hard-coded rule — admins can override grace period and
/// geofence radius per shift/location; the anti-spoofing thresholds are the
/// ones documented in README.md as configurable server-side policy.
abstract final class AppConstants {
  static const defaultGraceMinutes = 5;
  static const defaultGeofenceRadiusMeters = 150.0;

  /// GPS accuracy (meters) worse than this flags [IntegrityResult.lowAccuracy].
  static const lowAccuracyThresholdMeters = 50.0;

  /// Client-reported timestamp more than this many seconds from the
  /// server's clock flags [IntegrityResult.staleLocation].
  static const staleLocationThresholdSeconds = 120;

  /// Implied speed (km/h) between an employee's last accepted attendance
  /// event and the new one, above which the movement is physically
  /// implausible and flags [IntegrityResult.impossibleMovement].
  static const maxPlausibleSpeedKmh = 200.0;
}

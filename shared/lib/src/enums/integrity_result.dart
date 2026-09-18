/// Outcome of the server-side location-integrity checks run on every
/// attendance action. Stored on every `AttendanceEvent`, accepted or not,
/// so admins can audit exactly why an action was blocked or flagged.
///
/// Computed on-device (there is no application server) and, for the
/// results that must hard-block (see [isHardBlock]), independently
/// re-checked by firestore.rules before the write is allowed. See
/// README.md's "Location Integrity & Anti-Spoofing" section for the
/// documented policy per result.
enum IntegrityResult {
  /// No integrity concerns detected.
  ok('ok'),

  /// The device reported the location as mocked/simulated
  /// (`Position.isMocked` on Android). Hard-blocked.
  mockLocationDetected('mock_location_detected'),

  /// The reported speed since the employee's last accepted attendance
  /// event exceeds what is physically plausible. Hard-blocked.
  impossibleMovement('impossible_movement'),

  /// GPS accuracy is worse than the configured threshold. Flagged, not
  /// blocked, since real-world GPS accuracy legitimately varies.
  lowAccuracy('low_accuracy'),

  /// The client-reported timestamp is too far from the server's clock.
  /// Flagged, not blocked.
  staleLocation('stale_location'),

  /// Coordinates fall outside the assigned work location's geofence
  /// radius. Always blocked (this is the core geofence rule, not an
  /// anti-spoofing heuristic, but shares the same result field).
  outsideGeofence('outside_geofence');

  const IntegrityResult(this.wireValue);

  final String wireValue;

  static IntegrityResult fromWire(String value) {
    return IntegrityResult.values.firstWhere(
      (e) => e.wireValue == value,
      orElse: () => throw ArgumentError('Unknown IntegrityResult: $value'),
    );
  }

  /// Whether this result, on its own, must block the attendance action.
  /// Kept here (not hard-coded inline at every call site) so the policy is
  /// a single, documented, easy-to-audit decision.
  bool get isHardBlock {
    switch (this) {
      case IntegrityResult.mockLocationDetected:
      case IntegrityResult.impossibleMovement:
      case IntegrityResult.outsideGeofence:
        return true;
      case IntegrityResult.lowAccuracy:
      case IntegrityResult.staleLocation:
      case IntegrityResult.ok:
        return false;
    }
  }
}

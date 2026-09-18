import 'dart:math' as math;

/// Haversine great-circle distance, in meters. Used by `employee_app` to
/// decide whether to even attempt an attendance write, and to show live
/// "you are ~40m from the geofence" feedback. `firestore.rules` runs its
/// own, independent check as the real server-side gate — rules have no
/// trig functions, so it uses an equirectangular approximation instead of
/// this haversine formula (accurate at geofence scale). See
/// `WorkLocation.cosLatitude` and firestore.rules' `withinGeofence()`.
abstract final class GeoUtils {
  static const _earthRadiusMeters = 6371000.0;

  static double distanceMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusMeters * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);
}

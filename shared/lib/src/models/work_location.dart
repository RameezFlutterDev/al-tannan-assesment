import 'dart:math' as math;

import 'package:equatable/equatable.dart';

class WorkLocation extends Equatable {
  const WorkLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.isActive,
    required this.cosLatitude,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool isActive;

  /// `cos(latitude in radians)`, precomputed and stored at write time.
  ///
  /// This architecture has no application server — Firestore Security
  /// Rules are the only server-side gate, and the rules language has no
  /// trigonometric functions. Storing this one precomputed value lets the
  /// rules evaluate an equirectangular-approximation distance check
  /// (accurate at geofence scale — tens to hundreds of meters) using only
  /// arithmetic: `dx = Δlng * cosLatitude * 111320`,
  /// `dy = Δlat * 110540`, compare `dx² + dy²` against `radiusMeters²`
  /// (comparing squared distances avoids needing `sqrt` too). See
  /// firestore.rules' `withinGeofence()` helper for the authoritative
  /// implementation this mirrors.
  final double cosLatitude;

  static double computeCosLatitude(double latitudeDegrees) =>
      math.cos(latitudeDegrees * math.pi / 180.0);

  factory WorkLocation.fromJson(String id, Map<String, dynamic> json) {
    return WorkLocation(
      id: id,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num).toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      cosLatitude: (json['cosLatitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'isActive': isActive,
        'cosLatitude': cosLatitude,
      };

  WorkLocation copyWith({
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    bool? isActive,
  }) {
    final newLatitude = latitude ?? this.latitude;
    return WorkLocation(
      id: id,
      name: name ?? this.name,
      latitude: newLatitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      isActive: isActive ?? this.isActive,
      // Recompute whenever latitude changes so the two never drift apart.
      cosLatitude: latitude == null ? cosLatitude : computeCosLatitude(newLatitude),
    );
  }

  @override
  List<Object?> get props =>
      [id, name, latitude, longitude, radiusMeters, isActive, cosLatitude];
}

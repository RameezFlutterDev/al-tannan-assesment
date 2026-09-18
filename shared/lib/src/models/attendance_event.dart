import 'package:equatable/equatable.dart';

import '../enums/attendance_action_type.dart';
import '../enums/integrity_result.dart';

/// The full audit record of a single attendance action attempt, accepted or
/// rejected. Every submitted action — successful or not — creates exactly
/// one of these. This collection is both the audit trail and, filtered to
/// `accepted == false`, the "rejected attempts log" the assessment requires.
///
/// Written by the owning employee's own client (there is no application
/// server). firestore.rules enforces: create-only, never update/delete;
/// `employeeId` must equal the caller's uid; and any `accepted == true`
/// write must independently satisfy the geofence/sequence/mock-location
/// checks. `accepted == false` writes are accepted more permissively
/// (self-reported by the device) — see README.md's "Known Limitations".
class AttendanceEvent extends Equatable {
  const AttendanceEvent({
    required this.id,
    required this.employeeId,
    required this.actionType,
    required this.clientTimestamp,
    required this.serverTimestamp,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.isMockedClientFlag,
    required this.integrityResult,
    required this.distanceMeters,
    required this.withinGeofence,
    required this.assignedShiftId,
    required this.assignedLocationId,
    required this.accepted,
    this.rejectionReason,
  });

  final String id;
  final String employeeId;
  final AttendanceActionType actionType;

  /// Timestamp reported by the device. Never trusted for business logic —
  /// used only to compute clock-skew for [IntegrityResult.staleLocation].
  final DateTime clientTimestamp;

  /// Timestamp assigned by the Cloud Function at receipt. This is the
  /// authoritative time used for every calculation.
  final DateTime serverTimestamp;

  final double latitude;
  final double longitude;
  final double accuracyMeters;

  /// The `Position.isMocked` flag as reported by the device (Android only;
  /// always `false` on platforms that don't expose it). One signal among
  /// several — never trusted alone.
  final bool isMockedClientFlag;

  final IntegrityResult integrityResult;
  final double distanceMeters;
  final bool withinGeofence;
  final String assignedShiftId;
  final String assignedLocationId;
  final bool accepted;
  final String? rejectionReason;

  factory AttendanceEvent.fromJson(String id, Map<String, dynamic> json) {
    return AttendanceEvent(
      id: id,
      employeeId: json['employeeId'] as String,
      actionType: AttendanceActionType.fromWire(json['actionType'] as String),
      clientTimestamp: json['clientTimestamp'] as DateTime,
      serverTimestamp: json['serverTimestamp'] as DateTime,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracyMeters: (json['accuracyMeters'] as num).toDouble(),
      isMockedClientFlag: json['isMockedClientFlag'] as bool? ?? false,
      integrityResult: IntegrityResult.fromWire(json['integrityResult'] as String),
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      withinGeofence: json['withinGeofence'] as bool,
      assignedShiftId: json['assignedShiftId'] as String,
      assignedLocationId: json['assignedLocationId'] as String,
      accepted: json['accepted'] as bool,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'actionType': actionType.wireValue,
        'clientTimestamp': clientTimestamp,
        'serverTimestamp': serverTimestamp,
        'latitude': latitude,
        'longitude': longitude,
        'accuracyMeters': accuracyMeters,
        'isMockedClientFlag': isMockedClientFlag,
        'integrityResult': integrityResult.wireValue,
        'distanceMeters': distanceMeters,
        'withinGeofence': withinGeofence,
        'assignedShiftId': assignedShiftId,
        'assignedLocationId': assignedLocationId,
        'accepted': accepted,
        'rejectionReason': rejectionReason,
      };

  @override
  List<Object?> get props => [
        id,
        employeeId,
        actionType,
        clientTimestamp,
        serverTimestamp,
        latitude,
        longitude,
        accuracyMeters,
        isMockedClientFlag,
        integrityResult,
        distanceMeters,
        withinGeofence,
        assignedShiftId,
        assignedLocationId,
        accepted,
        rejectionReason,
      ];
}

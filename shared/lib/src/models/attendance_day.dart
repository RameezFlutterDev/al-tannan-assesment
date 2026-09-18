import 'package:equatable/equatable.dart';

import '../enums/attendance_day_state.dart';
import '../enums/attendance_status.dart';
import 'attendance_action_record.dart';

/// The aggregated daily attendance record — one document per
/// employee-per-date (`id` = `'{employeeId}_{yyyy-MM-dd}'`). This is the
/// source the employee home screen and every admin report read from.
/// Written by the owning employee's own client alongside each accepted
/// `AttendanceEvent`; firestore.rules independently re-validates the
/// state transition, ownership, and geofence on every write.
class AttendanceDay extends Equatable {
  const AttendanceDay({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.assignedShiftId,
    required this.assignedLocationId,
    required this.state,
    required this.status,
    this.checkIn,
    this.breaks = const [],
    this.checkOut,
    this.lateMinutes = 0,
    this.breakDurationMinutes = 0,
    this.grossPresenceMinutes,
    this.netWorkMinutes,
    required this.lastActionLatitude,
    required this.lastActionLongitude,
    required this.lastActionIsMockedClientFlag,
  });

  final String id;
  final String employeeId;

  /// Date-only, in the device's local time (see [CompanyTime]).
  final DateTime date;
  final String assignedShiftId;
  final String assignedLocationId;

  final AttendanceDayState state;
  final AttendanceStatus status;

  final AttendanceActionRecord? checkIn;
  final List<BreakRecord> breaks;
  final AttendanceActionRecord? checkOut;

  /// Coordinates/mock-flag of the most recent accepted action on this day
  /// (whichever of check-in/break-out/break-in/check-out was last).
  /// Denormalized here — separate from [checkIn]/[breaks]/[checkOut] —
  /// purely so firestore.rules' `passesLocationIntegrity()` can validate
  /// every update with the same three field names regardless of which
  /// action it is, instead of needing to know which nested field changed.
  final double lastActionLatitude;
  final double lastActionLongitude;
  final bool lastActionIsMockedClientFlag;

  final int lateMinutes;

  /// Sum of every completed break cycle's duration. An in-progress
  /// (open) break is not counted until it closes.
  final int breakDurationMinutes;

  /// `checkOut.time - checkIn.time`, in minutes. `null` until checked out.
  final int? grossPresenceMinutes;

  /// `grossPresenceMinutes - breakDurationMinutes`. `null` until checked out.
  final int? netWorkMinutes;

  bool get isLate => lateMinutes > 0;

  factory AttendanceDay.fromJson(String id, Map<String, dynamic> json) {
    return AttendanceDay(
      id: id,
      employeeId: json['employeeId'] as String,
      date: json['date'] as DateTime,
      assignedShiftId: json['assignedShiftId'] as String,
      assignedLocationId: json['assignedLocationId'] as String,
      state: AttendanceDayState.fromWire(json['state'] as String),
      status: AttendanceStatus.fromWire(json['status'] as String),
      checkIn: json['checkIn'] == null
          ? null
          : AttendanceActionRecord.fromJson(
              json['checkIn'] as Map<String, dynamic>),
      breaks: (json['breaks'] as List<dynamic>? ?? [])
          .map((b) => BreakRecord.fromJson(b as Map<String, dynamic>))
          .toList(),
      checkOut: json['checkOut'] == null
          ? null
          : AttendanceActionRecord.fromJson(
              json['checkOut'] as Map<String, dynamic>),
      lateMinutes: json['lateMinutes'] as int? ?? 0,
      breakDurationMinutes: json['breakDurationMinutes'] as int? ?? 0,
      grossPresenceMinutes: json['grossPresenceMinutes'] as int?,
      netWorkMinutes: json['netWorkMinutes'] as int?,
      lastActionLatitude: (json['lastActionLatitude'] as num).toDouble(),
      lastActionLongitude: (json['lastActionLongitude'] as num).toDouble(),
      lastActionIsMockedClientFlag:
          json['lastActionIsMockedClientFlag'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'date': date,
        'assignedShiftId': assignedShiftId,
        'assignedLocationId': assignedLocationId,
        'state': state.wireValue,
        'status': status.wireValue,
        'checkIn': checkIn?.toJson(),
        'breaks': breaks.map((b) => b.toJson()).toList(),
        'checkOut': checkOut?.toJson(),
        'lateMinutes': lateMinutes,
        'breakDurationMinutes': breakDurationMinutes,
        'grossPresenceMinutes': grossPresenceMinutes,
        'netWorkMinutes': netWorkMinutes,
        'lastActionLatitude': lastActionLatitude,
        'lastActionLongitude': lastActionLongitude,
        'lastActionIsMockedClientFlag': lastActionIsMockedClientFlag,
      };

  static String buildId(String employeeId, DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${employeeId}_$y-$m-$d';
  }

  @override
  List<Object?> get props => [
        id,
        employeeId,
        date,
        assignedShiftId,
        assignedLocationId,
        state,
        status,
        checkIn,
        breaks,
        checkOut,
        lateMinutes,
        breakDurationMinutes,
        grossPresenceMinutes,
        netWorkMinutes,
        lastActionLatitude,
        lastActionLongitude,
        lastActionIsMockedClientFlag,
      ];
}

import '../enums/attendance_day_state.dart';
import '../enums/attendance_status.dart';
import '../models/attendance_action_record.dart';

/// The authoritative attendance calculation logic. There is no application
/// server in this architecture — `employee_app` computes these values
/// on-device and writes them to Firestore; `firestore.rules` is the actual
/// server-side gate that authorizes *whether* an action may happen at all
/// (ownership/sequence/geofence/mock-location), but doesn't re-derive these
/// exact numbers. See README.md's "Known Limitations" section.
abstract final class AttendanceCalculations {
  /// Minutes late relative to [shiftStartMinutes] (since midnight) plus
  /// [graceMinutes], given the check-in's minutes-since-midnight
  /// ([checkInMinutes]). Returns 0 if on time or early.
  static int lateMinutes({
    required int shiftStartMinutes,
    required int graceMinutes,
    required int checkInMinutes,
  }) {
    final threshold = shiftStartMinutes + graceMinutes;
    final diff = checkInMinutes - threshold;
    return diff > 0 ? diff : 0;
  }

  static int totalBreakDurationMinutes(List<BreakRecord> breaks) {
    var total = 0;
    for (final b in breaks) {
      total += b.durationMinutes ?? 0;
    }
    return total;
  }

  static int? grossPresenceMinutes({
    required AttendanceActionRecord? checkIn,
    required AttendanceActionRecord? checkOut,
  }) {
    if (checkIn == null || checkOut == null) return null;
    return checkOut.time.difference(checkIn.time).inMinutes;
  }

  static int? netWorkMinutes({
    required int? grossPresenceMinutes,
    required int breakDurationMinutes,
  }) {
    if (grossPresenceMinutes == null) return null;
    final net = grossPresenceMinutes - breakDurationMinutes;
    return net < 0 ? 0 : net;
  }

  static AttendanceStatus deriveStatus({
    required AttendanceDayState state,
    required int lateMinutes,
  }) {
    if (state == AttendanceDayState.completed) {
      return lateMinutes > 0 ? AttendanceStatus.late : AttendanceStatus.onTime;
    }
    if (state == AttendanceDayState.notStarted) {
      return AttendanceStatus.notStarted;
    }
    // checkedIn or onBreak with no checkout yet by the time this is queried
    // (e.g. an admin viewing an in-progress day) is reported as incomplete.
    return AttendanceStatus.incomplete;
  }
}

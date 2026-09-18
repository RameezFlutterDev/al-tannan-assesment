import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/shared.dart';

import '../../app/core/firestore_converters.dart';

class AttendanceReportRepository {
  final _days = FirebaseFirestore.instance.collection(FirestoreCollections.attendanceDays);
  final _events =
      FirebaseFirestore.instance.collection(FirestoreCollections.attendanceEvents);

  /// All attendanceDays docs for one exact date — used by the dashboard's
  /// today-summary tiles.
  Stream<List<AttendanceDay>> forDate(DateTime date) {
    return _days.where('date', isEqualTo: Timestamp.fromDate(date)).snapshots().map(
          (snap) => snap.docs
              .map((d) => AttendanceDay.fromJson(d.id, withDateTimes(d.data())))
              .toList(),
        );
  }

  /// Date-range report, optionally narrowed by exactly one of
  /// employee/location/shift/status — matches the composite indexes
  /// deployed in firestore.indexes.json (each is `{dimension} + date`).
  Stream<List<AttendanceDay>> report({
    required DateTime from,
    required DateTime to,
    String? employeeId,
    String? locationId,
    String? shiftId,
    AttendanceStatus? status,
  }) {
    Query<Map<String, dynamic>> query = _days;
    if (employeeId != null) {
      query = query.where('employeeId', isEqualTo: employeeId);
    } else if (locationId != null) {
      query = query.where('assignedLocationId', isEqualTo: locationId);
    } else if (shiftId != null) {
      query = query.where('assignedShiftId', isEqualTo: shiftId);
    } else if (status != null) {
      query = query.where('status', isEqualTo: status.wireValue);
    }
    query = query
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('date', descending: true);

    return query.snapshots().map(
          (snap) => snap.docs
              .map((d) => AttendanceDay.fromJson(d.id, withDateTimes(d.data())))
              .toList(),
        );
  }

  /// Every attendance event (accepted or rejected) for one employee on one
  /// day — the detailed, coordinate-level view behind a report row.
  Stream<List<AttendanceEvent>> eventsForEmployeeOnDate(String employeeId, DateTime date) {
    final start = Timestamp.fromDate(date);
    final end = Timestamp.fromDate(date.add(const Duration(days: 1)));
    return _events
        .where('employeeId', isEqualTo: employeeId)
        .where('serverTimestamp', isGreaterThanOrEqualTo: start)
        .where('serverTimestamp', isLessThan: end)
        .orderBy('serverTimestamp')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AttendanceEvent.fromJson(d.id, withDateTimes(d.data())))
            .toList());
  }

  /// The rejected-attempts audit log across every employee/date, most
  /// recent first.
  Stream<List<AttendanceEvent>> rejectedAttempts({int limit = 100}) {
    return _events
        .where('accepted', isEqualTo: false)
        .orderBy('serverTimestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AttendanceEvent.fromJson(d.id, withDateTimes(d.data())))
            .toList());
  }
}

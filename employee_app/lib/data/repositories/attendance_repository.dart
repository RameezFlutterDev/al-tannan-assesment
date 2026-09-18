import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/shared.dart';

import '../../app/core/firestore_converters.dart';

class AttendanceRepository {
  final _days = FirebaseFirestore.instance.collection(FirestoreCollections.attendanceDays);
  final _events =
      FirebaseFirestore.instance.collection(FirestoreCollections.attendanceEvents);


  Stream<AttendanceDay?> todayStream(String employeeId) {
    final id = AttendanceDay.buildId(employeeId, CompanyTime.today());
    return _days.doc(id).snapshots().map(
          (doc) => doc.exists
              ? AttendanceDay.fromJson(doc.id, withDateTimes(doc.data()!))
              : null,
        );
  }

  /// Past attendance days for the employee, most recent first — used by
  /// the history feature.
  Stream<List<AttendanceDay>> historyStream(String employeeId, {int limit = 30}) {
    return _days
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AttendanceDay.fromJson(d.id, withDateTimes(d.data())))
            .toList());
  }

  DocumentReference<Map<String, dynamic>> newEventRef() => _events.doc();

  DocumentReference<Map<String, dynamic>> dayRef(String employeeId, DateTime date) =>
      _days.doc(AttendanceDay.buildId(employeeId, date));
}

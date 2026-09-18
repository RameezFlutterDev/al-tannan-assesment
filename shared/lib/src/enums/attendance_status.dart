/// The daily attendance status shown in reports and dashboards.
///
/// [absent] is intentionally never stored on an `AttendanceDay` document by
/// the backend (there is nothing to store if the employee never checked in).
/// It is computed at report-generation time by diffing employees with an
/// active assignment for a date against the `attendanceDays` that exist for
/// that date. See admin_panel's attendance_reports feature.
enum AttendanceStatus {
  notStarted('not_started'),
  onTime('on_time'),
  late('late'),
  incomplete('incomplete'),
  absent('absent');

  const AttendanceStatus(this.wireValue);

  final String wireValue;

  static AttendanceStatus fromWire(String value) {
    return AttendanceStatus.values.firstWhere(
      (e) => e.wireValue == value,
      orElse: () => throw ArgumentError('Unknown AttendanceStatus: $value'),
    );
  }

  String get label {
    switch (this) {
      case AttendanceStatus.notStarted:
        return 'Not Started';
      case AttendanceStatus.onTime:
        return 'On Time';
      case AttendanceStatus.late:
        return 'Late Arrival';
      case AttendanceStatus.incomplete:
        return 'Incomplete';
      case AttendanceStatus.absent:
        return 'Absent';
    }
  }
}

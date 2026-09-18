/// The four attendance actions an employee can perform, in the only valid
/// sequence: [checkIn] -> [breakOut] -> [breakIn] -> [checkOut].
enum AttendanceActionType {
  checkIn('check_in'),
  breakOut('break_out'),
  breakIn('break_in'),
  checkOut('check_out');

  const AttendanceActionType(this.wireValue);

  /// The exact string stored in Firestore / sent to Cloud Functions.
  final String wireValue;

  static AttendanceActionType fromWire(String value) {
    return AttendanceActionType.values.firstWhere(
      (e) => e.wireValue == value,
      orElse: () => throw ArgumentError('Unknown AttendanceActionType: $value'),
    );
  }
}

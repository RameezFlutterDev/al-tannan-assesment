/// Firestore top-level collection names. Defined once here so both apps
/// (and firestore.rules, kept in sync by hand since rules can't import
/// Dart) never disagree on a collection name.
abstract final class FirestoreCollections {
  static const employees = 'employees';
  static const shifts = 'shifts';
  static const locations = 'locations';
  static const assignments = 'assignments';
  static const attendanceEvents = 'attendanceEvents';
  static const attendanceDays = 'attendanceDays';
}

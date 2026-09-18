import 'attendance_action_type.dart';

/// The live state of an employee's attendance day, independent of
/// [AttendanceStatus] (which is about lateness/completeness for reporting).
/// This is what decides which action button is enabled next in the
/// employee app, and powers the admin dashboard's "currently on break" tile.
enum AttendanceDayState {
  notStarted('not_started'),
  checkedIn('checked_in'),
  onBreak('on_break'),
  completed('completed');

  const AttendanceDayState(this.wireValue);

  final String wireValue;

  static AttendanceDayState fromWire(String value) {
    return AttendanceDayState.values.firstWhere(
      (e) => e.wireValue == value,
      orElse: () => throw ArgumentError('Unknown AttendanceDayState: $value'),
    );
  }

  /// The single action valid from this state, or `null` if the day is
  /// [completed] and no further actions are allowed. [checkedIn] allows
  /// either [AttendanceActionType.breakOut] or [AttendanceActionType.checkOut]
  /// (breaks are optional and repeatable), so it returns the primary
  /// "next expected" action for UI purposes; use [isActionValid] for the
  /// actual authorization check.
  AttendanceActionType? get suggestedNextAction {
    switch (this) {
      case AttendanceDayState.notStarted:
        return AttendanceActionType.checkIn;
      case AttendanceDayState.checkedIn:
        return AttendanceActionType.checkOut;
      case AttendanceDayState.onBreak:
        return AttendanceActionType.breakIn;
      case AttendanceDayState.completed:
        return null;
    }
  }

  /// Full authorization check: is [action] valid from this state? Used by
  /// the app to decide button state; the real gate is the identical
  /// transition check in firestore.rules (see its `isValidTransition()`).
  bool isActionValid(AttendanceActionType action) {
    switch (this) {
      case AttendanceDayState.notStarted:
        return action == AttendanceActionType.checkIn;
      case AttendanceDayState.checkedIn:
        return action == AttendanceActionType.breakOut ||
            action == AttendanceActionType.checkOut;
      case AttendanceDayState.onBreak:
        return action == AttendanceActionType.breakIn;
      case AttendanceDayState.completed:
        return false;
    }
  }

  /// The state the day transitions to after [action] is accepted.
  AttendanceDayState nextState(AttendanceActionType action) {
    switch (action) {
      case AttendanceActionType.checkIn:
        return AttendanceDayState.checkedIn;
      case AttendanceActionType.breakOut:
        return AttendanceDayState.onBreak;
      case AttendanceActionType.breakIn:
        return AttendanceDayState.checkedIn;
      case AttendanceActionType.checkOut:
        return AttendanceDayState.completed;
    }
  }
}

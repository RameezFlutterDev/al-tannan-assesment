import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('AttendanceDayState.isActionValid — required sequencing', () {
    test('checkIn is only valid from notStarted', () {
      expect(
        AttendanceDayState.notStarted.isActionValid(AttendanceActionType.checkIn),
        isTrue,
      );
      for (final s in [
        AttendanceDayState.checkedIn,
        AttendanceDayState.onBreak,
        AttendanceDayState.completed,
      ]) {
        expect(s.isActionValid(AttendanceActionType.checkIn), isFalse,
            reason: 'duplicate check-in from $s must be rejected');
      }
    });

    test('breakOut before checkIn is rejected (scenario #6)', () {
      expect(
        AttendanceDayState.notStarted.isActionValid(AttendanceActionType.breakOut),
        isFalse,
      );
    });

    test('breakIn without an active breakOut is rejected (scenario #7)', () {
      expect(
        AttendanceDayState.checkedIn.isActionValid(AttendanceActionType.breakIn),
        isFalse,
      );
      expect(
        AttendanceDayState.notStarted.isActionValid(AttendanceActionType.breakIn),
        isFalse,
      );
    });

    test('checkOut is valid directly from checkedIn (breaks are optional)', () {
      expect(
        AttendanceDayState.checkedIn.isActionValid(AttendanceActionType.checkOut),
        isTrue,
      );
    });

    test('checkOut is not valid while still on break', () {
      expect(
        AttendanceDayState.onBreak.isActionValid(AttendanceActionType.checkOut),
        isFalse,
      );
    });

    test('duplicate checkOut from completed is rejected (scenario #8)', () {
      expect(
        AttendanceDayState.completed.isActionValid(AttendanceActionType.checkOut),
        isFalse,
      );
    });

    test('a full cycle with a second break is valid (scenario #11: 1+ breaks)', () {
      var state = AttendanceDayState.notStarted;
      for (final action in [
        AttendanceActionType.checkIn,
        AttendanceActionType.breakOut,
        AttendanceActionType.breakIn,
        AttendanceActionType.breakOut,
        AttendanceActionType.breakIn,
        AttendanceActionType.checkOut,
      ]) {
        expect(state.isActionValid(action), isTrue,
            reason: '$action should be valid from $state');
        state = state.nextState(action);
      }
      expect(state, AttendanceDayState.completed);
    });
  });
}

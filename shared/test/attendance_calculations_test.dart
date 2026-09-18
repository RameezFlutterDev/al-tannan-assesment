import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('AttendanceCalculations.lateMinutes', () {
    test('on-time check-in (before shift start) is 0', () {
      expect(
        AttendanceCalculations.lateMinutes(
          shiftStartMinutes: 420, // 07:00
          graceMinutes: 5,
          checkInMinutes: 415, // 06:55
        ),
        0,
      );
    });

    test('check-in exactly at shift start is 0', () {
      expect(
        AttendanceCalculations.lateMinutes(
          shiftStartMinutes: 420,
          graceMinutes: 5,
          checkInMinutes: 420,
        ),
        0,
      );
    });

    test('check-in within grace period is 0', () {
      expect(
        AttendanceCalculations.lateMinutes(
          shiftStartMinutes: 420,
          graceMinutes: 5,
          checkInMinutes: 425, // 07:05
        ),
        0,
      );
    });

    test('check-in past shift start + grace is late by the overage', () {
      // Shift 7:00, check-in 7:12 -> late by 7 minutes past the 5-min grace.
      expect(
        AttendanceCalculations.lateMinutes(
          shiftStartMinutes: 420,
          graceMinutes: 5,
          checkInMinutes: 432, // 07:12
        ),
        7,
      );
    });
  });

  group('AttendanceCalculations gross/net/break', () {
    test('matches the spec example: 7:00-16:00 with a 30-min break', () {
      final checkIn = AttendanceActionRecord(
        eventId: 'e1',
        time: DateTime.utc(2026, 1, 1, 7, 0),
        latitude: 0,
        longitude: 0,
      );
      final checkOut = AttendanceActionRecord(
        eventId: 'e4',
        time: DateTime.utc(2026, 1, 1, 16, 0),
        latitude: 0,
        longitude: 0,
      );
      final breakOut = AttendanceActionRecord(
        eventId: 'e2',
        time: DateTime.utc(2026, 1, 1, 12, 30),
        latitude: 0,
        longitude: 0,
      );
      final breakIn = AttendanceActionRecord(
        eventId: 'e3',
        time: DateTime.utc(2026, 1, 1, 13, 0),
        latitude: 0,
        longitude: 0,
      );

      final breaks = [BreakRecord(breakOut: breakOut, breakIn: breakIn)];
      final breakDuration = AttendanceCalculations.totalBreakDurationMinutes(breaks);
      expect(breakDuration, 30);

      final gross = AttendanceCalculations.grossPresenceMinutes(
        checkIn: checkIn,
        checkOut: checkOut,
      );
      expect(gross, 9 * 60);

      final net = AttendanceCalculations.netWorkMinutes(
        grossPresenceMinutes: gross,
        breakDurationMinutes: breakDuration,
      );
      // 9h gross - 30min break = 8h30min net (the spec's separate "Net Work
      // Hours" example uses a 1-hour break -> 8h net; this test reuses the
      // spec's 30-minute break example above for gross/break consistency).
      expect(net, 8 * 60 + 30);
    });

    test('an open (unfinished) break does not count toward duration', () {
      final breakOut = AttendanceActionRecord(
        eventId: 'e2',
        time: DateTime.utc(2026, 1, 1, 12, 30),
        latitude: 0,
        longitude: 0,
      );
      final breaks = [BreakRecord(breakOut: breakOut)];
      expect(AttendanceCalculations.totalBreakDurationMinutes(breaks), 0);
    });

    test('gross/net are null before check-out', () {
      final checkIn = AttendanceActionRecord(
        eventId: 'e1',
        time: DateTime.utc(2026, 1, 1, 7, 0),
        latitude: 0,
        longitude: 0,
      );
      final gross = AttendanceCalculations.grossPresenceMinutes(
        checkIn: checkIn,
        checkOut: null,
      );
      expect(gross, isNull);
      expect(
        AttendanceCalculations.netWorkMinutes(
          grossPresenceMinutes: gross,
          breakDurationMinutes: 0,
        ),
        isNull,
      );
    });
  });

  group('AttendanceCalculations.deriveStatus', () {
    test('notStarted before any check-in', () {
      expect(
        AttendanceCalculations.deriveStatus(
          state: AttendanceDayState.notStarted,
          lateMinutes: 0,
        ),
        AttendanceStatus.notStarted,
      );
    });

    test('incomplete while checked-in or on break with no checkout', () {
      expect(
        AttendanceCalculations.deriveStatus(
          state: AttendanceDayState.checkedIn,
          lateMinutes: 0,
        ),
        AttendanceStatus.incomplete,
      );
      expect(
        AttendanceCalculations.deriveStatus(
          state: AttendanceDayState.onBreak,
          lateMinutes: 0,
        ),
        AttendanceStatus.incomplete,
      );
    });

    test('onTime vs late once completed', () {
      expect(
        AttendanceCalculations.deriveStatus(
          state: AttendanceDayState.completed,
          lateMinutes: 0,
        ),
        AttendanceStatus.onTime,
      );
      expect(
        AttendanceCalculations.deriveStatus(
          state: AttendanceDayState.completed,
          lateMinutes: 12,
        ),
        AttendanceStatus.late,
      );
    });
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../app/core/services/biometric_service.dart';
import '../../../app/core/services/connectivity_service.dart';
import '../../../app/core/services/location_service.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../home/controllers/home_controller.dart';

enum AttendanceSubmitStatus { idle, loading, success, error }

class AttendanceController extends GetxController {
  final _locationService = LocationService();
  final _connectivityService = ConnectivityService();
  final _biometricService = BiometricService();
  final _attendanceRepository = AttendanceRepository();

  AttendanceSubmitStatus status = AttendanceSubmitStatus.idle;
  String? message;

  Future<void> performAction(AttendanceActionType action) async {
    final home = Get.find<HomeController>();
    final employee = home.employee;
    final location = home.location;
    final shift = home.shift;

    if (location == null || shift == null) {
      _fail('You have not been assigned a shift/location yet. Contact HR.');
      return;
    }
    final shiftId = employee.currentShiftId!;
    final locationId = employee.currentLocationId!;

    if (!home.state.isActionValid(action)) {
      _fail(_alreadyRecordedMessage(home.state, action));
      return;
    }

    status = AttendanceSubmitStatus.loading;
    message = null;
    update();

    // Biometric confirmation only gates Check In/Check Out (not the
    // breaks) — an anti-proxy-checkin layer on top of, not instead of,
    // the server-side geofence/sequence checks below. See
    // BiometricService's doc comment for why it's client-side-only.
    if (action == AttendanceActionType.checkIn || action == AttendanceActionType.checkOut) {
      final isCheckIn = action == AttendanceActionType.checkIn;
      final confirmed = await _biometricService.confirmIdentity(
        isCheckIn ? 'Confirm your identity to check in' : 'Confirm your identity to check out',
      );
      if (!confirmed) {
        _fail('Biometric confirmation is required to ${isCheckIn ? 'check in' : 'check out'}.');
        return;
      }
    }

    if (!await _connectivityService.isOnline()) {
      _fail('This action requires an internet connection. Please try again once connected.');
      return;
    }

    final locationResult = await _locationService.getCurrentPosition();
    if (!locationResult.isSuccess) {
      _fail(_locationFailureMessage(locationResult.failureReason!));
      return;
    }
    final position = locationResult.position!;
    final now = DateTime.now();

    final distanceMeters = GeoUtils.distanceMeters(
      lat1: position.latitude,
      lon1: position.longitude,
      lat2: location.latitude,
      lon2: location.longitude,
    );
    final withinGeofence = distanceMeters <= location.radiusMeters;
    final integrityResult = _computeIntegrity(
      isMocked: position.isMocked,
      accuracyMeters: position.accuracy,
      withinGeofence: withinGeofence,
      lastAction: _lastActionRecord(home.today),
      now: now,
      positionTimestamp: position.timestamp,
      newLat: position.latitude,
      newLng: position.longitude,
    );
    final accepted = !integrityResult.isHardBlock;

    final eventRef = _attendanceRepository.newEventRef();
    final event = AttendanceEvent(
      id: eventRef.id,
      employeeId: employee.id,
      actionType: action,
      clientTimestamp: now,
      serverTimestamp: now, // overwritten by FieldValue.serverTimestamp() below
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      isMockedClientFlag: position.isMocked,
      integrityResult: integrityResult,
      distanceMeters: distanceMeters,
      withinGeofence: withinGeofence,
      assignedShiftId: shiftId,
      assignedLocationId: locationId,
      accepted: accepted,
      rejectionReason: accepted ? null : _rejectionReason(integrityResult),
    );

    try {
      final batch = FirebaseFirestore.instance.batch();
      final eventJson = event.toJson()
        ..['serverTimestamp'] = FieldValue.serverTimestamp();
      batch.set(eventRef, eventJson);

      if (accepted) {
        final dayRef = _attendanceRepository.dayRef(employee.id, CompanyTime.today());
        final record = AttendanceActionRecord(
          eventId: eventRef.id,
          time: now,
          latitude: position.latitude,
          longitude: position.longitude,
        );
        final dayData = _buildDayUpdate(
          existing: home.today,
          employee: employee,
          shiftId: shiftId,
          locationId: locationId,
          shift: shift,
          action: action,
          record: record,
          isMocked: position.isMocked,
        );
        if (home.today == null) {
          batch.set(dayRef, dayData);
        } else {
          batch.update(dayRef, dayData);
        }
      }

      await batch.commit();

      if (!accepted) {
        _fail(_rejectionReason(integrityResult));
        return;
      }

      status = AttendanceSubmitStatus.success;
      message = _successMessage(action);
      update();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _fail('This action was rejected. Please refresh and try again.');
      } else {
        _fail('Something went wrong. Please try again.');
      }
    } catch (_) {
      _fail('Something went wrong. Please try again.');
    }
  }

  void _fail(String reason) {
    status = AttendanceSubmitStatus.error;
    message = reason;
    update();
  }

  AttendanceActionRecord? _lastActionRecord(AttendanceDay? day) {
    if (day == null) return null;
    if (day.checkOut != null) return day.checkOut;
    if (day.breaks.isNotEmpty) {
      final last = day.breaks.last;
      return last.breakIn ?? last.breakOut;
    }
    return day.checkIn;
  }

  IntegrityResult _computeIntegrity({
    required bool isMocked,
    required double accuracyMeters,
    required bool withinGeofence,
    required AttendanceActionRecord? lastAction,
    required DateTime now,
    required DateTime positionTimestamp,
    required double newLat,
    required double newLng,
  }) {
    if (isMocked) return IntegrityResult.mockLocationDetected;
    if (!withinGeofence) return IntegrityResult.outsideGeofence;

    if (lastAction != null) {
      final hours = now.difference(lastAction.time).inSeconds / 3600.0;
      if (hours > 0) {
        final km = GeoUtils.distanceMeters(
              lat1: lastAction.latitude,
              lon1: lastAction.longitude,
              lat2: newLat,
              lon2: newLng,
            ) /
            1000.0;
        if (km / hours > AppConstants.maxPlausibleSpeedKmh) {
          return IntegrityResult.impossibleMovement;
        }
      }
    }

    // The GPS fix's own timestamp vs. right now — catches a cached/old
    // reading (weak signal) or a replayed fixed reading (spoofing attempt)
    // being submitted as if it were fresh. `.abs()` because device clocks
    // can drift slightly ahead of the location provider's clock too.
    final positionAgeSeconds = now.difference(positionTimestamp).inSeconds.abs();
    if (positionAgeSeconds > AppConstants.staleLocationThresholdSeconds) {
      return IntegrityResult.staleLocation;
    }

    if (accuracyMeters > AppConstants.lowAccuracyThresholdMeters) {
      return IntegrityResult.lowAccuracy;
    }
    return IntegrityResult.ok;
  }

  Map<String, dynamic> _buildDayUpdate({
    required AttendanceDay? existing,
    required Employee employee,
    required String shiftId,
    required String locationId,
    required Shift shift,
    required AttendanceActionType action,
    required AttendanceActionRecord record,
    required bool isMocked,
  }) {
    final currentState = existing?.state ?? AttendanceDayState.notStarted;
    final newState = currentState.nextState(action);

    AttendanceActionRecord? checkIn = existing?.checkIn;
    List<BreakRecord> breaks = List.of(existing?.breaks ?? const []);
    AttendanceActionRecord? checkOut = existing?.checkOut;

    switch (action) {
      case AttendanceActionType.checkIn:
        checkIn = record;
      case AttendanceActionType.breakOut:
        breaks = [...breaks, BreakRecord(breakOut: record)];
      case AttendanceActionType.breakIn:
        final last = breaks.removeLast();
        breaks = [...breaks, last.copyWith(breakIn: record)];
      case AttendanceActionType.checkOut:
        checkOut = record;
    }

    final lateMinutes = checkIn == null
        ? 0
        : AttendanceCalculations.lateMinutes(
            shiftStartMinutes: shift.startMinutes,
            graceMinutes: shift.graceMinutes,
            checkInMinutes: _minutesSinceMidnight(checkIn.time),
          );
    final breakDuration = AttendanceCalculations.totalBreakDurationMinutes(breaks);
    final gross =
        AttendanceCalculations.grossPresenceMinutes(checkIn: checkIn, checkOut: checkOut);
    final net = AttendanceCalculations.netWorkMinutes(
      grossPresenceMinutes: gross,
      breakDurationMinutes: breakDuration,
    );
    final status =
        AttendanceCalculations.deriveStatus(state: newState, lateMinutes: lateMinutes);

    final day = AttendanceDay(
      id: '', // unused by toJson
      employeeId: employee.id,
      date: CompanyTime.today(),
      assignedShiftId: shiftId,
      assignedLocationId: locationId,
      state: newState,
      status: status,
      checkIn: checkIn,
      breaks: breaks,
      checkOut: checkOut,
      lateMinutes: lateMinutes,
      breakDurationMinutes: breakDuration,
      grossPresenceMinutes: gross,
      netWorkMinutes: net,
      lastActionLatitude: record.latitude,
      lastActionLongitude: record.longitude,
      lastActionIsMockedClientFlag: isMocked,
    );
    return day.toJson();
  }

  // `time` is always a local DateTime (captured via `DateTime.now()` at
  // the moment of the action) — compared directly against the shift's
  // raw stored minutes, matching how the admin panel's time picker
  // stores whatever hour/minute was typed with no timezone conversion.
  // See CompanyTime's doc comment for why this must NOT re-apply an
  // offset here.
  int _minutesSinceMidnight(DateTime time) => time.hour * 60 + time.minute;

  String _rejectionReason(IntegrityResult result) {
    switch (result) {
      case IntegrityResult.outsideGeofence:
        return 'You are outside your assigned office location.';
      case IntegrityResult.mockLocationDetected:
        return 'Mock/fake location detected. This attempt has been logged.';
      case IntegrityResult.impossibleMovement:
        return 'Location changed implausibly fast since your last action. This attempt has been logged.';
      case IntegrityResult.lowAccuracy:
      case IntegrityResult.staleLocation:
      case IntegrityResult.ok:
        return 'Action rejected.';
    }
  }

  String _locationFailureMessage(LocationFailureReason reason) {
    switch (reason) {
      case LocationFailureReason.serviceDisabled:
        return 'Location services are turned off. Please enable GPS.';
      case LocationFailureReason.permissionDenied:
        return 'Location permission is required to record attendance.';
      case LocationFailureReason.permissionDeniedForever:
        return 'Location permission was denied. Enable it from app settings.';
      case LocationFailureReason.timeout:
        return 'Could not get a GPS fix in time. Please try again.';
      case LocationFailureReason.unknown:
        return 'Could not determine your location. Please try again.';
    }
  }

  String _alreadyRecordedMessage(AttendanceDayState state, AttendanceActionType action) {
    if (state == AttendanceDayState.completed) {
      return 'You have already checked out today.';
    }
    return 'That action is not available right now.';
  }

  String _successMessage(AttendanceActionType action) {
    switch (action) {
      case AttendanceActionType.checkIn:
        return 'Checked in successfully.';
      case AttendanceActionType.breakOut:
        return 'Break started.';
      case AttendanceActionType.breakIn:
        return 'Break ended.';
      case AttendanceActionType.checkOut:
        return 'Checked out successfully.';
    }
  }
}

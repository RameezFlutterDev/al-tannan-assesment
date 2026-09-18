import 'dart:async';

import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../app/core/services/location_service.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/location_repository.dart';
import '../../../data/repositories/shift_repository.dart';
import '../../auth/controllers/auth_controller.dart';

class HomeController extends GetxController {
  final _attendanceRepository = AttendanceRepository();
  final _shiftRepository = ShiftRepository();
  final _locationRepository = LocationRepository();
  final _locationService = LocationService();

  Employee get employee => Get.find<AuthController>().currentEmployee!;

  bool isLoadingAssignment = true;
  Shift? shift;
  WorkLocation? location;

  AttendanceDay? today;
  StreamSubscription<AttendanceDay?>? _todaySub;

  @override
  void onInit() {
    super.onInit();
    _loadAssignment();
    _locationService.requestPermissionOnLaunch();
    _todaySub = _attendanceRepository.todayStream(employee.id).listen((day) {
      today = day;
      update();
    });
  }

  Future<void> _loadAssignment() async {
    final shiftId = employee.currentShiftId;
    final locationId = employee.currentLocationId;
    shift = shiftId == null ? null : await _shiftRepository.getById(shiftId);
    location = locationId == null ? null : await _locationRepository.getById(locationId);
    isLoadingAssignment = false;
    update();
  }

  AttendanceDayState get state => today?.state ?? AttendanceDayState.notStarted;

  @override
  void onClose() {
    _todaySub?.cancel();
    super.onClose();
  }
}

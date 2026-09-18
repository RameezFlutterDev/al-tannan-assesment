import 'dart:async';

import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/repositories/attendance_report_repository.dart';
import '../../../data/repositories/employee_repository.dart';

class DashboardController extends GetxController {
  final _attendanceRepository = AttendanceReportRepository();
  final _employeeRepository = EmployeeRepository();

  List<AttendanceDay> todayDays = [];
  int totalActiveEmployees = 0;
  bool isLoading = true;

  StreamSubscription? _daysSub;
  StreamSubscription? _employeesSub;

  @override
  void onInit() {
    super.onInit();
    _daysSub = _attendanceRepository.forDate(CompanyTime.today()).listen((value) {
      todayDays = value;
      isLoading = false;
      update();
    });
    _employeesSub = _employeeRepository.streamAll().listen((employees) {
      totalActiveEmployees =
          employees.where((e) => e.isActive && e.role == UserRole.employee).length;
      update();
    });
  }

  int get checkedInCount =>
      todayDays.where((d) => d.state == AttendanceDayState.checkedIn).length;
  int get onBreakCount => todayDays.where((d) => d.state == AttendanceDayState.onBreak).length;
  int get checkedOutCount =>
      todayDays.where((d) => d.state == AttendanceDayState.completed).length;
  int get lateCount => todayDays.where((d) => d.isLate).length;
  int get presentCount => todayDays.length;
  int get absentCount =>
      (totalActiveEmployees - presentCount) < 0 ? 0 : totalActiveEmployees - presentCount;

  @override
  void onClose() {
    _daysSub?.cancel();
    _employeesSub?.cancel();
    super.onClose();
  }
}

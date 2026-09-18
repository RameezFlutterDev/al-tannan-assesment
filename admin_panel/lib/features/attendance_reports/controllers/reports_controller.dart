import 'dart:async';

import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/repositories/attendance_report_repository.dart';
import '../../../data/repositories/employee_repository.dart';
import '../../../data/repositories/location_repository.dart';
import '../../../data/repositories/shift_repository.dart';

enum ReportFilterDimension { none, employee, location, shift, status }

class ReportsController extends GetxController {
  final _attendanceRepository = AttendanceReportRepository();
  final _employeeRepository = EmployeeRepository();
  final _shiftRepository = ShiftRepository();
  final _locationRepository = LocationRepository();

  List<Employee> employees = [];
  List<Shift> shifts = [];
  List<WorkLocation> locations = [];

  List<AttendanceDay> rows = [];
  bool isLoadingRows = true;
  String? rowsError;

  List<AttendanceEvent> rejectedAttempts = [];
  bool isLoadingRejected = true;
  String? rejectedError;

  DateTime from = CompanyTime.today().subtract(const Duration(days: 6));
  DateTime to = CompanyTime.today();
  ReportFilterDimension dimension = ReportFilterDimension.none;
  String? selectedEmployeeId;
  String? selectedLocationId;
  String? selectedShiftId;
  AttendanceStatus? selectedStatus;

  StreamSubscription? _rowsSub;
  StreamSubscription? _rejectedSub;
  StreamSubscription? _employeesSub;
  StreamSubscription? _shiftsSub;
  StreamSubscription? _locationsSub;

  @override
  void onInit() {
    super.onInit();
    _employeesSub = _employeeRepository.streamAll().listen((v) {
      employees = v;
      update();
    });
    _shiftsSub = _shiftRepository.streamAll().listen((v) {
      shifts = v;
      update();
    });
    _locationsSub = _locationRepository.streamAll().listen((v) {
      locations = v;
      update();
    });
    _rejectedSub = _attendanceRepository.rejectedAttempts().listen(
      (v) {
        rejectedAttempts = v;
        isLoadingRejected = false;
        rejectedError = null;
        update();
      },
      onError: (Object e) {
        isLoadingRejected = false;
        rejectedError = e.toString();
        update();
      },
    );
    _runReport();
  }

  Employee? employeeById(String id) => employees.where((e) => e.id == id).firstOrNull;

  void setDateRange(DateTime newFrom, DateTime newTo) {
    from = newFrom;
    to = newTo;
    _runReport();
  }

  void setDimension(ReportFilterDimension d) {
    dimension = d;
    selectedEmployeeId = null;
    selectedLocationId = null;
    selectedShiftId = null;
    selectedStatus = null;
    _runReport();
  }

  void setFilterValue(String? value) {
    switch (dimension) {
      case ReportFilterDimension.employee:
        selectedEmployeeId = value;
      case ReportFilterDimension.location:
        selectedLocationId = value;
      case ReportFilterDimension.shift:
        selectedShiftId = value;
      case ReportFilterDimension.status:
        selectedStatus =
            value == null ? null : AttendanceStatus.values.firstWhere((s) => s.wireValue == value);
      case ReportFilterDimension.none:
        break;
    }
    _runReport();
  }

  void _runReport() {
    isLoadingRows = true;
    rowsError = null;
    update();
    _rowsSub?.cancel();
    _rowsSub = _attendanceRepository
        .report(
      from: from,
      to: to,
      employeeId: selectedEmployeeId,
      locationId: selectedLocationId,
      shiftId: selectedShiftId,
      status: selectedStatus,
    )
        .listen(
      (value) {
        rows = value;
        isLoadingRows = false;
        rowsError = null;
        update();
      },
      onError: (Object e) {
        isLoadingRows = false;
        rowsError = e.toString();
        update();
      },
    );
  }

  Stream<List<AttendanceEvent>> eventsFor(AttendanceDay day) =>
      _attendanceRepository.eventsForEmployeeOnDate(day.employeeId, day.date);

  @override
  void onClose() {
    _rowsSub?.cancel();
    _rejectedSub?.cancel();
    _employeesSub?.cancel();
    _shiftsSub?.cancel();
    _locationsSub?.cancel();
    super.onClose();
  }
}

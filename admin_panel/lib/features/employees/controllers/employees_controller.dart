import 'dart:async';

import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/repositories/employee_repository.dart';
import '../../../data/repositories/location_repository.dart';
import '../../../data/repositories/shift_repository.dart';

class EmployeesController extends GetxController {
  final _employeeRepository = EmployeeRepository();
  final _shiftRepository = ShiftRepository();
  final _locationRepository = LocationRepository();

  List<Employee> employees = [];
  List<Shift> shifts = [];
  List<WorkLocation> locations = [];
  bool isLoading = true;

  StreamSubscription? _employeesSub;
  StreamSubscription? _shiftsSub;
  StreamSubscription? _locationsSub;

  @override
  void onInit() {
    super.onInit();
    _employeesSub = _employeeRepository.streamAll().listen((value) {
      employees = value;
      isLoading = false;
      update();
    });
    _shiftsSub = _shiftRepository.streamAll().listen((value) {
      shifts = value;
      update();
    });
    _locationsSub = _locationRepository.streamAll().listen((value) {
      locations = value;
      update();
    });
  }

  Shift? shiftById(String? id) =>
      id == null ? null : shifts.where((s) => s.id == id).firstOrNull;
  WorkLocation? locationById(String? id) =>
      id == null ? null : locations.where((l) => l.id == id).firstOrNull;

  Future<String?> createEmployee({
    required String name,
    required String email,
    required String password,
    required String employeeCode,
    required UserRole role,
    String? shiftId,
    String? locationId,
  }) async {
    try {
      await _employeeRepository.create(
        name: name,
        email: email,
        password: password,
        employeeCode: employeeCode,
        role: role,
        currentShiftId: shiftId,
        currentLocationId: locationId,
      );
      return null;
    } catch (e) {
      return _friendlyError(e);
    }
  }

  Future<String?> updateEmployee(Employee employee) async {
    try {
      await _employeeRepository.update(employee);
      return null;
    } catch (e) {
      return _friendlyError(e);
    }
  }

  Future<void> setActive(String employeeId, bool isActive) =>
      _employeeRepository.setActive(employeeId, isActive);

  String _friendlyError(Object e) {
    final message = e.toString();
    if (message.contains('email-already-in-use')) {
      return 'That email is already registered.';
    }
    if (message.contains('weak-password')) {
      return 'Password must be at least 6 characters.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  void onClose() {
    _employeesSub?.cancel();
    _shiftsSub?.cancel();
    _locationsSub?.cancel();
    super.onClose();
  }
}

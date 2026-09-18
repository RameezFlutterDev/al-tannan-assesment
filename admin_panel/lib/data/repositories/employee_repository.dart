import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/shared.dart';

import '../../app/core/firestore_converters.dart';
import '../../app/core/secondary_auth_service.dart';

class EmployeeRepository {
  final _employees =
      FirebaseFirestore.instance.collection(FirestoreCollections.employees);
  final _secondaryAuth = SecondaryAuthService();

  Stream<List<Employee>> streamAll() {
    return _employees.orderBy('name').snapshots().map(
          (snap) => snap.docs
              .map((d) => Employee.fromJson(d.id, withDateTimes(d.data())))
              .toList(),
        );
  }

  /// Creates the Firebase Auth account (via the isolated secondary app so
  /// the admin's own session is untouched) and the matching Firestore
  /// profile document, using the new account's uid as the document id.
  Future<void> create({
    required String name,
    required String email,
    required String password,
    required String employeeCode,
    required UserRole role,
    String? currentShiftId,
    String? currentLocationId,
  }) async {
    final uid = await _secondaryAuth.createEmployeeAccount(
      email: email,
      password: password,
    );
    final employee = Employee(
      id: uid,
      authUid: uid,
      name: name,
      email: email,
      employeeCode: employeeCode,
      isActive: true,
      role: role,
      currentShiftId: currentShiftId,
      currentLocationId: currentLocationId,
    );
    await _employees.doc(uid).set(employee.toJson());
  }

  Future<void> update(Employee employee) async {
    await _employees.doc(employee.id).set(employee.toJson());
  }

  Future<void> setActive(String employeeId, bool isActive) async {
    await _employees.doc(employeeId).update({'isActive': isActive});
  }
}

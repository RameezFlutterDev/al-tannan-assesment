import 'package:equatable/equatable.dart';

import '../enums/user_role.dart';

class Employee extends Equatable {
  const Employee({
    required this.id,
    required this.authUid,
    required this.name,
    required this.email,
    required this.employeeCode,
    required this.isActive,
    required this.role,
    this.currentShiftId,
    this.currentLocationId,
  });

  /// Firestore document id. By convention this equals [authUid] so
  /// resolving "my employee doc" from a Firebase Auth session is a direct
  /// lookup, never a query.
  final String id;
  final String authUid;
  final String name;
  final String email;
  final String employeeCode;
  final bool isActive;
  final UserRole role;

  /// The employee's *currently active* shift/location assignment,
  /// denormalized onto this document (rather than resolved by querying
  /// `assignments` by date range) specifically so Firestore Security Rules
  /// can validate an attendance action with a single `get()` on this doc —
  /// rules cannot run arbitrary range queries. Admin updates these two
  /// fields when reassigning an employee; the full history of past
  /// assignments (including date ranges) is still recorded in the
  /// `assignments` collection for reporting/audit and for the optional
  /// date-based scheduling bonus.
  ///
  /// `null` means "not yet assigned" — the default for a newly-created
  /// employee (and for admin accounts, which don't clock in). Attendance
  /// actions are blocked until both are set; see firestore.rules'
  /// `passesLocationIntegrity()`.
  final String? currentShiftId;
  final String? currentLocationId;

  factory Employee.fromJson(String id, Map<String, dynamic> json) {
    return Employee(
      id: id,
      authUid: json['authUid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      employeeCode: json['employeeCode'] as String,
      isActive: json['isActive'] as bool? ?? true,
      role: UserRole.fromWire(json['role'] as String? ?? 'employee'),
      currentShiftId: json['currentShiftId'] as String?,
      currentLocationId: json['currentLocationId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'authUid': authUid,
        'name': name,
        'email': email,
        'employeeCode': employeeCode,
        'isActive': isActive,
        'role': role.wireValue,
        'currentShiftId': currentShiftId,
        'currentLocationId': currentLocationId,
      };

  Employee copyWith({
    String? name,
    String? email,
    String? employeeCode,
    bool? isActive,
    UserRole? role,
    String? currentShiftId,
    String? currentLocationId,
  }) {
    return Employee(
      id: id,
      authUid: authUid,
      name: name ?? this.name,
      email: email ?? this.email,
      employeeCode: employeeCode ?? this.employeeCode,
      isActive: isActive ?? this.isActive,
      role: role ?? this.role,
      currentShiftId: currentShiftId ?? this.currentShiftId,
      currentLocationId: currentLocationId ?? this.currentLocationId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        authUid,
        name,
        email,
        employeeCode,
        isActive,
        role,
        currentShiftId,
        currentLocationId,
      ];
}

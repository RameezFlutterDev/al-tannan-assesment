/// Mirrors the Firebase Auth custom claim `role` set on every account.
enum UserRole {
  employee('employee'),
  admin('admin');

  const UserRole(this.wireValue);

  final String wireValue;

  static UserRole fromWire(String value) {
    return UserRole.values.firstWhere(
      (e) => e.wireValue == value,
      orElse: () => throw ArgumentError('Unknown UserRole: $value'),
    );
  }
}

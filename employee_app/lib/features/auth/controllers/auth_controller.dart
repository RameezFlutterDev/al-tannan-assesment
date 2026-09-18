import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

/// Handles employee login/session state. Uses GetX's `update()` +
/// `GetBuilder` pattern (not reactive `.obs`/`Obx`) per this project's
/// state-management convention.
class AuthController extends GetxController {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool isLoading = false;
  String? errorMessage;
  Employee? currentEmployee;

  bool get isLoggedIn => _auth.currentUser != null;

  /// Re-loads the employee profile for an already-signed-in Firebase user
  /// (e.g. on app restart with a persisted session). Returns false if the
  /// session is no longer valid (profile missing/deactivated), signing the
  /// user out in that case.
  Future<bool> restoreSession() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    return _loadEmployeeProfile(user.uid);
  }

  Future<bool> signIn(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    update();
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final ok = await _loadEmployeeProfile(credential.user!.uid);
      isLoading = false;
      update();
      return ok;
    } on FirebaseAuthException catch (e) {
      errorMessage = _mapAuthError(e.code);
      isLoading = false;
      update();
      return false;
    } catch (_) {
      errorMessage = 'Something went wrong. Please try again.';
      isLoading = false;
      update();
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    currentEmployee = null;
    update();
  }

  Future<bool> _loadEmployeeProfile(String uid) async {
    final doc =
        await _firestore.collection(FirestoreCollections.employees).doc(uid).get();
    if (!doc.exists) {
      await _auth.signOut();
      errorMessage = 'No employee profile found for this account.';
      return false;
    }
    final employee = Employee.fromJson(doc.id, doc.data()!);
    if (!employee.isActive) {
      await _auth.signOut();
      errorMessage = 'Your account has been deactivated. Contact HR.';
      return false;
    }
    currentEmployee = employee;
    return true;
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Sign-in failed. Please try again.';
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

/// Handles admin login/session state. Only accounts with
/// `employees/{uid}.role == 'admin'` may use this app — a valid employee
/// login is explicitly rejected here (separate apps for separate roles).
class AuthController extends GetxController {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool isLoading = false;
  String? errorMessage;
  Employee? currentAdmin;

  bool get isLoggedIn => _auth.currentUser != null;

  Future<bool> restoreSession() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    return _loadAdminProfile(user.uid);
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
      final ok = await _loadAdminProfile(credential.user!.uid);
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
    currentAdmin = null;
    update();
  }

  Future<bool> _loadAdminProfile(String uid) async {
    final doc =
        await _firestore.collection(FirestoreCollections.employees).doc(uid).get();
    if (!doc.exists) {
      await _auth.signOut();
      errorMessage = 'No admin profile found for this account.';
      return false;
    }
    final employee = Employee.fromJson(doc.id, doc.data()!);
    if (employee.role != UserRole.admin) {
      await _auth.signOut();
      errorMessage = 'This account does not have admin access.';
      return false;
    }
    if (!employee.isActive) {
      await _auth.signOut();
      errorMessage = 'Your account has been deactivated.';
      return false;
    }
    currentAdmin = employee;
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

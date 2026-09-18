import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

/// Creating a Firebase Auth user with the client SDK's
/// `createUserWithEmailAndPassword` automatically signs the *caller* into
/// that new account — fine for a normal signup flow, but wrong here: the
/// admin creating an employee account must stay signed in as themselves.
///
/// There's no application server in this architecture to do this "the
/// normal way" (an Admin SDK call from a backend). The standard
/// client-only workaround is a second, separate [FirebaseApp] instance
/// with its own independent [FirebaseAuth] session — the new user is
/// created and immediately signed out *there*, never touching the admin's
/// primary session.
class SecondaryAuthService {
  static const _appName = 'admin-panel-secondary';

  Future<FirebaseApp> _secondaryApp() async {
    final existing = Firebase.apps.where((a) => a.name == _appName);
    if (existing.isNotEmpty) return existing.first;
    return Firebase.initializeApp(
      name: _appName,
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  /// Creates a new employee's Firebase Auth account and returns their uid.
  /// Does not affect the currently signed-in admin session.
  Future<String> createEmployeeAccount({
    required String email,
    required String password,
  }) async {
    final app = await _secondaryApp();
    final auth = FirebaseAuth.instanceFor(app: app);
    final credential =
        await auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    final uid = credential.user!.uid;
    await auth.signOut();
    return uid;
  }
}

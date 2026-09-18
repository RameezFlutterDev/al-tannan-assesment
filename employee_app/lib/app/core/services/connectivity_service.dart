import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper around `connectivity_plus` — used to show an explicit
/// "action requires network" state instead of attempting (and failing) a
/// Firestore write while offline.
class ConnectivityService {
  Future<bool> isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }
}

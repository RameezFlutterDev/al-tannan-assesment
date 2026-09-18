import 'package:local_auth/local_auth.dart';

/// Wraps `local_auth`: asks the OS to confirm the device owner via
/// fingerprint/Face ID (falling back to device PIN/pattern), without this
/// app ever capturing, storing, or transmitting any biometric data itself
/// — the OS handles matching entirely in secure hardware and only reports
/// back a yes/no. Used as an anti-proxy-checkin gate on Check In/Check Out:
/// it proves the device's unlock credential was used at that moment, not
/// cryptographically who the employee is, so it's a client-side UX layer
/// on top of (not a replacement for) the server-side geofence/sequence
/// checks. See README.md's "Known Limitations".
class BiometricService {
  final _auth = LocalAuthentication();

  /// Returns `true` if either the device has no lock/biometric configured
  /// at all (nothing to gate on — can't force a security feature the
  /// device doesn't have) or the user successfully confirmed their
  /// identity. Returns `false` only when confirmation was available but
  /// failed or was cancelled.
  Future<bool> confirmIdentity(String reason) async {
    final supported = await _auth.isDeviceSupported();
    if (!supported) return true;

    try {
      return await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (e) {
      switch (e.code) {
        case LocalAuthExceptionCode.noCredentialsSet:
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noBiometricHardware:
          return true; // nothing enrolled — same as unsupported, don't block.
        default:
          return false;
      }
    }
  }
}

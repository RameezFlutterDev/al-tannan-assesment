/// Deliberately just the device's own local clock, not a fixed
/// `AppConstants.companyTimeZone` offset. An earlier version of this
/// applied a fixed Asia/Riyadh (UTC+3) shift here, but shift start/end
/// times entered in the admin panel's time picker are raw, unconverted
/// numbers — there is no matching conversion applied when an admin types
/// "7:00 AM". Shifting only one side of that comparison (the check-in
/// time) while leaving the other side (the shift's stored minutes) alone
/// meant a genuinely late check-in could read as on-time whenever the
/// testing device's timezone wasn't UTC+3. Using the device's own local
/// time on both sides keeps them on the same basis. Documented assumption
/// (see README's "Known Limitations"): admin and employees are assumed to
/// operate in the same practical timezone, which holds for a
/// single-location/single-country deployment like this one.
abstract final class CompanyTime {
  static DateTime now() => DateTime.now();

  /// Today's date, time-of-day zeroed out, in local time.
  static DateTime today() {
    final n = now();
    return DateTime(n.year, n.month, n.day);
  }
}

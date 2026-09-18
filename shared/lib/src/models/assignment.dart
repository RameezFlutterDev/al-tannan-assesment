import 'package:equatable/equatable.dart';

/// An employee's shift + location assignment for a date range. Multiple
/// assignments per employee are allowed (date-based scheduling); "today's
/// active assignment" is resolved server-side as the assignment where
/// `effectiveFrom <= today` and (`effectiveTo == null || today <= effectiveTo`),
/// preferring the most recently created match if more than one applies.
class Assignment extends Equatable {
  const Assignment({
    required this.id,
    required this.employeeId,
    required this.shiftId,
    required this.locationId,
    required this.effectiveFrom,
    this.effectiveTo,
  });

  final String id;
  final String employeeId;
  final String shiftId;
  final String locationId;

  /// Date-only (time component ignored), in the device's local time (see
  /// [CompanyTime]).
  final DateTime effectiveFrom;

  /// Date-only, inclusive. `null` means "open-ended / still active".
  final DateTime? effectiveTo;

  bool coversDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final from = DateTime(effectiveFrom.year, effectiveFrom.month, effectiveFrom.day);
    if (d.isBefore(from)) return false;
    if (effectiveTo == null) return true;
    final to = DateTime(effectiveTo!.year, effectiveTo!.month, effectiveTo!.day);
    return !d.isAfter(to);
  }

  factory Assignment.fromJson(String id, Map<String, dynamic> json) {
    return Assignment(
      id: id,
      employeeId: json['employeeId'] as String,
      shiftId: json['shiftId'] as String,
      locationId: json['locationId'] as String,
      effectiveFrom: json['effectiveFrom'] as DateTime,
      effectiveTo: json['effectiveTo'] as DateTime?,
    );
  }

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'shiftId': shiftId,
        'locationId': locationId,
        'effectiveFrom': effectiveFrom,
        'effectiveTo': effectiveTo,
      };

  @override
  List<Object?> get props =>
      [id, employeeId, shiftId, locationId, effectiveFrom, effectiveTo];
}

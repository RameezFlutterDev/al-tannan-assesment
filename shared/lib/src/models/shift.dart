import 'package:equatable/equatable.dart';

class Shift extends Equatable {
  const Shift({
    required this.id,
    required this.name,
    required this.startMinutes,
    required this.endMinutes,
    required this.graceMinutes,
    required this.isActive,
  });

  final String id;
  final String name;

  /// Minutes since midnight (0-1439), as raw numbers with no timezone
  /// conversion applied — matches whatever the admin panel's time picker
  /// shows, compared directly against a check-in's local device time (see
  /// [CompanyTime]). e.g. 7:00 AM = 420. Stored as an int (not a "HH:mm"
  /// string) so late-minute arithmetic never involves string parsing.
  final int startMinutes;
  final int endMinutes;
  final int graceMinutes;
  final bool isActive;

  /// True if [endMinutes] is on the following day relative to [startMinutes]
  /// (e.g. a night shift 22:00-06:00). Attendance calculations that span
  /// midnight must account for this.
  bool get crossesMidnight => endMinutes <= startMinutes;

  String get startLabel => _formatMinutes(startMinutes);
  String get endLabel => _formatMinutes(endMinutes);

  static String _formatMinutes(int minutes) {
    final h = (minutes ~/ 60) % 24;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  factory Shift.fromJson(String id, Map<String, dynamic> json) {
    return Shift(
      id: id,
      name: json['name'] as String,
      startMinutes: json['startMinutes'] as int,
      endMinutes: json['endMinutes'] as int,
      graceMinutes: json['graceMinutes'] as int,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'startMinutes': startMinutes,
        'endMinutes': endMinutes,
        'graceMinutes': graceMinutes,
        'isActive': isActive,
      };

  Shift copyWith({
    String? name,
    int? startMinutes,
    int? endMinutes,
    int? graceMinutes,
    bool? isActive,
  }) {
    return Shift(
      id: id,
      name: name ?? this.name,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      graceMinutes: graceMinutes ?? this.graceMinutes,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, startMinutes, endMinutes, graceMinutes, isActive];
}

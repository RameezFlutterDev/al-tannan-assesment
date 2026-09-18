import 'package:equatable/equatable.dart';

/// A single recorded action (time + location + link back to the full audit
/// event) as embedded inside an [AttendanceDay]. This is the "light"
/// summary used for the home screen / report table; the full
/// `AttendanceEvent` (with integrity result etc.) is looked up by
/// [eventId] for the admin's detailed view.
class AttendanceActionRecord extends Equatable {
  const AttendanceActionRecord({
    required this.eventId,
    required this.time,
    required this.latitude,
    required this.longitude,
  });

  final String eventId;
  final DateTime time;
  final double latitude;
  final double longitude;

  factory AttendanceActionRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceActionRecord(
      eventId: json['eventId'] as String,
      time: json['time'] as DateTime,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'time': time,
        'latitude': latitude,
        'longitude': longitude,
      };

  @override
  List<Object?> get props => [eventId, time, latitude, longitude];
}

/// One break cycle: a [breakOut] paired with its (possibly still-open)
/// [breakIn]. Multiple cycles per day are supported.
class BreakRecord extends Equatable {
  const BreakRecord({required this.breakOut, this.breakIn});

  final AttendanceActionRecord breakOut;
  final AttendanceActionRecord? breakIn;

  bool get isOpen => breakIn == null;

  int? get durationMinutes =>
      breakIn == null ? null : breakIn!.time.difference(breakOut.time).inMinutes;

  factory BreakRecord.fromJson(Map<String, dynamic> json) {
    return BreakRecord(
      breakOut: AttendanceActionRecord.fromJson(
          json['breakOut'] as Map<String, dynamic>),
      breakIn: json['breakIn'] == null
          ? null
          : AttendanceActionRecord.fromJson(
              json['breakIn'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'breakOut': breakOut.toJson(),
        'breakIn': breakIn?.toJson(),
      };

  BreakRecord copyWith({AttendanceActionRecord? breakIn}) {
    return BreakRecord(breakOut: breakOut, breakIn: breakIn ?? this.breakIn);
  }

  @override
  List<Object?> get props => [breakOut, breakIn];
}

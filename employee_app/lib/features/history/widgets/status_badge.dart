import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final AttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      AttendanceStatus.notStarted => ('Not Started', const Color(0xFFF1F5F9), const Color(0xFF64748B)),
      AttendanceStatus.onTime => ('On Time', const Color(0xFFD1FAE5), const Color(0xFF065F46)),
      AttendanceStatus.late => ('Late', const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      AttendanceStatus.incomplete => ('Incomplete', const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
      AttendanceStatus.absent => ('Absent', const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

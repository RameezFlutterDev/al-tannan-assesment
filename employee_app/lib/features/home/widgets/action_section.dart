import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../attendance/controllers/attendance_controller.dart';
import '../controllers/home_controller.dart';

class ActionSection extends StatelessWidget {
  const ActionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();
    Get.put(AttendanceController());
    final nextAction = home.state.suggestedNextAction;

    return GetBuilder<AttendanceController>(
      builder: (attendance) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (attendance.message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: attendance.status == AttendanceSubmitStatus.error
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: attendance.status == AttendanceSubmitStatus.error
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFFA7F3D0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        attendance.status == AttendanceSubmitStatus.error
                            ? Icons.error_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        color: attendance.status == AttendanceSubmitStatus.error
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          attendance.message!,
                          style: TextStyle(
                            color:
                                attendance.status ==
                                    AttendanceSubmitStatus.error
                                ? const Color(0xFF991B1B)
                                : const Color(0xFF065F46),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (home.state == AttendanceDayState.checkedIn) ...[
              ElevatedButton.icon(
                onPressed: attendance.status == AttendanceSubmitStatus.loading
                    ? null
                    : () => attendance.performAction(
                        AttendanceActionType.breakOut,
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.free_breakfast_rounded),
                label: const Text(
                  'Break Out',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: attendance.status == AttendanceSubmitStatus.loading
                    ? null
                    : () => attendance.performAction(
                        AttendanceActionType.checkOut,
                      ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  'Check Out',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ] else if (nextAction != null)
              FilledButton.icon(
                onPressed: attendance.status == AttendanceSubmitStatus.loading
                    ? null
                    : () => attendance.performAction(nextAction),
                style: FilledButton.styleFrom(
                  backgroundColor: nextAction == AttendanceActionType.checkIn
                      ? const Color(0xFF10B981)
                      : const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor:
                      (nextAction == AttendanceActionType.checkIn
                              ? const Color(0xFF10B981)
                              : const Color(0xFF4F46E5))
                          .withValues(alpha: 0.4),
                ),
                icon: attendance.status == AttendanceSubmitStatus.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Icon(_actionIcon(nextAction), size: 22),
                label: Text(
                  _actionLabel(nextAction),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.task_alt_rounded, color: Color(0xFF10B981)),
                    SizedBox(width: 8),
                    Text(
                      'No further actions required today.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  IconData _actionIcon(AttendanceActionType action) {
    switch (action) {
      case AttendanceActionType.checkIn:
        return Icons.fingerprint_rounded;
      case AttendanceActionType.breakOut:
        return Icons.free_breakfast_rounded;
      case AttendanceActionType.breakIn:
        return Icons.play_arrow_rounded;
      case AttendanceActionType.checkOut:
        return Icons.logout_rounded;
    }
  }

  String _actionLabel(AttendanceActionType action) {
    switch (action) {
      case AttendanceActionType.checkIn:
        return 'Check In Now';
      case AttendanceActionType.breakOut:
        return 'Start Break (Break Out)';
      case AttendanceActionType.breakIn:
        return 'Resume Work (Break In)';
      case AttendanceActionType.checkOut:
        return 'Complete Day (Check Out)';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../controllers/home_controller.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({super.key, required this.home});
  final HomeController home;

  @override
  Widget build(BuildContext context) {
    final day = home.today;
    final state = home.state;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.today_rounded,
                  color: Color(0xFF4F46E5),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Today\'s Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                _StatusChip(state: state, isLate: day?.isLate ?? false),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _TimeRow(
              label: 'Check In',
              record: day?.checkIn,
              icon: Icons.login_rounded,
            ),
            for (final b in day?.breaks ?? const []) ...[
              _TimeRow(
                label: 'Break Out',
                record: b.breakOut,
                icon: Icons.free_breakfast_outlined,
              ),
              _TimeRow(
                label: 'Break In',
                record: b.breakIn,
                icon: Icons.play_circle_outline,
              ),
            ],
            _TimeRow(
              label: 'Check Out',
              record: day?.checkOut,
              icon: Icons.logout_rounded,
            ),
            if (day?.isLate ?? false) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFD97706),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Late by ${day!.lateMinutes} min',
                      style: const TextStyle(
                        color: Color(0xFFB45309),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (day?.netWorkMinutes != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'Net Work',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${day!.netWorkMinutes} min',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 24,
                      width: 1,
                      color: const Color(0xFFCBD5E1),
                    ),
                    Column(
                      children: [
                        const Text(
                          'Break Duration',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${day.breakDurationMinutes} min',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.record,
    required this.icon,
  });
  final String label;
  final AttendanceActionRecord? record;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            record == null ? '— —' : _formatTime(record!.time),
            style: TextStyle(
              fontWeight: record == null ? FontWeight.normal : FontWeight.bold,
              color: record == null
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF0F172A),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.state, required this.isLate});
  final AttendanceDayState state;
  final bool isLate;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (state) {
      AttendanceDayState.notStarted => (
        'Not Started',
        const Color(0xFFF1F5F9),
        const Color(0xFF64748B),
      ),
      AttendanceDayState.checkedIn => (
        isLate ? 'Checked In (Late)' : 'Checked In',
        isLate ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
        isLate ? const Color(0xFFB45309) : const Color(0xFF065F46),
      ),
      AttendanceDayState.onBreak => (
        'On Break',
        const Color(0xFFE0F2FE),
        const Color(0xFF0369A1),
      ),
      AttendanceDayState.completed => (
        'Completed',
        const Color(0xFFCCFBF1),
        const Color(0xFF0F766E),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

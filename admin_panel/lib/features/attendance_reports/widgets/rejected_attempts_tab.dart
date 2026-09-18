import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/reports_controller.dart';

class RejectedAttemptsTab extends StatelessWidget {
  const RejectedAttemptsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReportsController>(
      builder: (controller) {
        if (controller.isLoadingRejected) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.rejectedError != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Could not load the rejected-attempts log:\n${controller.rejectedError}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          );
        }
        if (controller.rejectedAttempts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    size: 48,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No rejected attempts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'All check-ins and check-outs passed integrity checks',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: controller.rejectedAttempts.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final e = controller.rejectedAttempts[index];
            final employee = controller.employeeById(e.employeeId);
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.gpp_bad_rounded, color: Color(0xFFEF4444), size: 24),
                ),
                title: Text(
                  '${employee?.name ?? e.employeeId} — ${e.actionType.wireValue.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${_formatDateTime(e.serverTimestamp)} • ${e.integrityResult.wireValue}\n'
                    'Location: ${e.latitude.toStringAsFixed(5)}, ${e.longitude.toStringAsFixed(5)}'
                    '${e.rejectionReason != null ? '\nReason: ${e.rejectionReason}' : ''}',
                    style: const TextStyle(color: Color(0xFF64748B), height: 1.3),
                  ),
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  String _formatDateTime(DateTime time) {
    final local = time.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

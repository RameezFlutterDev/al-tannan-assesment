import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/admin_scaffold.dart';
import '../../../app/routes/app_routes.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/summary_tile.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(DashboardController());

    return AdminScaffold(
      title: 'Dashboard Overview',
      currentRoute: AppRoutes.dashboard,
      body: GetBuilder<DashboardController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          final tiles = [
            SummaryTile(
              label: 'Present Today',
              value: controller.presentCount,
              color: const Color(0xFF10B981), // Emerald
              icon: Icons.check_circle_outline_rounded,
            ),
            SummaryTile(
              label: 'Checked In',
              value: controller.checkedInCount,
              color: const Color(0xFF0EA5E9), // Sky
              icon: Icons.login_rounded,
            ),
            SummaryTile(
              label: 'On Break',
              value: controller.onBreakCount,
              color: const Color(0xFF8B5CF6), // Purple
              icon: Icons.free_breakfast_outlined,
            ),
            SummaryTile(
              label: 'Checked Out',
              value: controller.checkedOutCount,
              color: const Color(0xFF6366F1), // Indigo
              icon: Icons.logout_rounded,
            ),
            SummaryTile(
              label: 'Late',
              value: controller.lateCount,
              color: const Color(0xFFF59E0B), // Amber
              icon: Icons.schedule_rounded,
            ),
            SummaryTile(
              label: 'Absent / Not Checked In',
              value: controller.absentCount,
              color: const Color(0xFFEF4444), // Red
              icon: Icons.person_off_rounded,
            ),
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Attendance Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.8,
                  children: tiles,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/admin_scaffold.dart';
import '../../../app/routes/app_routes.dart';
import '../controllers/reports_controller.dart';
import '../widgets/daily_report_tab.dart';
import '../widgets/rejected_attempts_tab.dart';

class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ReportsController());

    return DefaultTabController(
      length: 2,
      child: AdminScaffold(
        title: 'Attendance Reports & Audit',
        currentRoute: AppRoutes.reports,
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: const TabBar(
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    icon: Icon(Icons.analytics_outlined, size: 20),
                    text: 'Daily Report',
                  ),
                  Tab(
                    icon: Icon(Icons.security_outlined, size: 20),
                    text: 'Rejected Attempts Log',
                  ),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(children: [DailyReportTab(), RejectedAttemptsTab()]),
            ),
          ],
        ),
      ),
    );
  }
}

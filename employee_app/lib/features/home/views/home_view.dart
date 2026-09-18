import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/home_controller.dart';
import '../widgets/action_section.dart';
import '../widgets/assignment_card.dart';
import '../widgets/status_card.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Attendance History',
            onPressed: () => Get.toNamed(AppRoutes.history),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            tooltip: 'Sign out',
            onPressed: () async {
              await Get.find<AuthController>().signOut();
              Get.offAllNamed(AppRoutes.login);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GetBuilder<HomeController>(
        builder: (home) => home.isLoadingAssignment
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {},
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    AssignmentCard(home: home),
                    const SizedBox(height: 20),
                    StatusCard(home: home),
                    const SizedBox(height: 24),
                    // NOT const: reads home.state/nextAction in its own
                    // build() outside its inner GetBuilder, so a frozen
                    // const instance would never pick up state changes
                    // (this caused the "action not available" bug before).
                    ActionSection(),
                  ],
                ),
              ),
      ),
    );
  }
}

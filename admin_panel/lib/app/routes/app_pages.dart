import 'package:get/get.dart';

import '../../features/attendance_reports/views/reports_view.dart';
import '../../features/auth/controllers/login_controller.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/dashboard/views/dashboard_view.dart';
import '../../features/employees/views/employees_view.dart';
import '../../features/locations/views/locations_view.dart';
import '../../features/shifts/views/shifts_view.dart';
import 'app_routes.dart';
import 'auth_middleware.dart';

final appPages = [
  GetPage(
    name: AppRoutes.login,
    page: () => const LoginView(),
    binding: BindingsBuilder(() {
      Get.put(LoginController());
    }),
  ),
  GetPage(
    name: AppRoutes.dashboard,
    page: () => const DashboardView(),
    middlewares: [AuthMiddleware()],
  ),
  GetPage(
    name: AppRoutes.employees,
    page: () => const EmployeesView(),
    middlewares: [AuthMiddleware()],
  ),
  GetPage(
    name: AppRoutes.shifts,
    page: () => const ShiftsView(),
    middlewares: [AuthMiddleware()],
  ),
  GetPage(
    name: AppRoutes.locations,
    page: () => const LocationsView(),
    middlewares: [AuthMiddleware()],
  ),
  GetPage(
    name: AppRoutes.reports,
    page: () => const ReportsView(),
    middlewares: [AuthMiddleware()],
  ),
];

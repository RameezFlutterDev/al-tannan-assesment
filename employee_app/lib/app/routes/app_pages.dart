import 'package:get/get.dart';

import '../../features/auth/controllers/login_controller.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/history/views/history_view.dart';
import '../../features/home/controllers/home_controller.dart';
import '../../features/home/views/home_view.dart';
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
    name: AppRoutes.home,
    page: () => const HomeView(),
    binding: BindingsBuilder(() {
      Get.put(HomeController());
    }),
    middlewares: [AuthMiddleware()],
  ),
  GetPage(
    name: AppRoutes.history,
    page: () => const HistoryView(),
    middlewares: [AuthMiddleware()],
  ),
];

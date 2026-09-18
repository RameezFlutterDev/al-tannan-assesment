import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../features/auth/controllers/auth_controller.dart';
import 'app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final isLoggedIn = Get.find<AuthController>().isLoggedIn;
    if (!isLoggedIn && route != AppRoutes.login) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}

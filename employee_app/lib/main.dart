import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/core/employee_theme.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final authController = Get.put(AuthController());
  var initialRoute = AppRoutes.login;
  if (authController.isLoggedIn && await authController.restoreSession()) {
    initialRoute = AppRoutes.home;
  }

  runApp(EmployeeApp(initialRoute: initialRoute));
}

class EmployeeApp extends StatelessWidget {
  const EmployeeApp({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Al Tannan Attendance',
      debugShowCheckedModeBanner: false,
      theme: EmployeeTheme.themeData,
      initialRoute: initialRoute,
      getPages: appPages,
    );
  }
}

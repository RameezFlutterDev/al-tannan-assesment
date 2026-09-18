import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import 'auth_controller.dart';

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;

  void toggleObscurePassword() {
    obscurePassword = !obscurePassword;
    update();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    final ok = await Get.find<AuthController>()
        .signIn(emailController.text, passwordController.text);
    if (ok) {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}

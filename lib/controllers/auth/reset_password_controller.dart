import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';
import '../../utils/ui_utils.dart';
import '../../screens/auth/login_screen.dart';

class ResetPasswordController extends GetxController {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final isLoading = false.obs;

  void toggleObscurePassword() => obscurePassword.value = !obscurePassword.value;
  void toggleObscureConfirmPassword() => obscureConfirmPassword.value = !obscureConfirmPassword.value;

  Future<void> resetPassword(String mobile) async {
    if (passwordController.text.trim().isEmpty || confirmPasswordController.text.trim().isEmpty) {
      UIUtils.showTopMessage(Get.context!, 'Please fill all fields', isError: true);
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      UIUtils.showTopMessage(Get.context!, 'Passwords do not match', isError: true);
      return;
    }

    String pwd = passwordController.text.trim();
    if (pwd.length < 6) {
      UIUtils.showTopMessage(
        Get.context!,
        'Password must be at least 6 characters',
        isError: true,
      );
      return;
    }

    isLoading.value = true;
    try {
      final result = await AuthService.resetPassword(
        mobile: mobile,
        password: pwd,
      );
      
      UIUtils.showTopMessage(Get.context!, result['message']?.toString() ?? 'Password reset successful.');

      Get.offAll(() => const LoginScreen());
    } catch (e) {
      UIUtils.showTopMessage(Get.context!, e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}

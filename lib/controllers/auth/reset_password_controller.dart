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
      UIUtils.showTopMessage(Get.context!, 'PINs do not match', isError: true);
      return;
    }

    // PIN Validation: 4 digit numeric as per user request
    String pin = passwordController.text.trim();
    if (pin.length != 4 || !RegExp(r'^[0-9]+$').hasMatch(pin)) {
      UIUtils.showTopMessage(
        Get.context!,
        'PIN must be exactly 4 numeric digits',
        isError: true,
      );
      return;
    }

    isLoading.value = true;
    try {
      final result = await AuthService.resetPassword(
        mobile: mobile,
        password: pin,
      );
      
      UIUtils.showTopMessage(Get.context!, result['message']?.toString() ?? 'PIN reset successful.');
      
      // Update locally saved auth method to PIN since they just set one
      await AuthService.saveAuthMethod(mobile, 'PIN');

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

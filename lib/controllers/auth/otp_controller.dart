import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/ui_utils.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/reset_password_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';

class OtpController extends GetxController {
  final List<TextEditingController> controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());
  final isLoading = false.obs;

  // Flows: 'registration', 'forgot_password', 'login'
  void verifyOtp(String mobile, String flow) {
    String otp = controllers.map((c) => c.text).join();
    if (otp.length == 6) {
      isLoading.value = true;
      UIUtils.showTopMessage(Get.context!, 'Verification successful');
      
      Future.delayed(const Duration(seconds: 1), () {
        if (flow == 'forgot_password') {
          Get.off(() => ResetPasswordScreen(mobile: mobile));
        } else if (flow == 'login') {
          Get.offAll(() => const DashboardScreen());
        } else {
          // Default/Registration goes to login for fresh start or auto-login logic
          Get.offAll(() => const LoginScreen());
        }
      });
    } else {
      UIUtils.showTopMessage(Get.context!, 'Please enter 6-digit OTP', isError: true);
    }
  }

  String getMaskedMobile(String mobile) {
    if (mobile.length >= 10) {
      return '+91***${mobile.substring(mobile.length - 3)}';
    }
    return '+91 $mobile';
  }

  @override
  void onClose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.onClose();
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:country_picker/country_picker.dart';
import '../../services/auth_service.dart';
import '../../utils/ui_utils.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/auth/otp_screen.dart';

class LoginController extends GetxController {
  final mobileController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordFocusNode = FocusNode();
  
  final countryCode = '+91'.obs;
  final countryFlag = '🇮🇳'.obs;
  final obscurePassword = true.obs;
  final rememberMe = false.obs;
  final isLoading = false.obs;
  
  // 'PIN' or 'OTP'
  final loginMethod = 'PIN'.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to mobile changes to check if they registered with OTP or PIN
    mobileController.addListener(_checkAuthMethod);
  }

  Future<void> _checkAuthMethod() async {
    if (mobileController.text.trim().length == 10) {
      final method = await AuthService.getAuthMethod(mobileController.text.trim());
      if (method != null) {
        loginMethod.value = method;
      } else {
        loginMethod.value = 'PIN'; // default
      }
    }
  }

  void toggleObscure() => obscurePassword.value = !obscurePassword.value;
  void toggleRememberMe() => rememberMe.value = !rememberMe.value;

  void selectCountryCode(BuildContext context) {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (Country country) {
        countryCode.value = '+${country.phoneCode}';
        countryFlag.value = country.flagEmoji;
      },
    );
  }

  Future<void> login() async {
    if (mobileController.text.trim().isEmpty) {
      UIUtils.showTopMessage(Get.context!, 'Please enter mobile number', isError: true);
      return;
    }

    if (mobileController.text.trim().length != 10) {
      UIUtils.showTopMessage(Get.context!, 'Mobile number must be 10 digits', isError: true);
      return;
    }
    
    if (loginMethod.value == 'PIN') {
      if (passwordController.text.trim().isEmpty) {
        UIUtils.showTopMessage(Get.context!, 'Please enter 4-digit PIN', isError: true);
        passwordFocusNode.requestFocus();
        return;
      }
      if (passwordController.text.length != 4) {
        UIUtils.showTopMessage(Get.context!, 'PIN must be 4 digits', isError: true);
        return;
      }
    } else {
      // OTP Method: Navigate to OTP verification instead of login directly
      UIUtils.showTopMessage(Get.context!, 'Sending OTP to ${mobileController.text.trim()}');
      Get.to(() => OtpScreen(mobile: mobileController.text.trim(), flow: 'login'));
      return;
    }

    isLoading.value = true;

    try {
      final result = await AuthService.login(
        username: mobileController.text.trim(),
        password: passwordController.text.trim(),
      );

      UIUtils.showTopMessage(Get.context!, result['message']?.toString() ?? 'Login successful');
      Get.offAll(() => const DashboardScreen());
    } catch (e) {
      UIUtils.showTopMessage(Get.context!, e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    mobileController.removeListener(_checkAuthMethod);
    mobileController.dispose();
    passwordController.dispose();
    passwordFocusNode.dispose();
    super.onClose();
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:country_picker/country_picker.dart';
import '../../services/auth_service.dart';
import '../../utils/ui_utils.dart';
import '../../screens/dashboard/dashboard_screen.dart';

class LoginController extends GetxController {
  final mobileController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordFocusNode = FocusNode();
  
  final countryCode = '+91'.obs;
  final countryFlag = '🇮🇳'.obs;
  final obscurePassword = true.obs;
  final rememberMe = false.obs;
  final isLoading = false.obs;

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
    
    if (passwordController.text.trim().isEmpty) {
      UIUtils.showTopMessage(Get.context!, 'Please enter password', isError: true);
      passwordFocusNode.requestFocus();
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
    mobileController.dispose();
    passwordController.dispose();
    passwordFocusNode.dispose();
    super.onClose();
  }
}

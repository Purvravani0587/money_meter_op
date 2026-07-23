import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:country_picker/country_picker.dart';
import '../../utils/ui_utils.dart';
import '../../screens/auth/otp_screen.dart';

class ForgotPasswordController extends GetxController {
  final mobileController = TextEditingController();
  final isLoading = false.obs;
  final countryCode = '+91'.obs;
  final countryFlag = '🇮🇳'.obs;

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

  Future<void> sendOtp() async {
    if (mobileController.text.trim().length != 10) {
      UIUtils.showTopMessage(Get.context!, 'Please enter a valid 10-digit mobile number', isError: true);
      return;
    }

    isLoading.value = true;
    try {
      // Simulate OTP sending
      await Future.delayed(const Duration(seconds: 1));
      
      UIUtils.showTopMessage(Get.context!, 'OTP sent successfully to ${countryCode.value} ${mobileController.text.trim()}');
      
      Get.to(() => OtpScreen(
        mobile: mobileController.text.trim(),
        flow: 'forgot_password',
      ));
    } catch (e) {
      UIUtils.showTopMessage(Get.context!, 'Failed to send OTP', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    mobileController.dispose();
    super.onClose();
  }
}

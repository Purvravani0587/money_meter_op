import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import '../../utils/ui_utils.dart';

class ForgotPasswordController extends ChangeNotifier {
  final mobileController = TextEditingController();
  bool isLoading = false;
  String countryCode = '+91';
  String countryFlag = '🇮🇳';

  void selectCountryCode(BuildContext context) {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (Country country) {
        countryCode = '+${country.phoneCode}';
        countryFlag = country.flagEmoji;
        notifyListeners();
      },
    );
  }

  /// Returns the mobile number on success for screen-level navigation.
  Future<String?> sendOtp(BuildContext context) async {
    if (mobileController.text.trim().length != 10) {
      UIUtils.showTopMessage(
          context, 'Please enter a valid 10-digit mobile number',
          isError: true);
      return null;
    }

    isLoading = true;
    notifyListeners();
    try {
      await Future.delayed(const Duration(seconds: 1));
      // ignore: use_build_context_synchronously
      UIUtils.showTopMessage(
          context, 'OTP sent successfully to $countryCode ${mobileController.text.trim()}');
      return mobileController.text.trim();
    } catch (e) {
      // ignore: use_build_context_synchronously
      UIUtils.showTopMessage(context, 'Failed to send OTP', isError: true);
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    mobileController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import '../../services/auth_service.dart';
import '../../utils/ui_utils.dart';

class LoginController extends ChangeNotifier {
  final mobileController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordFocusNode = FocusNode();

  String countryCode = '+91';
  String countryFlag = '🇮🇳';
  bool obscurePassword = true;
  bool rememberMe = false;
  bool isLoading = false;
  String familyIdText = '';

  LoginController() {
    _loadFamilyId();
  }

  Future<void> _loadFamilyId() async {
    final fid = await AuthService.getFamilyId();
    familyIdText = 'Family ID: $fid';
    debugPrint('Current Family ID: $fid');
    notifyListeners();
  }

  void toggleObscure() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void toggleRememberMe() {
    rememberMe = !rememberMe;
    notifyListeners();
  }

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

  /// Returns true on successful login so the screen can navigate.
  Future<bool> login(BuildContext context) async {
    if (mobileController.text.trim().isEmpty) {
      UIUtils.showTopMessage(context, 'Please enter mobile number', isError: true);
      return false;
    }

    if (mobileController.text.trim().length != 10) {
      UIUtils.showTopMessage(context, 'Mobile number must be 10 digits', isError: true);
      return false;
    }

    if (passwordController.text.trim().isEmpty) {
      UIUtils.showTopMessage(context, 'Please enter password', isError: true);
      passwordFocusNode.requestFocus();
      return false;
    }

    isLoading = true;
    notifyListeners();

    try {
      final result = await AuthService.login(
        username: mobileController.text.trim(),
        password: passwordController.text.trim(),
      );

      final familyId = await AuthService.getFamilyId();
      debugPrint('Family ID: $familyId');
      familyIdText = 'Family ID: $familyId';

      // ignore: use_build_context_synchronously
      UIUtils.showTopMessage(
        context,
        '${result['message']?.toString() ?? 'Login successful'} | Family ID: $familyId',
      );
      return true;
    } catch (e) {
      // ignore: use_build_context_synchronously
      UIUtils.showTopMessage(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    mobileController.dispose();
    passwordController.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }
}

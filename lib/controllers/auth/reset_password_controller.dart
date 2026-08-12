import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/ui_utils.dart';

class ResetPasswordController extends ChangeNotifier {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  void toggleObscurePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void toggleObscureConfirmPassword() {
    obscureConfirmPassword = !obscureConfirmPassword;
    notifyListeners();
  }

  /// Returns true on success so the screen can navigate.
  Future<bool> resetPassword(BuildContext context, String mobile) async {
    if (passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty) {
      UIUtils.showTopMessage(context, 'Please fill all fields', isError: true);
      return false;
    }

    if (passwordController.text != confirmPasswordController.text) {
      UIUtils.showTopMessage(context, 'Passwords do not match', isError: true);
      return false;
    }

    final pwd = passwordController.text.trim();
    if (pwd.length < 6) {
      UIUtils.showTopMessage(
          context, 'Password must be at least 6 characters',
          isError: true);
      return false;
    }

    isLoading = true;
    notifyListeners();
    try {
      final result = await AuthService.resetPassword(
        mobile: mobile,
        password: pwd,
      );
      // ignore: use_build_context_synchronously
      UIUtils.showTopMessage(
          context, result['message']?.toString() ?? 'Password reset successful.');
      return true;
    } catch (e) {
      // ignore: use_build_context_synchronously
      UIUtils.showTopMessage(
          context, e.toString().replaceFirst('Exception: ', ''),
          isError: true);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}

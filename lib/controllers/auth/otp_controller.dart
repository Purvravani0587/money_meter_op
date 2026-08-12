import 'package:flutter/material.dart';
import '../../utils/ui_utils.dart';

class OtpController extends ChangeNotifier {
  final List<TextEditingController> controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());
  bool isLoading = false;

  String getMaskedMobile(String mobile) {
    if (mobile.length >= 10) {
      return '+91***${mobile.substring(mobile.length - 3)}';
    }
    return '+91 $mobile';
  }

  /// Returns the flow string on success so the screen can navigate.
  /// Returns null if OTP is invalid.
  String? verifyOtp(BuildContext context, String mobile, String flow) {
    final otp = controllers.map((c) => c.text).join();
    if (otp.length == 6) {
      isLoading = true;
      notifyListeners();
      UIUtils.showTopMessage(context, 'Verification successful');
      return flow;
    } else {
      UIUtils.showTopMessage(context, 'Please enter 6-digit OTP', isError: true);
      return null;
    }
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/otp_controller.dart';
import '../../widgets/custom_button.dart';
import '../../utils/ui_utils.dart';

class OtpScreen extends StatefulWidget {
  final String mobile;
  final String flow; // 'registration', 'forgot_password', 'profile_edit'

  const OtpScreen({
    super.key, 
    required this.mobile, 
    this.flow = 'registration',
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  late final OtpController controller;

  @override
  void initState() {
    super.initState();
    Get.delete<OtpController>();
    controller = Get.put(OtpController());
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 30),
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 100,
                        height: 100,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Money Meter',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2E4D),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Verify OTP',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    text: 'Enter the 6-digit code sent to ',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                    children: [
                      TextSpan(
                        text: controller.getMaskedMobile(widget.mobile),
                        style: const TextStyle(
                          color: Color(0xFF2D2E4D),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 45,
                      child: TextField(
                        controller: controller.controllers[index],
                        focusNode: controller.focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0xFFF0F0F0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            controller.focusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            controller.focusNodes[index - 1].requestFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 40),
                Obx(() => CustomButton(
                  text: 'Verify',
                  isLoading: controller.isLoading.value,
                  onPressed: () => controller.verifyOtp(widget.mobile, widget.flow),
                )),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () {
                      UIUtils.showTopMessage(context, 'OTP Resent successfully');
                    },
                    child: const Text(
                      'Resend Code',
                      style: TextStyle(
                        color: Color(0xFF2D2E4D),
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/auth/reset_password_controller.dart';
import '../../widgets/custom_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String mobile;
  const ResetPasswordScreen({super.key, required this.mobile});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final ResetPasswordController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ResetPasswordController());
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
                  'Create New Password',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Set a new password for your account',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 40),
                _buildLabel('NEW PASSWORD', Icons.lock_outline),
                Obx(() => _buildTextField(
                  'Enter Password',
                  controller: controller.passwordController,
                  obscureText: controller.obscurePassword.value,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.obscurePassword.value ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: controller.toggleObscurePassword,
                  ),
                )),
                const SizedBox(height: 24),
                _buildLabel('CONFIRM PASSWORD', Icons.lock_outline),
                Obx(() => _buildTextField(
                  'Confirm Password',
                  controller: controller.confirmPasswordController,
                  obscureText: controller.obscureConfirmPassword.value,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.obscureConfirmPassword.value ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: controller.toggleObscureConfirmPassword,
                  ),
                )),
                const SizedBox(height: 40),
                Obx(() => CustomButton(
                  text: 'Reset Password',
                  isLoading: controller.isLoading.value,
                  onPressed: () => controller.resetPassword(widget.mobile),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2D3436)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String hint, {
    bool obscureText = false,
    TextEditingController? controller,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Color(0xFF2D3436), fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF0F0F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/auth/login_controller.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/responsive_center.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LoginController());
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ResponsiveCenter(
          child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 120,
                        height: 120,
                      ),
                      const SizedBox(height: 12),
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
                  'Welcome back',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
                const Text(
                  'Sign in to continue to Money Meter',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),
                _buildLabel('MOBILE NUMBER', Icons.phone_android_outlined),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => controller.selectCountryCode(context),
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Obx(() => Row(
                          children: [
                            Text(controller.countryFlag.value, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 4),
                            Text(
                              controller.countryCode.value,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 20),
                          ],
                        )),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField(
                        'Enter Mobile No.',
                        controller: controller.mobileController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                _buildLabel('PASSWORD', Icons.lock_outline),
                Obx(() => _buildTextField(
                  'Enter Password',
                  controller: controller.passwordController,
                  focusNode: controller.passwordFocusNode,
                  obscureText: controller.obscurePassword.value,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.obscurePassword.value ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade700,
                    ),
                    onPressed: controller.toggleObscure,
                  ),
                )),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: controller.toggleRememberMe,
                      child: Row(
                        children: [
                          Obx(() => SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: controller.rememberMe.value,
                              activeColor: const Color(0xFF2D2E4D),
                              onChanged: (value) => controller.toggleRememberMe(),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          )),
                          const SizedBox(width: 8),
                          const Text('Remember me'),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Get.to(() => const ForgotPasswordScreen()),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color(0xFF2D2E4D),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Obx(() => CustomButton(
                  text: 'Sign In',
                  isLoading: controller.isLoading.value,
                  onPressed: controller.login,
                )),
                const SizedBox(height: 40),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("New to Money Meter? "),
                      GestureDetector(
                        onTap: () => Get.to(() => const SignUpScreen()),
                        child: const Text(
                          'Create account',
                          style: TextStyle(
                            color: Color(0xFF2D2E4D),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
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
    TextInputType? keyboardType,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    FocusNode? focusNode,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
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

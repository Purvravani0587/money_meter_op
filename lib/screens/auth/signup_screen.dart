import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/auth/signup_controller.dart';
import '../../widgets/custom_button.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensuring controller is initialized
    final controller = Get.put(SignUpController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
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
                const SizedBox(height: 30),
                const Text(
                  'Create account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
                const Text(
                  'Takes less than a minute',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),
                
                _buildLabel('FULL NAME', Icons.person_outline),
                _buildTextField('Enter Full Name', controller: controller.fullNameController),
                
                const SizedBox(height: 24),
                _buildLabel('MOBILE NO.', Icons.phone_android_outlined),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => controller.selectCountryCode(context),
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Obx(() => Row(
                          children: [
                            Text(controller.countryFlag.value, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 4),
                            Text(
                              controller.countryCode.value,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 20),
                          ],
                        )),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildTextField(
                        'Mobile No.',
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
                _buildLabel('DATE OF BIRTH', Icons.calendar_today_outlined),
                _buildTextField(
                  'DD/MM/YYYY',
                  controller: controller.dobController,
                  readOnly: true,
                  onTap: () => controller.selectDate(context),
                ),
                const SizedBox(height: 24),
                _buildLabel('GENDER', Icons.wc_outlined),
                Row(
                  children: [
                    Obx(() => _buildRadio('Male', 'M', controller.gender.value, (v) => controller.setGender(v))),
                    const SizedBox(width: 20),
                    Obx(() => _buildRadio('Female', 'F', controller.gender.value, (v) => controller.setGender(v))),
                  ],
                ),

                const SizedBox(height: 24),
                _buildLabel('PASSWORD', Icons.lock_outline),
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

                const SizedBox(height: 24),
                _buildLabel('EMAIL (OPTIONAL)', Icons.email_outlined),
                _buildTextField('Enter Your Email', controller: controller.emailController, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 24),
                _buildLabel('ADDRESS', Icons.location_on_outlined),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'Enter Your Address',
                        controller: controller.addressController,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 52,
                      child: Obx(() => ElevatedButton.icon(
                        onPressed: controller.isGettingLocation.value ? null : controller.getCurrentLocation,
                        icon: controller.isGettingLocation.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location, size: 18),
                        label: const Text('Use current', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5CE7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildLabel('LANDMARK (OPTIONAL)', Icons.flag_outlined),
                _buildTextField('Enter Your Landmark', controller: controller.landmarkController),
                
                const SizedBox(height: 40),
                Obx(() => CustomButton(
                  text: 'Create Account',
                  isLoading: controller.isLoading.value,
                  onPressed: controller.register,
                )),
                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already registered? "),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: const Text(
                          'Sign in',
                          style: TextStyle(
                            color: Color(0xFF6C5CE7),
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
    );
  }

  Widget _buildRadio(String label, String value, String groupValue, Function(String) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Row(
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Radio<String>(
              // ignore: deprecated_member_use
              value: value,
              // ignore: deprecated_member_use
              groupValue: groupValue,
              // ignore: deprecated_member_use
              onChanged: (val) => onChanged(val!),
              activeColor: const Color(0xFF6C5CE7),
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
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
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      onTap: onTap,
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

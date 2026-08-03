import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:country_picker/country_picker.dart';
import '../../services/auth_service.dart';
import '../../utils/ui_utils.dart';
import '../../screens/auth/otp_screen.dart';

class SignUpController extends GetxController {
  final fullNameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final addressController = TextEditingController();
  final landmarkController = TextEditingController();
  final dobController = TextEditingController();

  final countryCode = '+91'.obs;
  final countryFlag = '🇮🇳'.obs;
  final gender = 'M'.obs;
  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final isLoading = false.obs;
  final isGettingLocation = false.obs;
  
  String currentLatitude = '';
  String currentLongitude = '';

  void setGender(String value) => gender.value = value;
  void toggleObscurePassword() => obscurePassword.value = !obscurePassword.value;
  void toggleObscureConfirmPassword() => obscureConfirmPassword.value = !obscureConfirmPassword.value;

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

  Future<void> selectDate(BuildContext context) async {
    final now = DateTime.now();
    // Enforce 18+ age restriction
    final maxDate = DateTime(now.year - 18, now.month, now.day);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: maxDate,
      firstDate: DateTime(1900),
      lastDate: maxDate,
    );
    if (picked != null) {
      dobController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  Future<void> getCurrentLocation() async {
    isGettingLocation.value = true;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled. Please enable GPS.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) throw Exception('Location permission is permanently denied.');
      if (permission == LocationPermission.denied) throw Exception('Location permission was denied.');

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final geocoding = Geocoding();
      final placemarks = await geocoding.placemarkFromCoordinates(position.latitude, position.longitude);
      final place = placemarks.isNotEmpty ? placemarks.first : null;
      final addressText = [
        place?.name,
        place?.locality,
        place?.administrativeArea,
        place?.country,
      ].whereType<String>().where((v) => v.trim().isNotEmpty).join(', ');

      currentLatitude = position.latitude.toString();
      currentLongitude = position.longitude.toString();
      addressController.text = addressText.isNotEmpty ? addressText : 'Lat: ${position.latitude}, Long: ${position.longitude}';
      
      UIUtils.showTopMessage(Get.context!, 'Current location captured');
    } catch (e) {
      UIUtils.showTopMessage(Get.context!, e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      isGettingLocation.value = false;
    }
  }

  Future<void> register() async {
    if (fullNameController.text.trim().isEmpty ||
        mobileController.text.trim().isEmpty ||
        dobController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty) {
      UIUtils.showTopMessage(Get.context!, 'Please fill all required fields', isError: true);
      return;
    }

    if (mobileController.text.trim().length != 10) {
      UIUtils.showTopMessage(Get.context!, 'Mobile number must be 10 digits', isError: true);
      return;
    }

    if (passwordController.text.trim().isEmpty || confirmPasswordController.text.trim().isEmpty) {
      UIUtils.showTopMessage(Get.context!, 'Please enter password', isError: true);
      return;
    }
    if (passwordController.text.length < 6) {
      UIUtils.showTopMessage(Get.context!, 'Password must be at least 6 characters', isError: true);
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      UIUtils.showTopMessage(Get.context!, 'Passwords do not match', isError: true);
      return;
    }

    isLoading.value = true;
    try {
      final result = await AuthService.register(
        fullName: fullNameController.text.trim(),
        dob: dobController.text.trim(),
        gender: gender.value,
        email: emailController.text.trim(),
        mobile: mobileController.text.trim(),
        password: passwordController.text.trim(),
        confirmPassword: confirmPasswordController.text.trim(),
        address: addressController.text.trim(),
        landmark: landmarkController.text.trim(),
        latitude: currentLatitude.isNotEmpty ? currentLatitude : '1',
        longitude: currentLongitude.isNotEmpty ? currentLongitude : '1',
      );

      UIUtils.showTopMessage(Get.context!, result['message']?.toString() ?? 'Registration successful');
      Get.to(() => OtpScreen(mobile: mobileController.text.trim(), flow: 'registration'));
    } catch (e) {
      UIUtils.showTopMessage(Get.context!, e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    fullNameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    addressController.dispose();
    landmarkController.dispose();
    dobController.dispose();
    super.onClose();
  }
}

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:country_picker/country_picker.dart';
import '../../services/auth_service.dart';
import '../../utils/ui_utils.dart';

class SignUpController extends ChangeNotifier {
  final fullNameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final addressController = TextEditingController();
  final landmarkController = TextEditingController();
  final dobController = TextEditingController();

  String countryCode = '+91';
  String countryFlag = '🇮🇳';
  String gender = 'M';
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;
  bool isGettingLocation = false;

  String currentLatitude = '';
  String currentLongitude = '';

  void setGender(String value) {
    gender = value;
    notifyListeners();
  }

  void toggleObscurePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void toggleObscureConfirmPassword() {
    obscureConfirmPassword = !obscureConfirmPassword;
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

  Future<void> selectDate(BuildContext context) async {
    final now = DateTime.now();
    final maxDate = DateTime(now.year - 18, now.month, now.day);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: maxDate,
      firstDate: DateTime(1900),
      lastDate: maxDate,
    );
    if (picked != null) {
      dobController.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  String _formatDobForApi(String rawDob) {
    rawDob = rawDob.trim();
    if (rawDob.contains('/')) {
      final parts = rawDob.split('/');
      if (parts.length == 3) {
        if (parts[0].length <= 2 && parts[2].length == 4) {
          return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
        }
      }
    } else if (rawDob.contains('-')) {
      final parts = rawDob.split('-');
      if (parts.length == 3) {
        if (parts[0].length <= 2 && parts[2].length == 4) {
          return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
        }
      }
    }
    return rawDob;
  }

  Future<void> getCurrentLocation(BuildContext context) async {
    isGettingLocation = true;
    notifyListeners();
    try {
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        UIUtils.showTopMessage(
          context,
          'Location feature is not supported on Desktop. Please enter your address manually.',
          isError: true,
        );
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable GPS.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is permanently denied.');
      }
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      currentLatitude = position.latitude.toString();
      currentLongitude = position.longitude.toString();

      String addressText = '';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final parts = [
            place.name,
            place.subLocality,
            place.locality,
            place.administrativeArea,
            place.postalCode,
            place.country,
          ]
              .where((v) => v != null && v.toString().trim().isNotEmpty)
              .map((v) => v.toString().trim())
              .toSet()
              .toList();
          addressText = parts.join(', ');
        }
      } catch (_) {
        // Fallback to coordinates if reverse geocoding fails
      }

      if (addressText.isEmpty) {
        addressText =
            'Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}';
      }

      addressController.text = addressText;
      // ignore: use_build_context_synchronously
      UIUtils.showTopMessage(context, 'Current location captured');
    } catch (e) {
      final msg = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('TypeError: ', '');
      final cleanMsg =
          (msg.contains('Null check') || msg.contains('null'))
              ? 'Location not available on this device. Please enter address manually.'
              : msg;
      // ignore: use_build_context_synchronously
      UIUtils.showTopMessage(context, cleanMsg, isError: true);
    } finally {
      isGettingLocation = false;
      notifyListeners();
    }
  }

  /// Returns the mobile number on success (for navigation), null on failure.
  Future<String?> register(BuildContext context) async {
    if (fullNameController.text.trim().isEmpty ||
        mobileController.text.trim().isEmpty ||
        dobController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty) {
      UIUtils.showTopMessage(context, 'Please fill all required fields', isError: true);
      return null;
    }

    if (mobileController.text.trim().length != 10) {
      UIUtils.showTopMessage(context, 'Mobile number must be 10 digits', isError: true);
      return null;
    }

    if (passwordController.text.trim().isEmpty || confirmPasswordController.text.trim().isEmpty) {
      UIUtils.showTopMessage(context, 'Please enter password', isError: true);
      return null;
    }
    if (passwordController.text.length < 6) {
      UIUtils.showTopMessage(context, 'Password must be at least 6 characters', isError: true);
      return null;
    }
    if (passwordController.text != confirmPasswordController.text) {
      UIUtils.showTopMessage(context, 'Passwords do not match', isError: true);
      return null;
    }

    isLoading = true;
    notifyListeners();
    try {
      final formattedDob = _formatDobForApi(dobController.text);
      final result = await AuthService.register(
        fullName: fullNameController.text.trim(),
        dob: formattedDob,
        gender: gender,
        email: emailController.text.trim(),
        mobile: mobileController.text.trim(),
        password: passwordController.text.trim(),
        confirmPassword: confirmPasswordController.text.trim(),
        address: addressController.text.trim(),
        landmark: landmarkController.text.trim(),
        latitude: currentLatitude.isNotEmpty ? currentLatitude : '1',
        longitude: currentLongitude.isNotEmpty ? currentLongitude : '1',
      );

      // ignore: use_build_context_synchronously
      UIUtils.showTopMessage(context, result['message']?.toString() ?? 'Registration successful');
      return mobileController.text.trim();
    } catch (e) {
      // ignore: use_build_context_synchronously
      UIUtils.showTopMessage(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    addressController.dispose();
    landmarkController.dispose();
    dobController.dispose();
    super.dispose();
  }
}

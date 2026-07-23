import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../utils/ui_utils.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    final fullName = await AuthService.getUserName() ?? '';
    final mobile = await AuthService.getUserMobile() ?? '';
    // email and dob could be stored or fetched.
    
    final names = fullName.split(' ');
    _nameController.text = names.isNotEmpty ? names[0] : '';
    _surnameController.text = names.length > 1 ? names.sublist(1).join(' ') : '';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty || _surnameController.text.trim().isEmpty) {
      UIUtils.showTopMessage(context, 'Name and Surname are required', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    // Simulation: in real app, call API to update
    await Future.delayed(const Duration(seconds: 1));
    
    final newFullName = '${_nameController.text.trim()} ${_surnameController.text.trim()}';
    await AuthService.saveUserName(newFullName);
    
    if (mounted) {
      UIUtils.showTopMessage(context, 'Profile updated successfully');
      Get.back();
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: Color(0xFF2D2E4D), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D2E4D)),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('NAME', Icons.person_outline),
            _buildTextField('First Name', controller: _nameController),
            const SizedBox(height: 24),
            _buildLabel('SURNAME', Icons.person_outline),
            _buildTextField('Last Name', controller: _surnameController),
            const SizedBox(height: 24),
            _buildLabel('EMAIL', Icons.email_outlined),
            _buildTextField('Email', controller: _emailController, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 24),
            _buildLabel('DATE OF BIRTH', Icons.calendar_today_outlined),
            _buildTextField(
              'DD/MM/YYYY', 
              controller: _dobController, 
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: 'Save Changes',
              isLoading: _isLoading,
              onPressed: _updateProfile,
            ),
          ],
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
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, {TextEditingController? controller, bool readOnly = false, VoidCallback? onTap, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF0F0F0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

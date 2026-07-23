import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/ui_utils.dart';

class AddRecurringIncomeScreen extends StatefulWidget {
  const AddRecurringIncomeScreen({super.key});

  @override
  State<AddRecurringIncomeScreen> createState() => _AddRecurringIncomeScreenState();
}

class _AddRecurringIncomeScreenState extends State<AddRecurringIncomeScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _frequencyController = TextEditingController(text: 'Monthly');
  final _dueDateController = TextEditingController();
  bool _autoRemind = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _frequencyController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dueDateController.text = picked.toString().split(' ')[0];
      });
    }
  }

  Future<void> _saveIncome() async {
    if (_nameController.text.trim().isEmpty || _amountController.text.trim().isEmpty || _dueDateController.text.isEmpty) {
      UIUtils.showTopMessage(context, 'Please fill all required fields', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.createIncomeMaster(
        familyId: 1,
        incomeName: _nameController.text.trim(),
        incomeType: 'I',
        cycleMonths: 1,
        startDate: DateTime.now().toString().split(' ')[0],
        amount: int.tryParse(_amountController.text.trim()) ?? 0,
        nextDueDate: _dueDateController.text,
      );

      if (mounted) {
        UIUtils.showTopMessage(context, 'Income saved successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showTopMessage(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Purple Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF2D2E4D),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Add Recurring Income',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Track your regular earnings',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('INCOME NAME / SOURCE'),
                    _buildTextField('Monthly Salary', controller: _nameController),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('AMOUNT'),
                              _buildTextField('25000', controller: _amountController, keyboardType: TextInputType.number),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('CATEGORY'),
                              _buildTextField('Employment', controller: _categoryController),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('FREQUENCY'),
                              _buildTextField('Monthly', controller: _frequencyController, readOnly: true),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('EXPECTED DATE'),
                              _buildTextField('YYYY-MM-DD', controller: _dueDateController, readOnly: true, onTap: () => _selectDate(context)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Auto-notify me', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Switch(
                          value: _autoRemind,
                          onChanged: (val) => setState(() => _autoRemind = val),
                          activeColor: const Color(0xFF2D2E4D),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveIncome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D2E4D),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text(
                              'Save Income',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
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
        fillColor: const Color(0xFFF9F9F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

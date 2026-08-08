import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/auth_service.dart';
import '../utils/ui_utils.dart';
import '../widgets/responsive_center.dart';

class AddRecurringIncomeScreen extends StatefulWidget {
  final FamilyTransactionItem? item;
  final bool isViewOnly;

  const AddRecurringIncomeScreen({
    super.key,
    this.item,
    this.isViewOnly = false,
  });

  @override
  State<AddRecurringIncomeScreen> createState() => _AddRecurringIncomeScreenState();
}

class _AddRecurringIncomeScreenState extends State<AddRecurringIncomeScreen> {
  String _incomeType = '-- SELECT --';
  final _sourceNameController = TextEditingController();
  String _paymentCycle = 'Select Payment Cycle';
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _amountController = TextEditingController();
  String _paymentMode = '-- SELECT --';
  String _status = 'Active';
  final _descriptionController = TextEditingController();

  String? _doc1Name;
  String? _doc2Name;

  bool _isLoading = false;

  final List<String> _incomeTypeOptions = [
    '-- SELECT --',
    'Salary',
    'Business',
    'Investment',
    'Rental',
    'Other',
  ];

  final List<String> _paymentCycleOptions = [
    'Select Payment Cycle',
    'Daily',
    'Weekly',
    'Monthly',
    'Quarterly',
    'Yearly',
  ];

  final List<String> _paymentModeOptions = [
    '-- SELECT --',
    'Bank Transfer',
    'Cash',
    'UPI',
    'Cheque',
    'Other',
  ];

  final List<String> _statusOptions = [
    'Active',
    'Inactive',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _populateFromItem(widget.item!);
    }

    final id = int.tryParse(widget.item?.id ?? '');
    if (id != null) {
      _fetchIncomeDetail(id);
    }
  }

  void _populateFromItem(FamilyTransactionItem item) {
    if (item.name.isNotEmpty && item.name != 'Unnamed') {
      _sourceNameController.text = item.name;
    }
    if (item.amount.isNotEmpty && item.amount != '₹0') {
      _amountController.text = item.amount.replaceAll(RegExp(r'[^0-9]'), '');
    }

    final statusRaw = item.status;
    if (statusRaw.toUpperCase().startsWith('A') || statusRaw.toLowerCase() == 'active') {
      _status = 'Active';
    } else if (statusRaw.isNotEmpty) {
      _status = 'Inactive';
    }

    // End Date
    if (item.endDate.isNotEmpty) {
      _endDateController.text = item.endDate;
    } else if (item.date.isNotEmpty) {
      _endDateController.text = item.date;
    }

    // Start Date (Never leave blank)
    if (item.startDate.isNotEmpty) {
      _startDateController.text = item.startDate;
    } else if (_endDateController.text.isNotEmpty) {
      _startDateController.text = _endDateController.text;
    } else {
      final now = DateTime.now();
      _startDateController.text = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    }

    // Income Type
    if (item.type.isNotEmpty) {
      final t = item.type.toUpperCase();
      if (t == 'S' || item.type.contains('Salary')) {
        _incomeType = 'Salary';
      } else if (t == 'B' || item.type.contains('Business')) {
        _incomeType = 'Business';
      } else if (t == 'V' || item.type.contains('Investment')) {
        _incomeType = 'Investment';
      } else if (t == 'R' || item.type.contains('Rental')) {
        _incomeType = 'Rental';
      } else if (_incomeTypeOptions.contains(item.type)) {
        _incomeType = item.type;
      }
    }
    if (_incomeType == '-- SELECT --') {
      _incomeType = 'Salary';
    }

    // Payment Cycle
    if (item.paymentCycle.isNotEmpty) {
      final c = item.paymentCycle;
      if (c == '1' || c.toLowerCase().contains('month')) {
        _paymentCycle = 'Monthly';
      } else if (c == '3' || c.toLowerCase().contains('quarter')) {
        _paymentCycle = 'Quarterly';
      } else if (c == '12' || c.toLowerCase().contains('year')) {
        _paymentCycle = 'Yearly';
      } else if (c.toLowerCase().contains('week')) {
        _paymentCycle = 'Weekly';
      } else if (c.toLowerCase().contains('day')) {
        _paymentCycle = 'Daily';
      } else if (_paymentCycleOptions.contains(c)) {
        _paymentCycle = c;
      }
    }
    if (_paymentCycle == 'Select Payment Cycle' || _paymentCycle == '--SELECT--') {
      _paymentCycle = 'Monthly';
    }

    // Payment Mode
    if (item.paymentMode.isNotEmpty) {
      if (_paymentModeOptions.contains(item.paymentMode)) {
        _paymentMode = item.paymentMode;
      }
    }
    if (_paymentMode == '-- SELECT --') {
      _paymentMode = 'Bank Transfer';
    }

    // Description
    if (item.description.isNotEmpty) {
      _descriptionController.text = item.description;
    }
  }

  Future<void> _fetchIncomeDetail(int incomeId) async {
    try {
      final detail = await AuthService.getIncomeMasterDetail(incomeId: incomeId);
      if (detail != null && mounted) {
        setState(() {
          _populateFromItem(detail);
        });
      }
    } catch (_) {
      // Keep pre-populated state if fetch fails
    }
  }

  @override
  void dispose() {
    _sourceNameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    if (widget.isViewOnly) return;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  String _formatDateForApi(String dateStr) {
    if (dateStr.isEmpty) return DateTime.now().toString().split(' ')[0];
    if (dateStr.contains('/')) {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      }
    }
    return dateStr;
  }

  Future<void> _saveIncome() async {
    if (widget.isViewOnly) {
      Navigator.pop(context);
      return;
    }

    if (_sourceNameController.text.trim().isEmpty ||
        _amountController.text.trim().isEmpty) {
      UIUtils.showTopMessage(context, 'Please enter Source Name and Amount', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final formattedStartDate = _formatDateForApi(_startDateController.text.trim());
      final formattedEndDate = _formatDateForApi(_endDateController.text.trim());
      final statusCode = _status == 'Active' ? 'A' : 'D';

      if (widget.item != null) {
        final incomeId = int.tryParse(widget.item!.id) ?? 0;
        await AuthService.updateIncomeMaster(
          familyId: 1,
          incomeId: incomeId,
          incomeName: _sourceNameController.text.trim(),
          incomeType: _incomeType != '-- SELECT --' ? _incomeType : 'I',
          cycleMonths: 1,
          startDate: formattedStartDate,
          amount: int.tryParse(_amountController.text.trim()) ?? 0,
          nextDueDate: formattedEndDate,
          status: statusCode,
        );
        if (mounted) {
          UIUtils.showTopMessage(context, 'Income updated successfully');
          Navigator.pop(context, true);
        }
      } else {
        await AuthService.createIncomeMaster(
          familyId: 1,
          incomeName: _sourceNameController.text.trim(),
          incomeType: _incomeType != '-- SELECT --' ? _incomeType : 'I',
          cycleMonths: 1,
          startDate: formattedStartDate,
          amount: int.tryParse(_amountController.text.trim()) ?? 0,
          nextDueDate: formattedEndDate,
        );
        if (mounted) {
          UIUtils.showTopMessage(context, 'Income saved successfully');
          Navigator.pop(context, true);
        }
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
    final titleText = widget.isViewOnly
        ? 'View Recurring Income'
        : widget.item != null
            ? 'Edit Recurring Income'
            : 'Add Recurring Income';

    final buttonLabelText = widget.isViewOnly
        ? 'Close'
        : widget.item != null
            ? 'Update Recurring Income'
            : '+ Add Recurring Income';

    return Scaffold(
      backgroundColor: const Color(0xFF2D2E4D),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navy Blue Header
            Container(
              color: const Color(0xFF2D2E4D),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      titleText,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Form Card
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ResponsiveCenter(
                  maxWidth: 700,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Income Type
                        _buildLabel('Income Type'),
                        _buildDropdown(
                          value: _incomeType,
                          items: _incomeTypeOptions,
                          onChanged: widget.isViewOnly
                              ? null
                              : (val) {
                                  if (val != null) setState(() => _incomeType = val);
                                },
                        ),
                        const SizedBox(height: 16),

                        // 2. Source Name
                        _buildLabel('Source Name'),
                        _buildTextField(
                          'Enter Source Name',
                          controller: _sourceNameController,
                          readOnly: widget.isViewOnly,
                        ),
                        const SizedBox(height: 16),

                        // 3. Payment Cycle
                        _buildLabel('Payment Cycle'),
                        _buildDropdown(
                          value: _paymentCycle,
                          items: _paymentCycleOptions,
                          onChanged: widget.isViewOnly
                              ? null
                              : (val) {
                                  if (val != null) setState(() => _paymentCycle = val);
                                },
                        ),
                        const SizedBox(height: 16),

                        // 4. Start Date
                        _buildLabel('Start Date'),
                        _buildDateField(
                          'dd / mm / yyyy',
                          controller: _startDateController,
                          onTap: () => _selectDate(context, _startDateController),
                        ),
                        const SizedBox(height: 16),

                        // 5. End Date
                        _buildLabel('End Date'),
                        _buildDateField(
                          'dd / mm / yyyy',
                          controller: _endDateController,
                          onTap: () => _selectDate(context, _endDateController),
                        ),
                        const SizedBox(height: 16),

                        // 6. Amount
                        _buildLabel('Amount'),
                        _buildTextField(
                          'Enter Amount',
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          readOnly: widget.isViewOnly,
                        ),
                        const SizedBox(height: 16),

                        // 7. Payment Mode
                        _buildLabel('Payment Mode'),
                        _buildDropdown(
                          value: _paymentMode,
                          items: _paymentModeOptions,
                          onChanged: widget.isViewOnly
                              ? null
                              : (val) {
                                  if (val != null) setState(() => _paymentMode = val);
                                },
                        ),
                        const SizedBox(height: 16),

                        // 8. Status
                        _buildLabel('Status'),
                        _buildDropdown(
                          value: _status,
                          items: _statusOptions,
                          onChanged: widget.isViewOnly
                              ? null
                              : (val) {
                                  if (val != null) setState(() => _status = val);
                                },
                        ),
                        const SizedBox(height: 16),

                        // 9. Description
                        _buildLabel('Description'),
                        _buildTextField(
                          'Enter Description',
                          controller: _descriptionController,
                          maxLines: 3,
                          readOnly: widget.isViewOnly,
                        ),
                        const SizedBox(height: 16),

                        // 10. Refrence Document 1 (Optional)
                        _buildLabel('Refrence Document 1 (Optional)'),
                        _buildFilePicker(
                          fileName: _doc1Name,
                          onBrowse: widget.isViewOnly
                              ? null
                              : () {
                                  setState(() => _doc1Name = 'Document_1.pdf');
                                },
                        ),
                        const SizedBox(height: 16),

                        // 11. Refrence Document 2 (Optional)
                        _buildLabel('Refrence Document 2 (Optional)'),
                        _buildFilePicker(
                          fileName: _doc2Name,
                          onBrowse: widget.isViewOnly
                              ? null
                              : () {
                                  setState(() => _doc2Name = 'Document_2.pdf');
                                },
                        ),
                        const SizedBox(height: 28),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveIncome,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D2E4D),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    buttonLabelText,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint, {
    required TextEditingController controller,
    bool readOnly = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: Color(0xFF2D3436)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2D2E4D), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDateField(
    String hint, {
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      style: const TextStyle(fontSize: 14, color: Color(0xFF2D3436)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF666666)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2D2E4D), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    final validValue = items.contains(value) ? value : items.first;
    return DropdownButtonFormField<String>(
      initialValue: validValue,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: Color(0xFF2D3436)),
      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF666666)),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2D2E4D), width: 1.5),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14,
                  color: (item.startsWith('--') || item.startsWith('Select'))
                      ? const Color(0xFFA0A0A0)
                      : const Color(0xFF2D3436),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFilePicker({
    String? fileName,
    VoidCallback? onBrowse,
  }) {
    return GestureDetector(
      onTap: onBrowse,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Text(
              fileName != null && fileName.isNotEmpty
                  ? 'File: $fileName'
                  : 'Browse...  No file selected.',
              style: TextStyle(
                fontSize: 14,
                color: fileName != null ? const Color(0xFF2D3436) : const Color(0xFF777777),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

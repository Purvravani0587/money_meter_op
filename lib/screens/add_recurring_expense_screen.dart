import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/auth_service.dart';
import '../utils/ui_utils.dart';
import '../widgets/responsive_center.dart';

class AddRecurringExpenseScreen extends StatefulWidget {
  final FamilyTransactionItem? item;
  final int? expenseId;
  final bool isViewOnly;

  const AddRecurringExpenseScreen({
    super.key,
    this.item,
    this.expenseId,
    this.isViewOnly = false,
  });

  @override
  State<AddRecurringExpenseScreen> createState() => _AddRecurringExpenseScreenState();
}

class _AddRecurringExpenseScreenState extends State<AddRecurringExpenseScreen> {
  String _type = '-- SELECT --';
  final _acNameController = TextEditingController();
  String _paymentCycle = '--SELECT--';
  final _startDateController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _amountController = TextEditingController();
  String _status = 'Active';
  final _beneficiaryController = TextEditingController();
  final _upiIdController = TextEditingController();

  String? _upiQrName;
  String? _doc1Name;
  String? _doc2Name;

  bool _isLoading = false;

  final List<String> _typeOptions = [
    '-- SELECT --',
    'Utility',
    'Loan / EMI',
    'Rent',
    'Insurance',
    'Subscription',
    'Other',
  ];

  final List<String> _paymentCycleOptions = [
    '--SELECT--',
    'Daily',
    'Weekly',
    'Monthly',
    'Quarterly',
    'Yearly',
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

    final id = widget.expenseId ?? int.tryParse(widget.item?.id ?? '');
    if (id != null) {
      _fetchExpenseDetail(id);
    }
  }

  void _populateFromItem(FamilyTransactionItem item) {
    if (item.name.isNotEmpty && item.name != 'Unnamed') {
      _acNameController.text = item.name;
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

    // Expiry / Maturity Date
    if (item.endDate.isNotEmpty) {
      _expiryDateController.text = item.endDate;
    } else if (item.date.isNotEmpty) {
      _expiryDateController.text = item.date;
    }

    // Start Date (Never leave blank)
    if (item.startDate.isNotEmpty) {
      _startDateController.text = item.startDate;
    } else if (_expiryDateController.text.isNotEmpty) {
      _startDateController.text = _expiryDateController.text;
    } else {
      final now = DateTime.now();
      _startDateController.text = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    }

    // Type
    if (item.type.isNotEmpty) {
      final t = item.type.toUpperCase();
      if (t == 'E' || item.type.contains('Utility')) {
        _type = 'Utility';
      } else if (t == 'L' || item.type.contains('Loan')) {
        _type = 'Loan / EMI';
      } else if (t == 'R' || item.type.contains('Rent')) {
        _type = 'Rent';
      } else if (t == 'I' || item.type.contains('Insurance')) {
        _type = 'Insurance';
      } else if (t == 'S' || item.type.contains('Subscription')) {
        _type = 'Subscription';
      } else if (_typeOptions.contains(item.type)) {
        _type = item.type;
      }
    }
    if (_type == '-- SELECT --') {
      _type = 'Utility';
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
    if (_paymentCycle == '--SELECT--' || _paymentCycle == 'Select Payment Cycle') {
      _paymentCycle = 'Monthly';
    }

    // Beneficiary Details
    if (item.description.isNotEmpty) {
      _beneficiaryController.text = item.description;
    }
  }

  Future<void> _fetchExpenseDetail(int expenseId) async {
    try {
      final detail = await AuthService.getOneExpense(expenseId: expenseId);
      if (detail != null && mounted) {
        setState(() {
          _populateFromItem(detail);
        });
      }
    } catch (_) {
      // Keep pre-populated state if detail fetch fails
    }
  }

  @override
  void dispose() {
    _acNameController.dispose();
    _startDateController.dispose();
    _expiryDateController.dispose();
    _amountController.dispose();
    _beneficiaryController.dispose();
    _upiIdController.dispose();
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

  Future<void> _saveExpense() async {
    if (widget.isViewOnly) {
      Navigator.pop(context);
      return;
    }

    if (_acNameController.text.trim().isEmpty ||
        _amountController.text.trim().isEmpty) {
      UIUtils.showTopMessage(context, 'Please enter Name and Amount', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final familyId = await AuthService.getFamilyId();
      final formattedStartDate = _formatDateForApi(_startDateController.text.trim());
      final formattedExpiryDate = _formatDateForApi(_expiryDateController.text.trim());
      final statusCode = _status == 'Active' ? 'A' : 'D';

      final targetExpenseId = widget.expenseId ?? (widget.item != null ? int.tryParse(widget.item!.id) : null);

      if (targetExpenseId != null) {
        await AuthService.editExpenseMaster(
          familyId: familyId,
          expenseId: targetExpenseId,
          expenseName: _acNameController.text.trim(),
          expenseType: _type != '-- SELECT --' ? _type : 'E',
          cycleMonths: 1,
          startDate: formattedStartDate,
          amount: int.tryParse(_amountController.text.trim()) ?? 0,
          nextDueDate: formattedExpiryDate,
          status: statusCode,
        );
        if (mounted) {
          UIUtils.showTopMessage(context, 'Expense updated successfully');
          Navigator.pop(context, true);
        }
      } else {
        await AuthService.addExpense(
          familyId: familyId,
          expenseName: _acNameController.text.trim(),
          expenseType: _type != '-- SELECT --' ? _type : 'E',
          cycleMonths: 1,
          startDate: formattedStartDate,
          amount: int.tryParse(_amountController.text.trim()) ?? 0,
          nextDueDate: formattedExpiryDate,
        );
        if (mounted) {
          UIUtils.showTopMessage(context, 'Expense saved successfully');
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
        ? 'View Recurring Fix Expenses'
        : widget.item != null
            ? 'Edit Recurring Fix Expenses'
            : 'Recurring Fix Expenses';

    final buttonLabelText = widget.isViewOnly
        ? 'Close'
        : widget.item != null
            ? 'Update Recurring Fix Expenses'
            : '+ Add Recurring Fix Expenses';

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
                        // 1. Type
                        _buildLabel('Type'),
                        _buildDropdown(
                          value: _type,
                          items: _typeOptions,
                          onChanged: widget.isViewOnly
                              ? null
                              : (val) {
                                  if (val != null) setState(() => _type = val);
                                },
                        ),
                        const SizedBox(height: 16),

                        // 2. Name
                        _buildLabel('Name'),
                        _buildTextField(
                          'Enter Name',
                          controller: _acNameController,
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

                        // 5. Expiry / Maturity Date
                        _buildLabel('Expiry / Maturity Date'),
                        _buildDateField(
                          'dd / mm / yyyy',
                          controller: _expiryDateController,
                          onTap: () => _selectDate(context, _expiryDateController),
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

                        // 7. Status
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

                        // 8. Beneficiary Details
                        _buildLabel('Beneficiary Details'),
                        _buildTextField(
                          'Enter Description',
                          controller: _beneficiaryController,
                          maxLines: 3,
                          readOnly: widget.isViewOnly,
                        ),
                        const SizedBox(height: 16),

                        // 9. UPI ID
                        _buildLabel('UPI ID'),
                        _buildTextField(
                          'Enter Amount',
                          controller: _upiIdController,
                          readOnly: widget.isViewOnly,
                        ),
                        const SizedBox(height: 16),

                        // 10. UPI QR (Optional)
                        _buildLabel('UPI QR (Optional)'),
                        _buildFilePicker(
                          fileName: _upiQrName,
                          onBrowse: widget.isViewOnly
                              ? null
                              : () {
                                  setState(() => _upiQrName = 'UPI_QR.png');
                                },
                        ),
                        const SizedBox(height: 16),

                        // 11. Refrence Document 1 (Optional)
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

                        // 12. Refrence Document 2 (Optional)
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
                            onPressed: _isLoading ? null : _saveExpense,
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

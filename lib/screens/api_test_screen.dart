import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  String _result = 'Tap any endpoint to test it.';
  bool _isLoading = false;

  Future<void> _runCall(Future<dynamic> Function() action, String label) async {
    setState(() {
      _isLoading = true;
      _result = 'Calling $label...';
    });

    try {
      final response = await action();
      setState(() {
        _result = 'Success for $label:\n${response.toString()}';
      });
    } catch (e) {
      setState(() {
        _result = 'Error for $label:\n${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Test Screen')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Base URL: ${AuthService.baseUrl}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildButton(
                      'Member Login',
                      () => AuthService.login(
                        username: '9227219560',
                        password: 'Deep@123',
                      ),
                    ),
                    _buildButton(
                      'Merchant Login',
                      () => AuthService.merchantLogin(
                        username: '9227219560',
                        password: 'Deep@123',
                      ),
                    ),
                    _buildButton(
                      'Member Register',
                      () => AuthService.register(
                        fullName: 'Deep',
                        dob: '2002-01-01',
                        gender: 'M',
                        email: 'deep.wipra13@gmail.com',
                        mobile: '9227219560',
                        password: 'Deep@123',
                        confirmPassword: 'Deep@123',
                        address: 'Test',
                        landmark: 'Law Gardan',
                        latitude: '1',
                        longitude: '1',
                      ),
                    ),
                    _buildButton(
                      'Merchant List',
                      () => AuthService.getMerchantList(merchantId: 3),
                    ),
                    _buildButton(
                      'Member Master',
                      () => AuthService.getMemberMasterList(),
                    ),
                    _buildButton(
                      'Merchant Business Staff',
                      () => AuthService.getMerchantBusinessStaff(),
                    ),
                    _buildButton(
                      'Merchant Business Products',
                      () => AuthService.getMerchantBusinessProducts(),
                    ),
                    _buildButton(
                      'MB Bill Hdr',
                      () => AuthService.getMBBillHdrList(),
                    ),
                    _buildButton(
                      'MB Bill Bdy',
                      () => AuthService.getMBBillBdyList(),
                    ),
                    _buildButton(
                      'MB Bills',
                      () => AuthService.getMBBillsList(),
                    ),
                    _buildButton(
                      'Delivery Hdr',
                      () => AuthService.getDeliveryHdrList(),
                    ),
                    _buildButton(
                      'Delivery Bdy',
                      () => AuthService.getDeliveryBdyList(),
                    ),
                    _buildButton(
                      'Delivery Details',
                      () => AuthService.getDeliveryDetails(),
                    ),
                    _buildButton(
                      'MB Collection',
                      () => AuthService.getMBCollectionList(),
                    ),
                    _buildButton(
                      'Collection Marking',
                      () => AuthService.getCollectionMarkingList(),
                    ),
                    _buildButton(
                      'Merchant Businesses',
                      () => AuthService.getMerchantBusinessesList(),
                    ),
                    _buildButton(
                      'Merchant Business Client',
                      () => AuthService.getMerchantBusinessClientList(),
                    ),
                    _buildButton(
                      'Common Master',
                      () => AuthService.getCommonMasterList(
                        commonType: 'spendingType',
                      ),
                    ),
                    _buildButton(
                      'Family Income History',
                      () => AuthService.getFamilyIncomeHistory(familyId: 1),
                    ),
                    _buildButton(
                      'Family Income List',
                      () => AuthService.getFamilyIncomeList(familyId: 1),
                    ),
                    _buildButton(
                      'Family Income View',
                      () => AuthService.getFamilyIncomeView(
                        familyId: 1,
                        startRow: 0,
                        incomeId: 1,
                      ),
                    ),
                    _buildButton(
                      'Family Unpaid Income',
                      () => AuthService.getFamilyUnpaidIncome(familyId: 1),
                    ),
                    _buildButton(
                      'Family Paid Income',
                      () => AuthService.getFamilyPaidIncome(familyId: 1),
                    ),
                    _buildButton(
                      'Family Expense History',
                      () => AuthService.getFamilyExpenseHistory(familyId: 1),
                    ),
                    _buildButton(
                      '1. Add Expense (POST member-expense)',
                      () => AuthService.addExpense(
                        familyId: 1,
                        expenseName: 'Test Electricity Bill',
                        expenseType: 'Utility',
                        cycleMonths: 1,
                        startDate: '2026-08-01',
                        amount: 1500,
                        nextDueDate: '2026-09-01',
                      ),
                    ),
                    _buildButton(
                      '2. Get One Expense (GET member-expense/2)',
                      () => AuthService.getExpenseMasterDetailRaw(expenseId: 2),
                    ),
                    _buildButton(
                      '3. Edit Expense Master (PATCH member-expense/2)',
                      () => AuthService.editExpenseMaster(
                        familyId: 1,
                        expenseId: 2,
                        expenseName: 'Test Electricity Bill Updated',
                        expenseType: 'Utility',
                        cycleMonths: 1,
                        startDate: '2026-08-01',
                        amount: 1800,
                        nextDueDate: '2026-09-01',
                        status: 'A',
                      ),
                    ),
                    _buildButton(
                      '4. View Expense Master Grid (GET member-expense)',
                      () => AuthService.getExpenseMasterGridRaw(
                        familyId: 1,
                        startRow: 0,
                      ),
                    ),
                    _buildButton(
                      'Family Expense List',
                      () => AuthService.getFamilyExpenseList(familyId: 1),
                    ),
                    _buildButton(
                      'Family Expense View',
                      () => AuthService.getFamilyExpenseView(
                        familyId: 1,
                        startRow: 0,
                        expenseId: 1,
                      ),
                    ),
                    _buildButton(
                      'Family Unpaid Expense',
                      () => AuthService.getFamilyUnpaidExpense(familyId: 1),
                    ),
                    _buildButton(
                      'Family Paid Expense',
                      () => AuthService.getFamilyPaidExpense(familyId: 1),
                    ),
                    _buildButton(
                      'Recurring Expenses Paid',
                      () => AuthService.getRecurringExpensesPaid(
                        familyId: 1,
                        startRow: 0,
                        fromDate: '2026-07-01',
                        toDate: '2026-07-27',
                      ),
                    ),
                    _buildButton(
                      'Home Screen Data',
                      () => AuthService.getHomeScreenData(familyId: 1),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading) const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_result),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String label, Future<dynamic> Function() action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _runCall(action, label),
          child: Text(label),
        ),
      ),
    );
  }
}

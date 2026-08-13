import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/auth_service.dart';
import '../widgets/responsive_center.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  List<FamilyTransactionItem> _allExpenses = [];
  bool _isLoading = false;
  String _totalAmount = '₹0';
  String _userName = '';
  int _familyId = 0;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadExpenses();
  }

  Future<void> _loadUserInfo() async {
    final name = await AuthService.getUserName();
    final familyId = await AuthService.getFamilyId();

    if (mounted) {
      setState(() {
        _userName = (name == null || name.isEmpty) ? 'User' : name;
        _familyId = familyId;
      });
    }
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final familyId = await AuthService.getFamilyId();

      List<FamilyTransactionItem> expenseItems =
          await AuthService.getExpenseMasterGrid(
              familyId: familyId, startRow: 0);

      List<FamilyTransactionItem> unpaidExpList = [];
      try {
        final res =
            await AuthService.getFamilyUnpaidExpense(familyId: familyId);
        unpaidExpList = FamilyTransactionItem.fromResponse(res);
      } catch (_) {}

      List<FamilyTransactionItem> paidExpList = [];
      try {
        final res = await AuthService.getFamilyPaidExpense(familyId: familyId);
        paidExpList = FamilyTransactionItem.fromResponse(res);
      } catch (_) {}

      // Combine all expense lists
      List<FamilyTransactionItem> combinedExpList = [];
      combinedExpList.addAll(expenseItems);
      for (final item in unpaidExpList) {
        if (!combinedExpList
            .any((e) => e.name == item.name && e.amount == item.amount)) {
          combinedExpList.add(item);
        }
      }
      for (final item in paidExpList) {
        if (!combinedExpList
            .any((e) => e.name == item.name && e.amount == item.amount)) {
          combinedExpList.add(item);
        }
      }

      final summary = await AuthService.getHomeScreenData(familyId: familyId);

      if (!mounted) return;

      setState(() {
        _allExpenses = combinedExpList;
        _totalAmount = summary.totalExpenseAmount;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading expenses: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expense List',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF232038),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _userName.isNotEmpty
                  ? '$_userName\'s Family (ID: $_familyId)'
                  : 'Family ID: $_familyId',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF85809A),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF232038)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ResponsiveCenter(
        maxWidth: 800,
        child: RefreshIndicator(
          onRefresh: _loadExpenses,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE55B68)),
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total Expense Amount Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDEEEF),
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: const Color(0xFFF9D5D8)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.receipt_long_rounded,
                                    color: Color(0xFFE55B68), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Total Expenses (${_allExpenses.length} items)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF232038),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _totalAmount,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                color: Color(0xFFE55B68),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Expense Items List
                      if (_allExpenses.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'No expense records found',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x06000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _allExpenses.length,
                            separatorBuilder: (context, index) => const Divider(
                                height: 1, color: Color(0xFFF2EEF7)),
                            itemBuilder: (context, index) {
                              final item = _allExpenses[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDEEEF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                      Icons.arrow_downward_rounded,
                                      color: Color(0xFFE55B68),
                                      size: 24),
                                ),
                                title: Text(
                                  item.name.isNotEmpty
                                      ? item.name
                                      : 'Expense Transaction',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF232038),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      item.date.isNotEmpty
                                          ? item.date
                                          : 'No date',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF85809A),
                                      ),
                                    ),
                                    if (item.status.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: item.status
                                                    .toLowerCase()
                                                    .contains('paid')
                                                ? const Color(0xFFE8F6F0)
                                                : const Color(0xFFFDEEEF),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item.status,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: item.status
                                                      .toLowerCase()
                                                      .contains('paid')
                                                  ? const Color(0xFF2E9A68)
                                                  : const Color(0xFFE55B68),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Text(
                                  item.amount,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFFE55B68),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

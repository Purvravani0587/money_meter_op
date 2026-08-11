import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../models/api_models.dart';
import '../services/auth_service.dart';
import '../widgets/responsive_center.dart';
import 'api_test_screen.dart';
import 'mtd_income_screen.dart';
import 'recurring_expenses_screen.dart';
import 'recurring_income_screen.dart';
import 'unbilled_transactions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  String _mtdExpense = '₹0';
  String _mtdIncome = '₹0';
  String _projExpenses = '₹0';
  String _projIncome = '₹0';
  bool _hasLoadedHomeData = false;
  bool _isLoadingHomeData = false;
  bool _isLoadingTransactions = false;
  List<Map<String, dynamic>> _upcomingIncome = [];
  List<Map<String, dynamic>> _upcomingExpense = [];
  List<Map<String, dynamic>> _unbilledItems = [];

  bool get _isIOS => !kIsWeb && Platform.isIOS;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadHomeScreenData();
  }

  Future<void> _loadUserProfile() async {
    final name = await AuthService.getUserName();
    if (mounted) {
      final newName = (name == null || name.isEmpty) ? 'User' : name;
      if (_userName != newName) {
        setState(() {
          _userName = newName;
        });
      }
    }
  }

  Future<void> _loadHomeScreenData({bool showLoading = true}) async {
    if (showLoading && !_hasLoadedHomeData) {
      setState(() {
        _isLoadingHomeData = true;
        _isLoadingTransactions = true;
      });
    }

    try {
      final familyId = await AuthService.getFamilyId();
      final summary = await AuthService.getHomeScreenData(familyId: familyId);
      List<FamilyTransactionItem> incomeItems = summary.upcomingIncome;
      if (incomeItems.isEmpty) {
        incomeItems =
            await AuthService.getIncomeTransactions(familyId: familyId);
        if (incomeItems.isEmpty) {
          incomeItems = await AuthService.getAllIncome(familyId: familyId);
        }
      }

      List<FamilyTransactionItem> expenseItems = summary.upcomingExpense;
      if (expenseItems.isEmpty) {
        expenseItems =
            await AuthService.getExpenseTransactions(familyId: familyId);
        if (expenseItems.isEmpty) {
          expenseItems = await AuthService.getAllExpense(familyId: familyId);
        }
      }

      List<FamilyTransactionItem> unbilledItems = summary.unbilledItems;
      if (unbilledItems.isEmpty) {
        unbilledItems =
            await AuthService.getUnbilledTransactions(familyId: familyId);
      }
      if (!mounted) return;

      num parseAmount(String str) {
        final cleaned = str.replaceAll(RegExp(r'[^0-9.-]'), '');
        return num.tryParse(cleaned) ?? 0;
      }

      String formatVal(num val) {
        return '₹${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 2)}';
      }

      String mtdExp = summary.mtdExpense;
      String mtdInc = summary.mtdIncome;
      String projExp = summary.projectedExpenses;
      String projInc = summary.projectedIncome;

      if ((mtdInc == '₹0' || mtdInc == '₹0.00') && incomeItems.isNotEmpty) {
        final sum = incomeItems.fold<num>(
          0,
          (prev, item) => prev + parseAmount(item.amount),
        );
        if (sum > 0) mtdInc = formatVal(sum);
      }

      if ((mtdExp == '₹0' || mtdExp == '₹0.00') && expenseItems.isNotEmpty) {
        final sum = expenseItems.fold<num>(
          0,
          (prev, item) => prev + parseAmount(item.amount),
        );
        if (sum > 0) mtdExp = formatVal(sum);
      }

      if (projInc == '₹0' || projInc == '₹0.00') {
        projInc = mtdInc;
      }

      if (projExp == '₹0' || projExp == '₹0.00') {
        projExp = mtdExp;
      }

      setState(() {
        _mtdExpense = mtdExp;
        _mtdIncome = mtdInc;
        _projExpenses = projExp;
        _projIncome = projInc;
        _upcomingIncome = incomeItems
            .map((item) => {
                  'name': item.name,
                  'amount': item.amount,
                  'date': item.date,
                  'status': item.status,
                })
            .toList();
        _upcomingExpense = expenseItems
            .map((item) => {
                  'name': item.name,
                  'amount': item.amount,
                  'date': item.date,
                  'status': item.status,
                })
            .toList();
        _unbilledItems = unbilledItems
            .map((item) => {
                  'name': item.name,
                  'amount': item.amount,
                })
            .toList();
        _hasLoadedHomeData = true;
        _isLoadingHomeData = false;
        _isLoadingTransactions = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasLoadedHomeData = true;
          _isLoadingHomeData = false;
          _isLoadingTransactions = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isIOS ? const Color(0xFFF2F2F7) : const Color(0xFFFAFAFC),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 800,
          child: RefreshIndicator(
            onRefresh: () => _loadHomeScreenData(showLoading: false),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFDCD6F7),
                          child: Text(
                            _userName.isNotEmpty
                                ? _userName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: Colors.brown.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Hello, ${_userName.isNotEmpty ? _userName : 'User'}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2D2E4D),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFFD700),
                                          Color(0xFFFFA500)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'PREMIUM',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Text(
                                'Welcome back 👋',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ApiTestScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.api_outlined,
                                  color: Colors.grey),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Stack(
                                children: [
                                  Icon(Icons.notifications_outlined,
                                      color: Colors.grey),
                                  Positioned(
                                    right: 2,
                                    top: 2,
                                    child: CircleAvatar(
                                      radius: 4,
                                      backgroundColor: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Section Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'Projected Recurring',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2E4D),
                      ),
                    ),
                  ),
                  if (_isLoadingHomeData)
                    const Padding(
                      padding: EdgeInsets.only(left: 24.0, top: 8.0),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Grid Stats
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.45,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RecurringExpensesScreen(),
                              ),
                            );
                          },
                          child: _buildStatCard(
                            title: 'MTD EXPENSE',
                            value: _mtdExpense,
                            badge: '↓ 4.2% vs last mo.',
                            badgeColor: Colors.red,
                            icon: Icons.trending_down_rounded,
                            iconBgColor: const Color(0xFFFFEBEE),
                            iconColor: const Color(0xFFE53935),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MtdIncomeScreen(),
                              ),
                            );
                          },
                          child: _buildStatCard(
                            title: 'MTD INCOME',
                            value: _mtdIncome,
                            badge: '↑ 8.1% vs last mo.',
                            badgeColor: Colors.green,
                            icon: Icons.trending_up_rounded,
                            iconBgColor: const Color(0xFFE8F5E9),
                            iconColor: const Color(0xFF43A047),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RecurringExpensesScreen(),
                              ),
                            );
                          },
                          child: _buildStatCard(
                            title: 'PROJ. EXPENSES',
                            value: _projExpenses,
                            badge: '',
                            badgeColor: Colors.transparent,
                            icon: Icons.receipt_long_outlined,
                            iconBgColor: const Color(0xFFFFF3E0),
                            iconColor: const Color(0xFFFB8C00),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RecurringIncomeScreen(),
                              ),
                            );
                          },
                          child: _buildStatCard(
                            title: 'PROJ. INCOME',
                            value: _projIncome,
                            badge: '',
                            badgeColor: Colors.transparent,
                            icon: Icons.account_balance_wallet_outlined,
                            iconBgColor: const Color(0xFFE0F7FA),
                            iconColor: const Color(0xFF00ACC1),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Upcoming & Recurring',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D2E4D),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAEFF5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_upcomingExpense.length + _upcomingIncome.length + (_unbilledItems.isNotEmpty ? 1 : 0)} items',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5C6B73),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Transaction List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLoadingTransactions)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else ...[
                          if (_upcomingExpense.isEmpty &&
                              _upcomingIncome.isEmpty &&
                              _unbilledItems.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: const Color(0xFFEEEEEE)),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.inbox_outlined,
                                      size: 40, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    'No recurring items found',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ..._upcomingExpense.map((item) => _buildListItem(
                                Icons.receipt_long_outlined,
                                item['name'] ?? 'Expense',
                                item['date'] ?? 'Next 7 days',
                                item['amount'] ?? '₹0',
                                0,
                                const Color(0xFFFFEBEE),
                              )),
                          ..._upcomingIncome.map((item) => _buildListItem(
                                Icons.work_outline,
                                item['name'] ?? 'Income',
                                item['date'] ?? 'Next 7 days',
                                item['amount'] ?? '₹0',
                                0,
                                const Color(0xFFE8F5E9),
                              )),
                          if (_unbilledItems.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const UnbilledTransactionsScreen(),
                                  ),
                                );
                              },
                              child: _buildListItem(
                                Icons.receipt_outlined,
                                'Unbilled Items',
                                'Awaiting invoice',
                                _unbilledItems
                                    .map((item) => item['amount'] ?? '₹0')
                                    .join(', '),
                                _unbilledItems.length,
                                const Color(0xFFE3F2FD),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D2E4D).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              if (badge.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.4,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2E4D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(
    IconData icon,
    String title,
    String subtitle,
    String amount,
    int badgeCount,
    Color bgIconColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF2F2F5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgIconColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF2D2E4D), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF2D2E4D),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF2D2E4D),
                  ),
                ),
                if (badgeCount > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$badgeCount items',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

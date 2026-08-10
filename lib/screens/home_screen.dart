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
      backgroundColor: _isIOS ? const Color(0xFFF2F2F7) : Colors.white,
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 800,
          child: RefreshIndicator(
            onRefresh: () => _loadHomeScreenData(showLoading: false),
            child: Column(
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

                const Center(
                  child: Text(
                    'Projected Recurring',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2E4D),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_isLoadingHomeData)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
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
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.4,
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
                          'MTD EXPENSE',
                          _mtdExpense,
                          '↓ 4.2% vs last mo.',
                          Colors.red,
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
                          'MTD INCOME',
                          _mtdIncome,
                          '↑ 8.1% vs last mo.',
                          Colors.green,
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
                          'PROJ. EXPENSES',
                          _projExpenses,
                          '',
                          Colors.transparent,
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
                          'PROJ. INCOME',
                          _projIncome,
                          '',
                          Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // List
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (_isLoadingTransactions)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        else ...[
                          if (_upcomingExpense.isEmpty &&
                              _upcomingIncome.isEmpty &&
                              _unbilledItems.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'No recurring items found',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 14),
                                ),
                              ),
                            ),
                          ..._upcomingExpense.map((item) => _buildListItem(
                                Icons.receipt_long_outlined,
                                item['name'] ?? 'Expense',
                                item['date'] ?? 'Next 7 days',
                                item['amount'] ?? '₹0',
                                0,
                                Colors.red.shade50,
                              )),
                          ..._upcomingIncome.map((item) => _buildListItem(
                                Icons.work_outline,
                                item['name'] ?? 'Income',
                                item['date'] ?? 'Next 7 days',
                                item['amount'] ?? '₹0',
                                0,
                                Colors.green.shade50,
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
                                Icons.receipt_long_outlined,
                                'Unbilled',
                                'Awaiting invoice',
                                _unbilledItems
                                    .map((item) => item['amount'] ?? '₹0')
                                    .join(', '),
                                _unbilledItems.length,
                                Colors.blue.shade50,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String badge,
    Color badgeColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
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
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
              child: Icon(icon, color: const Color(0xFF2D2E4D)),
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
                if (badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$badgeCount items',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

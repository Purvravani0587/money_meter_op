import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../services/auth_service.dart';
import '../widgets/responsive_center.dart';
import 'expense_list_screen.dart';
import 'mtd_income_screen.dart';
import 'recurring_expenses_screen.dart';
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

  String _recurringExpense = '₹0';
  String _recurringIncome = '₹0';
  String _totalRecurringAmount = '₹0';

  String _upcomingExpAmount = '₹0';
  int _upcomingExpCount = 0;

  String _upcomingIncAmount = '₹0';
  int _upcomingIncCount = 0;

  String _unbilledAmount = '₹0';
  int _unbilledCount = 0;

  String _unpaidRecAmount = '₹0';
  int _unpaidRecCount = 0;

  List<FamilyTransactionItem> _recentExpensesList = [];
  String _totalExpenseListAmount = '₹0';

  bool _hasLoadedHomeData = false;

  num _parseAmount(String value) {
    return num.tryParse(value.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0;
  }

  String _formatAmount(num value) {
    return '₹${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)}';
  }

  DateTime? _parseTransactionDate(String value) {
    if (value.trim().isEmpty) return null;
    return DateTime.tryParse(value) ??
        (() {
          final parts = value.trim().split(RegExp(r'[/.-]'));
          if (parts.length != 3) return null;
          final isYearFirst = parts[0].length == 4;
          final year = int.tryParse(isYearFirst ? parts[0] : parts[2]);
          final month = int.tryParse(parts[1]);
          final day = int.tryParse(isYearFirst ? parts[2] : parts[0]);
          if (day == null || month == null || year == null) return null;
          return DateTime(year, month, day);
        })();
  }

  String _currentMonthPaidTotal(List<FamilyTransactionItem> items) {
    final now = DateTime.now();
    final seenIds = <String>{};
    final total = items.where((item) {
      // A refresh can contain duplicate rows for one transaction. Use its
      // stable API id so it contributes to the monthly total only once.
      if (item.id.isNotEmpty && !seenIds.add(item.id)) return false;
      final date = _parseTransactionDate(item.date);
      return date == null || (date.year == now.year && date.month == now.month);
    }).fold<num>(0, (sum, item) => sum + _parseAmount(item.amount));
    return _formatAmount(total);
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadHomeScreenData();
    AuthService.dashboardDataVersion.addListener(_refreshFromDataChange);
  }

  @override
  void dispose() {
    AuthService.dashboardDataVersion.removeListener(_refreshFromDataChange);
    super.dispose();
  }

  void _refreshFromDataChange() {
    _loadHomeScreenData(showLoading: false);
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
    try {
      final familyId = await AuthService.getFamilyId();
      final summary = await AuthService.getHomeScreenData(familyId: familyId);
      final recurringExpense = await AuthService.getRecurringExpense();
      final recurringIncome = await AuthService.getRecurringIncome();
      final projectedExpense = await AuthService.getProjectedExpense();
      final projectedIncome = await AuthService.getProjectedIncome();
      List<FamilyTransactionItem> paidExpenseItems = [];
      List<FamilyTransactionItem> paidIncomeItems = [];
      try {
        final paidExpenseResponse =
            await AuthService.getFamilyPaidExpense(familyId: familyId);
        paidExpenseItems =
            FamilyTransactionItem.fromResponse(paidExpenseResponse);
      } catch (_) {}
      try {
        final paidIncomeResponse =
            await AuthService.getFamilyPaidIncome(familyId: familyId);
        paidIncomeItems =
            FamilyTransactionItem.fromResponse(paidIncomeResponse);
      } catch (_) {}
      final paidExpenseAmount = _currentMonthPaidTotal(paidExpenseItems);
      final paidIncomeAmount = _currentMonthPaidTotal(paidIncomeItems);

      if (!mounted) return;

      setState(() {
        // Display API values directly
        // MTD expense includes only expense amounts that have been paid.
        _mtdExpense =
            paidExpenseItems.isEmpty ? summary.mtdExpense : paidExpenseAmount;
        // MTD income includes only income amounts that have been received.
        _mtdIncome =
            paidIncomeItems.isEmpty ? summary.mtdIncome : paidIncomeAmount;
        // Calculate real-time projected amounts by adding API summary and recurring
        final apiProjExp = _parseAmount(summary.projectedExpenses);
        final recExp = _parseAmount(recurringExpense);
        _projExpenses = _formatAmount(apiProjExp + recExp);

        final apiProjInc = _parseAmount(summary.projectedIncome);
        final recInc = _parseAmount(recurringIncome);
        _projIncome = _formatAmount(apiProjInc + recInc);

        _recurringExpense = recurringExpense;
        _recurringIncome = recurringIncome;
        _totalRecurringAmount = summary.totalRecurringAmount;

        _upcomingExpAmount = summary.upcomingExpenseAmount;
        _upcomingExpCount = summary.upcomingExpense.length;

        _upcomingIncAmount = summary.upcomingIncomeAmount;
        _upcomingIncCount = summary.upcomingIncome.length;

        _unbilledAmount = summary.unbilledAmount;
        _unbilledCount = summary.unbilledItems.length;

        _unpaidRecAmount = recurringExpense;
        _unpaidRecCount = 0;

        _recentExpensesList = summary.expenses;
        _totalExpenseListAmount = summary.totalExpenseAmount;

        _hasLoadedHomeData = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasLoadedHomeData = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FC),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 800,
          child: RefreshIndicator(
            onRefresh: () => _loadHomeScreenData(showLoading: false),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Soft Purple Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 20.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EDFA),
                      borderRadius: BorderRadius.circular(28.0),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFFE2C481),
                          child: Text(
                            _userName.isNotEmpty
                                ? _userName[0].toUpperCase()
                                : 'R',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${_userName.isNotEmpty ? _userName : 'Rahul'}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF232038),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Welcome back 👋',
                                style: TextStyle(
                                  color: Color(0xFF85809A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Grid 2x2 Stats
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.35,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildTopStatCard(
                        title: 'MTD EXPENSE',
                        value: _mtdExpense,
                        valueColor: const Color(0xFF262638),
                      ),
                      _buildTopStatCard(
                        title: 'MTD INCOME',
                        value: _mtdIncome,
                        valueColor: const Color(0xFF262638),
                      ),
                      _buildTopStatCard(
                        title: 'PROJ. EXPENSES',
                        value: _projExpenses,
                        valueColor: const Color(0xFF7A6830),
                      ),
                      _buildTopStatCard(
                        title: 'PROJ. INCOME',
                        value: _projIncome,
                        valueColor: const Color(0xFF7A6830),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Bottom List Items Container
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
                    child: Column(
                      children: [
                        _buildListItem(
                          icon: Icons.unarchive_rounded,
                          iconBgColor: const Color(0xFFFDEEEF),
                          iconColor: const Color(0xFFE55B68),
                          title: 'Upcoming Expenses',
                          subtitle: 'Next 7 days',
                          amount: _upcomingExpAmount,
                          badgeCount: _upcomingExpCount,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RecurringExpensesScreen(),
                              ),
                            );
                            _loadHomeScreenData(showLoading: false);
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFFF2EEF7)),
                        _buildListItem(
                          icon: Icons.archive_rounded,
                          iconBgColor: const Color(0xFFE8F6F0),
                          iconColor: const Color(0xFF2E9A68),
                          title: 'Upcoming Income',
                          subtitle: 'Next 7 days',
                          amount: _upcomingIncAmount,
                          badgeCount: _upcomingIncCount,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MtdIncomeScreen(),
                              ),
                            );
                            _loadHomeScreenData(showLoading: false);
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFFF2EEF7)),
                        _buildListItem(
                          icon: Icons.receipt_long_rounded,
                          iconBgColor: const Color(0xFFFBF4E6),
                          iconColor: const Color(0xFFD4A038),
                          title: 'Unbilled',
                          subtitle: 'Awaiting invoice',
                          amount: _unbilledAmount,
                          badgeCount: _unbilledCount,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const UnbilledTransactionsScreen(),
                              ),
                            );
                            _loadHomeScreenData(showLoading: false);
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFFF2EEF7)),
                        _buildListItem(
                          icon: Icons.hourglass_bottom_rounded,
                          iconBgColor: const Color(0xFFFDECEF),
                          iconColor: const Color(0xFFE55B68),
                          title: 'Unpaid Recurring',
                          subtitle: 'Action needed',
                          amount: _unpaidRecAmount,
                          badgeCount: _unpaidRecCount,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RecurringExpensesScreen(),
                              ),
                            );
                            _loadHomeScreenData(showLoading: false);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recurring Amounts Section
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
                    child: Column(
                      children: [
                        // Recurring Expense Row
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDEEEF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.trending_down_rounded,
                                color: Color(0xFFE55B68), size: 20),
                          ),
                          title: const Text(
                            'Recurring Expenses',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF232038),
                            ),
                          ),
                          trailing: Text(
                            _recurringExpense,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFFE55B68),
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFF2EEF7)),
                        // Recurring Income Row
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F6F0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.trending_up_rounded,
                                color: Color(0xFF2E9A68), size: 20),
                          ),
                          title: const Text(
                            'Recurring Income',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF232038),
                            ),
                          ),
                          trailing: Text(
                            _recurringIncome,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF2E9A68),
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFF2EEF7)),
                        // Total Recurring Row
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBF4E6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.calculate_rounded,
                                color: Color(0xFFD4A038), size: 20),
                          ),
                          title: const Text(
                            'Total Recurring',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF232038),
                            ),
                          ),
                          trailing: Text(
                            _totalRecurringAmount,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFFD4A038),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Expense List Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Expense List',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF232038),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ExpenseListScreen(),
                            ),
                          );
                          _loadHomeScreenData(showLoading: false);
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text(
                          'See All',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Total Expense Amount Banner
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ExpenseListScreen(),
                        ),
                      );
                      _loadHomeScreenData(showLoading: false);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 14.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDEEEF),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: const Color(0xFFF9D5D8)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.receipt_long_rounded,
                                  color: Color(0xFFE55B68), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Total Expense Amount',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF232038),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _totalExpenseListAmount,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Color(0xFFE55B68),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Expense Items List
                  if (_recentExpensesList.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'No expense records found',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
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
                        itemCount: _recentExpensesList.length > 5
                            ? 5
                            : _recentExpensesList.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: Color(0xFFF2EEF7)),
                        itemBuilder: (context, index) {
                          final item = _recentExpensesList[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDEEEF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.arrow_downward_rounded,
                                  color: Color(0xFFE55B68), size: 20),
                            ),
                            title: Text(
                              item.name.isNotEmpty
                                  ? item.name
                                  : 'Expense Transaction',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF232038),
                              ),
                            ),
                            subtitle: Text(
                              item.date.isNotEmpty
                                  ? item.date
                                  : (item.status.isNotEmpty
                                      ? item.status
                                      : 'Expense'),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            trailing: Text(
                              item.amount,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFFE55B68),
                              ),
                            ),
                          );
                        },
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

  Widget _buildTopStatCard({
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF868297),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String amount,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(14.0),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF232038),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8D88A2),
                      fontWeight: FontWeight.w500,
                    ),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF232038),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF332D56),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
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

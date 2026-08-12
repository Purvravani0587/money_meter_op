import 'package:flutter/material.dart';

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

  String _upcomingExpAmount = '₹0';
  int _upcomingExpCount = 0;

  String _upcomingIncAmount = '₹0';
  int _upcomingIncCount = 0;

  String _unbilledAmount = '₹0';
  int _unbilledCount = 0;

  String _unpaidRecAmount = '₹0';
  int _unpaidRecCount = 0;

  bool _hasLoadedHomeData = false;
  bool _isLoadingHomeData = false;

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
      });
    }

    try {
      final familyId = await AuthService.getFamilyId();
      final summary = await AuthService.getHomeScreenData(familyId: familyId);

      List<FamilyTransactionItem> incomeItems = await AuthService.getAllIncome(familyId: familyId);
      if (incomeItems.isEmpty) {
        incomeItems = summary.upcomingIncome;
        if (incomeItems.isEmpty) {
          incomeItems = await AuthService.getIncomeTransactions(familyId: familyId);
        }
      }

      List<FamilyTransactionItem> expenseItems = await AuthService.getExpenseMasterGrid(familyId: familyId, startRow: 0);
      if (expenseItems.isEmpty) {
        expenseItems = summary.upcomingExpense;
        if (expenseItems.isEmpty) {
          expenseItems = await AuthService.getExpenseTransactions(familyId: familyId);
        }
      }

      List<FamilyTransactionItem> unbilledItemsList = summary.unbilledItems;
      if (unbilledItemsList.isEmpty) {
        unbilledItemsList = await AuthService.getUnbilledTransactions(familyId: familyId);
      }

      List<FamilyTransactionItem> unpaidExpList = [];
      try {
        final res = await AuthService.getFamilyUnpaidExpense(familyId: familyId);
        unpaidExpList = FamilyTransactionItem.fromResponse(res);
      } catch (_) {}

      List<FamilyTransactionItem> pendingIncList = [];
      try {
        final res = await AuthService.getFamilyUnpaidIncome(familyId: familyId);
        pendingIncList = FamilyTransactionItem.fromResponse(res);
      } catch (_) {}

      List<FamilyTransactionItem> paidExpList = [];
      try {
        final res = await AuthService.getFamilyPaidExpense(familyId: familyId);
        paidExpList = FamilyTransactionItem.fromResponse(res);
      } catch (_) {}

      List<FamilyTransactionItem> paidIncList = [];
      try {
        final res = await AuthService.getFamilyPaidIncome(familyId: familyId);
        paidIncList = FamilyTransactionItem.fromResponse(res);
      } catch (_) {}

      if (!mounted) return;

      num parseAmount(String str) {
        final cleaned = str.replaceAll(RegExp(r'[^0-9.-]'), '');
        return num.tryParse(cleaned) ?? 0;
      }

      String formatVal(num val) {
        return '₹${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 2)}';
      }

      num getItemAmount(FamilyTransactionItem item) {
        num val = parseAmount(item.amount);
        if (val > 0) return val;
        if (item.rawJson != null) {
          for (final key in [
            'dcAmount',
            'fInc_dcAmount',
            'fex_dcAmount',
            'fEx_dcAmount',
            'nAmount',
            'iAmount',
            'fInc_nAmount',
            'fex_nAmount',
            'fEx_nAmount',
            'amount',
            'totalAmount',
            'amt',
            'value',
            'price',
          ]) {
            if (item.rawJson!.containsKey(key) && item.rawJson![key] != null) {
              final parsed = num.tryParse(
                item.rawJson![key].toString().replaceAll(RegExp(r'[^0-9.-]'), ''),
              );
              if (parsed != null && parsed > 0) return parsed;
            }
          }
        }
        return 0;
      }

      num sumList(List<FamilyTransactionItem> list) =>
          list.fold<num>(0, (prev, item) => prev + getItemAmount(item));

      num paidExpSum = sumList(paidExpList);
      num paidIncSum = sumList(paidIncList);
      num unpaidExpSum = sumList(unpaidExpList);
      num pendingIncSum = sumList(pendingIncList);
      num unbilledSum = sumList(unbilledItemsList);

      num totalExpSum = sumList(expenseItems);
      num totalIncSum = sumList(incomeItems);

      num summaryMtdExp = parseAmount(summary.mtdExpense);
      num summaryMtdInc = parseAmount(summary.mtdIncome);
      num summaryProjExp = parseAmount(summary.projectedExpenses);
      num summaryProjInc = parseAmount(summary.projectedIncome);

      num pickTotal(List<num> candidates) {
        for (final c in candidates) {
          if (c > 0) return c;
        }
        return 0;
      }

      num mtdExpNum = pickTotal([paidExpSum, summaryMtdExp, totalExpSum, unpaidExpSum]);
      num mtdIncNum = pickTotal([paidIncSum, summaryMtdInc, totalIncSum, pendingIncSum]);

      num projExpNum = pickTotal([
        paidExpSum + unpaidExpSum,
        totalExpSum,
        summaryProjExp,
        paidExpSum,
        unpaidExpSum,
        summaryMtdExp,
      ]);

      num projIncNum = pickTotal([
        paidIncSum + pendingIncSum,
        totalIncSum,
        summaryProjInc,
        paidIncSum,
        pendingIncSum,
        summaryMtdInc,
      ]);

      List<FamilyTransactionItem> upcomingExpItems =
          summary.upcomingExpense.isNotEmpty ? summary.upcomingExpense : unpaidExpList;
      List<FamilyTransactionItem> upcomingIncItems =
          summary.upcomingIncome.isNotEmpty ? summary.upcomingIncome : pendingIncList;

      num upcomingExpSum = sumList(upcomingExpItems);
      num upcomingIncSum = sumList(upcomingIncItems);

      setState(() {
        _mtdExpense = formatVal(mtdExpNum);
        _mtdIncome = formatVal(mtdIncNum);
        _projExpenses = formatVal(projExpNum);
        _projIncome = formatVal(projIncNum);

        _upcomingExpAmount = formatVal(upcomingExpSum);
        _upcomingExpCount = upcomingExpItems.length;

        _upcomingIncAmount = formatVal(upcomingIncSum);
        _upcomingIncCount = upcomingIncItems.length;

        _unbilledAmount = formatVal(unbilledSum);
        _unbilledCount = unbilledItemsList.length;

        _unpaidRecAmount = formatVal(unpaidExpSum);
        _unpaidRecCount = unpaidExpList.length;

        _hasLoadedHomeData = true;
        _isLoadingHomeData = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasLoadedHomeData = true;
          _isLoadingHomeData = false;
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Soft Purple Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
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
                            _userName.isNotEmpty ? _userName[0].toUpperCase() : 'R',
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
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ApiTestScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x0C000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(Icons.notifications_rounded, color: Color(0xFFF5B731), size: 24),
                                if (_isLoadingHomeData)
                                  const Positioned(
                                    top: 10,
                                    right: 12,
                                    child: SizedBox(
                                      width: 8,
                                      height: 8,
                                      child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFE55B68)),
                                    ),
                                  )
                                else
                                  const Positioned(
                                    top: 10,
                                    right: 12,
                                    child: CircleAvatar(
                                      radius: 4,
                                      backgroundColor: Color(0xFFE55B68),
                                    ),
                                  ),
                              ],
                            ),
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
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RecurringExpensesScreen(),
                            ),
                          );
                          _loadHomeScreenData(showLoading: false);
                        },
                        child: _buildTopStatCard(
                          title: 'MTD EXPENSE',
                          value: _mtdExpense,
                          valueColor: const Color(0xFF262638),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MtdIncomeScreen(),
                            ),
                          );
                          _loadHomeScreenData(showLoading: false);
                        },
                        child: _buildTopStatCard(
                          title: 'MTD INCOME',
                          value: _mtdIncome,
                          valueColor: const Color(0xFF262638),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RecurringExpensesScreen(),
                            ),
                          );
                          _loadHomeScreenData(showLoading: false);
                        },
                        child: _buildTopStatCard(
                          title: 'PROJ. EXPENSES',
                          value: _projExpenses,
                          valueColor: const Color(0xFF7A6830),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RecurringIncomeScreen(),
                            ),
                          );
                          _loadHomeScreenData(showLoading: false);
                        },
                        child: _buildTopStatCard(
                          title: 'PROJ. INCOME',
                          value: _projIncome,
                          valueColor: const Color(0xFF7A6830),
                        ),
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
                                builder: (context) => const RecurringExpensesScreen(),
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
                                builder: (context) => const UnbilledTransactionsScreen(),
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
                                builder: (context) => const RecurringExpensesScreen(),
                              ),
                            );
                            _loadHomeScreenData(showLoading: false);
                          },
                        ),
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

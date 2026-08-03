import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/auth_service.dart';
import '../../widgets/glass_container.dart';
import '../api_test_screen.dart';
import '../auth/login_screen.dart';
import '../unbilled_transactions_screen.dart';
import '../mtd_income_screen.dart';
import '../recurring_expenses_screen.dart';
import '../recurring_income_screen.dart';
import 'edit_profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _invoiceTabController;
  String _userName = '';
  String _userMobile = '';
  String _mtdExpense = '₹0';
  String _mtdIncome = '₹0';
  String _projExpenses = '₹0';
  String _projIncome = '₹0';
  bool _isLoadingHomeData = false;
  bool _isLoadingTransactions = false;
  List<Map<String, dynamic>> _upcomingIncome = [];
  List<Map<String, dynamic>> _upcomingExpense = [];
  List<Map<String, dynamic>> _unbilledItems = [];

  final List<Map<String, dynamic>> _allInvoices = [
    {
      'date': '22/07/2026',
      'merchant': 'Kallubhai',
      'amount': '₹0',
      'ref': 'Inv Ref 26-07-0001',
      'status': 'Paid',
    },
    {
      'date': '22/07/2026',
      'merchant': 'Ramesh Chaiwala',
      'amount': '₹0',
      'ref': 'Inv Ref 26-07-0025',
      'status': 'Pending',
    },
    {
      'date': '23/07/2026',
      'merchant': 'Super Market',
      'amount': '₹0',
      'ref': 'Inv Ref 26-07-0030',
      'status': 'Paid',
    },
  ];

  bool get _isIOS => !kIsWeb && Platform.isIOS;

  @override
  void initState() {
    super.initState();
    _invoiceTabController = TabController(length: 3, vsync: this);
    _loadUserProfile();
    _loadHomeScreenData();
  }

  Future<void> _loadUserProfile() async {
    final name = await AuthService.getUserName();
    final mobile = await AuthService.getUserMobile();
    if (mounted) {
      setState(() {
        _userName = (name == null || name.isEmpty) ? 'User' : name;
        _userMobile = (mobile == null || mobile.isEmpty) ? '' : mobile;
      });
    }
  }

  Future<void> _loadHomeScreenData() async {
    setState(() {
      _isLoadingHomeData = true;
      _isLoadingTransactions = true;
    });

    try {
      final summary = await AuthService.getHomeScreenData(familyId: 1);
      final incomeItems = await AuthService.getIncomeTransactions(familyId: 1);
      final expenseItems = await AuthService.getExpenseTransactions(familyId: 1);
      final unbilledItems = await AuthService.getUnbilledTransactions(familyId: 1);
      if (!mounted) return;

      setState(() {
        _mtdExpense = summary.mtdExpense;
        _mtdIncome = summary.mtdIncome;
        _projExpenses = summary.projectedExpenses;
        _projIncome = summary.projectedIncome;
        _upcomingIncome = incomeItems.take(3).map((item) => {
          'name': item.name,
          'amount': item.amount,
          'date': item.date,
          'status': item.status,
        }).toList();
        _upcomingExpense = expenseItems.take(3).map((item) => {
          'name': item.name,
          'amount': item.amount,
          'date': item.date,
          'status': item.status,
        }).toList();
        _unbilledItems = unbilledItems.take(3).map((item) => {
          'name': item.name,
          'amount': item.amount,
        }).toList();
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _mtdExpense = '₹0';
          _mtdIncome = '₹0';
          _projExpenses = '₹0';
          _projIncome = '₹0';
          _upcomingIncome = [];
          _upcomingExpense = [];
          _unbilledItems = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingHomeData = false;
          _isLoadingTransactions = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _invoiceTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isIOS ? const Color(0xFFF2F2F7) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildBody()),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return _buildInvoicesContent();
      case 2:
        return _buildMastersContent();
      case 3:
        return _buildProfileContent();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return Column(
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
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
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
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
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
                      style: TextStyle(color: Colors.grey, fontSize: 14),
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
                    icon: const Icon(Icons.api_outlined, color: Colors.grey),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Stack(
                      children: [
                        Icon(Icons.notifications_outlined, color: Colors.grey),
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
              _buildStatCard(
                'MTD EXPENSE',
                _mtdExpense,
                '↓ 4.2% vs last mo.',
                Colors.red,
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
              _buildStatCard(
                'PROJ. EXPENSES',
                _projExpenses,
                '',
                Colors.transparent,
              ),
              _buildStatCard(
                'PROJ. INCOME',
                _projIncome,
                '',
                Colors.transparent,
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
              children: [
                if (_isLoadingTransactions)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else ...[
                  ..._upcomingExpense.map((item) => _buildListItem(
                        Icons.cake_outlined,
                        item['name'] ?? 'Expense',
                        item['date'] ?? 'Next 7 days',
                        item['amount'] ?? '₹0',
                        0,
                        Colors.red.shade50,
                      )),
                  ..._upcomingIncome.map((item) => _buildListItem(
                        Icons.cake_outlined,
                        item['name'] ?? 'Income',
                        item['date'] ?? 'Next 7 days',
                        item['amount'] ?? '₹0',
                        0,
                        Colors.green.shade50,
                      )),
                ],
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
                    _unbilledItems.isNotEmpty
                        ? _unbilledItems.map((item) => item['amount'] ?? '₹0').join(', ')
                        : '₹0',
                    _unbilledItems.length,
                    Colors.blue.shade50,
                  ),
                ),
                _buildListItem(
                  Icons.hourglass_empty,
                  'Unpaid Recurring',
                  'Action needed',
                  '₹36,480',
                  8,
                  Colors.orange.shade50,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoicesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => setState(() => _selectedIndex = 0),
                icon: const Icon(Icons.arrow_back),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 20),
              const Text(
                'My Invoices',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2E4D),
                ),
              ),
              const Text(
                'Invoices for this month',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),

        // Swipable Filter (TabBar)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _invoiceTabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: const Color(0xFF2D2E4D),
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Paid'),
                Tab(text: 'Pending'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // TabBarView for swipable content
        Expanded(
          child: TabBarView(
            controller: _invoiceTabController,
            children: [
              _buildInvoiceList('All'),
              _buildInvoiceList('Paid'),
              _buildInvoiceList('Pending'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMastersContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => setState(() => _selectedIndex = 0),
                icon: const Icon(Icons.arrow_back),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 20),
              const Text(
                'Masters',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2E4D),
                ),
              ),
              const Text(
                'Manage the data behind your app',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              _buildMasterItem(
                Icons.apartment,
                'Recurring Fix Expenses',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecurringExpensesScreen(),
                    ),
                  );
                },
              ),
              _buildMasterItem(
                Icons.apartment,
                'Recurring Fix Income',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecurringIncomeScreen(),
                    ),
                  );
                },
              ),
              _buildMasterItem(
                Icons.location_on_outlined,
                'Search Merchant Near Me',
              ),
              _buildMasterItem(Icons.business_outlined, 'My Merchants'),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF7E2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF3E5A0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: Color(0xFFB8860B)),
                      Text(
                        ' Premium',
                        style: TextStyle(
                          color: Color(0xFFB8860B),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildMasterItem(Icons.bar_chart_outlined, 'Spending Insights'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileContent() {
    return Column(
      children: [
        // Profile Header
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF0EFFF),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: const Color(0xFFDCD6F7),
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: Colors.brown.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName.isNotEmpty ? _userName : 'User',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2E4D),
                      ),
                    ),
                    Text(
                      _userMobile.isNotEmpty ? '+91 $_userMobile' : '',
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Premium Badge
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF7E2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF3E5A0)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 14, color: Color(0xFFB8860B)),
                  Text(
                    ' Premium Member',
                    style: TextStyle(
                      color: Color(0xFFB8860B),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Profile Menu Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              _buildProfileItem(
                Icons.person_outline,
                'Personal Details',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
              _buildProfileItem(
                Icons.notifications_none,
                'Notifications',
                color: Colors.orange,
              ),
              _buildProfileItem(
                Icons.lock_outline,
                'Security & Password',
                color: Colors.blueGrey,
              ),
              _buildProfileItem(
                Icons.dark_mode_outlined,
                'Theme',
                trailing: 'Light ✓',
                color: Colors.black87,
              ),
              _buildProfileItem(
                Icons.logout,
                'Log Out',
                color: Colors.red,
                onTap: () async {
                  final navigator = Navigator.of(context);
                  await AuthService.logout();
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem(
    IconData icon,
    String title, {
    String? trailing,
    Color color = Colors.grey,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EFFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF2D3436),
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterItem(IconData icon, String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EFFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF6C5CE7), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF2D3436),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceList(String status) {
    final filteredInvoices = status == 'All'
        ? _allInvoices
        : _allInvoices.where((inv) => inv['status'] == status).toList();

    if (filteredInvoices.isEmpty) {
      return const Center(child: Text('No invoices found'));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        // Table Section
        GlassContainer(
          borderRadius: 16,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0EFFF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'DATE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2E4D),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        'MERCHANT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2E4D),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'AMOUNT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2E4D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...filteredInvoices.map(
                (inv) => Column(
                  children: [
                    _buildTableRow(inv['date'], inv['merchant'], inv['amount']),
                    if (inv != filteredInvoices.last)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Cards Section
        ...filteredInvoices.map(
          (inv) => _buildInvoiceCard(
            inv['ref'],
            '${inv['merchant']} · ${inv['date']}',
            inv['status'],
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(String date, String merchant, String amount) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(date, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            flex: 4,
            child: Text(merchant, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              amount,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(String ref, String subtitle, String status) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: status == 'Paid'
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.receipt_outlined,
              color: status == 'Paid' ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D2E4D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              minimumSize: const Size(60, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('View', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String amount,
    String trend,
    Color trendColor,
  ) {
    bool isTotal = label.contains('MTD INCOME');
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      color: isTotal ? const Color(0xFF6C5CE7) : Colors.white,
      opacity: isTotal ? 0.8 : 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isTotal ? Colors.white70 : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isTotal ? Colors.white : const Color(0xFF2D2E4D),
            ),
          ),
          if (trend.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isTotal ? Colors.white24 : trendColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                trend,
                style: TextStyle(
                  fontSize: 10,
                  color: isTotal ? Colors.white : trendColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListItem(
    IconData icon,
    String title,
    String subtitle,
    String amount,
    int count,
    Color bg,
  ) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bg.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black87, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF2D2E4D),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
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
                  fontSize: 16,
                  color: Color(0xFF2D2E4D),
                ),
              ),
              if (count > 0)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_outlined, 'Home', 0),
          _buildNavItem(Icons.description_outlined, 'Invoices', 1),
          Transform.translate(
            offset: const Offset(0, -10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF2D2E4D),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.swap_vert, color: Colors.white),
            ),
          ),
          _buildNavItem(Icons.grid_view, 'Masters', 2),
          _buildNavItem(Icons.account_circle_outlined, 'Profile', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF2D2E4D) : Colors.grey,
            size: 24,
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF2D2E4D) : Colors.grey,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

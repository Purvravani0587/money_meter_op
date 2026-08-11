import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/auth_service.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/responsive_center.dart';
import '../auth/login_screen.dart';
import '../home_screen.dart';
import '../recurring_expenses_screen.dart';
import '../recurring_income_screen.dart';
import '../add_recurring_expense_screen.dart';
import '../add_recurring_income_screen.dart';
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
  DateTime? _masterFromDate;
  DateTime? _masterToDate;

  Future<void> _selectMasterFromDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _masterFromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _masterFromDate = picked;
      });
    }
  }

  Future<void> _selectMasterToDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _masterToDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _masterToDate = picked;
      });
    }
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2E4D)),
      ),
      backgroundColor: const Color(0xFFEAEFF5),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onPressed: onTap,
    );
  }

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
  }

  Future<void> _loadUserProfile() async {
    final name = await AuthService.getUserName();
    final mobile = await AuthService.getUserMobile();
    if (mounted) {
      final newName = (name == null || name.isEmpty) ? 'User' : name;
      final newMobile = (mobile == null || mobile.isEmpty) ? '' : mobile;
      if (_userName != newName || _userMobile != newMobile) {
        setState(() {
          _userName = newName;
          _userMobile = newMobile;
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
            Expanded(
              child: ResponsiveCenter(
                maxWidth: 800,
                child: _buildBody(),
              ),
            ),
            ResponsiveCenter(
              maxWidth: 800,
              child: _buildBottomNav(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        _buildHomeContent(),
        _buildInvoicesContent(),
        _buildMastersContent(),
        _buildProfileContent(),
      ],
    );
  }

  Widget _buildHomeContent() {
    return const HomeScreen();
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
    String formatDate(DateTime? dt) {
      if (dt == null) return '';
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }

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

        // Date Filter Box
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.filter_alt_outlined,
                            size: 18, color: Color(0xFF2D2E4D)),
                        SizedBox(width: 6),
                        Text(
                          'Master Date Filter',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D2E4D),
                          ),
                        ),
                      ],
                    ),
                    if (_masterFromDate != null || _masterToDate != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _masterFromDate = null;
                            _masterToDate = null;
                          });
                        },
                        child: const Text(
                          'Clear Filter',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectMasterFromDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _masterFromDate != null
                                  ? const Color(0xFF2D2E4D)
                                  : const Color(0xFFD1D5DB),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _masterFromDate != null
                                      ? formatDate(_masterFromDate)
                                      : 'From Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _masterFromDate != null
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _masterFromDate != null
                                        ? const Color(0xFF2D2E4D)
                                        : Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectMasterToDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _masterToDate != null
                                  ? const Color(0xFF2D2E4D)
                                  : const Color(0xFFD1D5DB),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _masterToDate != null
                                      ? formatDate(_masterToDate)
                                      : 'To Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _masterToDate != null
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _masterToDate != null
                                        ? const Color(0xFF2D2E4D)
                                        : Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Quick preset chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPresetChip('This Month', () {
                        final now = DateTime.now();
                        setState(() {
                          _masterFromDate = DateTime(now.year, now.month, 1);
                          _masterToDate =
                              DateTime(now.year, now.month + 1, 0);
                        });
                      }),
                      const SizedBox(width: 6),
                      _buildPresetChip('Last 30 Days', () {
                        final now = DateTime.now();
                        setState(() {
                          _masterFromDate =
                              now.subtract(const Duration(days: 30));
                          _masterToDate = now;
                        });
                      }),
                      const SizedBox(width: 6),
                      _buildPresetChip('This Year', () {
                        final now = DateTime.now();
                        setState(() {
                          _masterFromDate = DateTime(now.year, 1, 1);
                          _masterToDate = DateTime(now.year, 12, 31);
                        });
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              _buildMasterItem(
                Icons.repeat,
                'Recurring Fix Expense',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecurringExpensesScreen(
                        initialFromDate: _masterFromDate,
                        initialToDate: _masterToDate,
                      ),
                    ),
                  );
                },
              ),
              _buildMasterItem(
                Icons.apartment,
                'Recurring Fix Income',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecurringIncomeScreen(
                        initialFromDate: _masterFromDate,
                        initialToDate: _masterToDate,
                      ),
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
            color: const Color(0xFFEAEFF5),
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
                color: const Color(0xFFEAEFF5),
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
                color: const Color(0xFFEAEFF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF2D2E4D), size: 24),
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
                  color: Color(0xFFEAEFF5),
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



  void _showQuickActionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Quick Actions & Options',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2E4D),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_card, color: Color(0xFFE53935)),
                ),
                title: const Text('Add Recurring Fix Expense', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: const Text('Create a new recurring expense record', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddRecurringExpenseScreen()),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF43A047)),
                ),
                title: const Text('Add Recurring Fix Income', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: const Text('Create a new recurring income record', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddRecurringIncomeScreen()),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.repeat, color: Color(0xFFFB8C00)),
                ),
                title: const Text('Recurring Expenses Master', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: const Text('View and manage expense master records', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RecurringExpensesScreen()),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.apartment, color: Color(0xFF00ACC1)),
                ),
                title: const Text('Recurring Income Master', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: const Text('View and manage income master records', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RecurringIncomeScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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
          GestureDetector(
            onTap: _showQuickActionsBottomSheet,
            child: Transform.translate(
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

import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/auth_service.dart';
import '../utils/ui_utils.dart';
import '../widgets/glass_container.dart';
import '../widgets/responsive_center.dart';
import 'add_recurring_income_screen.dart';
import 'mtd_income_screen.dart';

class RecurringIncomeScreen extends StatefulWidget {
  final DateTime? initialFromDate;
  final DateTime? initialToDate;

  const RecurringIncomeScreen({
    super.key,
    this.initialFromDate,
    this.initialToDate,
  });

  @override
  State<RecurringIncomeScreen> createState() => _RecurringIncomeScreenState();
}

class _RecurringIncomeScreenState extends State<RecurringIncomeScreen> {
  List<FamilyTransactionItem> _items = [];
  bool _isLoading = false;
  String? _loadError;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
    _loadData();
  }

  DateTime? _parseDateString(String text) {
    if (text.trim().isEmpty) return null;
    final clean = text.trim();
    final dt = DateTime.tryParse(clean);
    if (dt != null) return dt;

    final parts = clean.split(RegExp(r'[/.\-]'));
    if (parts.length == 3) {
      if (parts[0].length == 4) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) return DateTime(y, m, d);
      } else {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) return DateTime(y, m, d);
      }
    }
    return null;
  }

  List<FamilyTransactionItem> get _filteredItems {
    if (_fromDate == null && _toDate == null) return _items;

    return _items.where((item) {
      final itemDt = _parseDateString(item.date) ??
          _parseDateString(item.startDate) ??
          _parseDateString(item.endDate);

      if (itemDt == null) return true;

      if (_fromDate != null) {
        final start = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
        if (itemDt.isBefore(start)) return false;
      }

      if (_toDate != null) {
        final end = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
        if (itemDt.isAfter(end)) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked;
      });
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _toDate = picked;
      });
    }
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (_items.isEmpty || showLoading) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final items = await AuthService.getAllIncome(familyId: 1);
      if (mounted) {
        setState(() {
          _items = items;
          _loadError = null;
        });
      }
    } catch (error) {
      if (mounted && _items.isEmpty) {
        setState(
          () => _loadError = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openViewScreen(FamilyTransactionItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRecurringIncomeScreen(
          item: item,
          isViewOnly: true,
        ),
      ),
    );
  }

  Future<void> _openEditScreen(FamilyTransactionItem item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRecurringIncomeScreen(
          item: item,
          isViewOnly: false,
        ),
      ),
    );
    if (result == true) {
      await _loadData(showLoading: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

    String formatDate(DateTime? dt) {
      if (dt == null) return '';
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ResponsiveCenter(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recurring Fix Income',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D2E4D),
                              ),
                            ),
                            Text(
                              '${filtered.length} of ${_items.length}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Date Filter Bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectFromDate(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _fromDate != null ? const Color(0xFF2D2E4D) : const Color(0xFFD1D5DB),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _fromDate != null ? formatDate(_fromDate) : 'From Date',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: _fromDate != null ? FontWeight.bold : FontWeight.normal,
                                              color: _fromDate != null ? const Color(0xFF2D2E4D) : Colors.grey,
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
                                  onTap: () => _selectToDate(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _toDate != null ? const Color(0xFF2D2E4D) : const Color(0xFFD1D5DB),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _toDate != null ? formatDate(_toDate) : 'To Date',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: _toDate != null ? FontWeight.bold : FontWeight.normal,
                                              color: _toDate != null ? const Color(0xFF2D2E4D) : Colors.grey,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (_fromDate != null || _toDate != null) ...[
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    setState(() {
                                      _fromDate = null;
                                      _toDate = null;
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: GlassContainer(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      borderRadius: 24,
                      child: RefreshIndicator(
                        onRefresh: _loadData,
                        child: Column(
                          children: [
                            // 3-Column Table Header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAEFF5),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      'INCOME NAME',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Color(0xFF2D2E4D),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'AMOUNT',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Color(0xFF2D2E4D),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'ACTIONS',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Color(0xFF2D2E4D),
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),

                            // 3-Column Table Data
                            Expanded(
                              child: _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : _loadError != null
                                  ? ListView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            children: [
                                              Text(
                                                _loadError!,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              OutlinedButton.icon(
                                                onPressed: _loadData,
                                                icon: const Icon(Icons.refresh),
                                                label: const Text('Retry'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : filtered.isEmpty
                                  ? ListView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      children: const [
                                        Padding(
                                          padding: EdgeInsets.all(32),
                                          child: Center(
                                            child: Text(
                                              'No recurring income sources found for selected dates',
                                              style: TextStyle(color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : ListView.separated(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      itemCount: filtered.length,
                                      separatorBuilder:
                                          (context, index) =>
                                              const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final item = filtered[index];
                                        return _build3ColumnRow(item);
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100), // Space for FAB
                ],
              ),

              Positioned(
                right: 24,
                bottom: 24,
                child: FloatingActionButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddRecurringIncomeScreen(),
                      ),
                    );
                    if (result == true) {
                      await _loadData(showLoading: false);
                    }
                  },
                  backgroundColor: const Color(0xFF2D2E4D),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _build3ColumnRow(FamilyTransactionItem item) {
    final statusText = item.status.isEmpty ? 'Pending' : item.status;
    final isActive = statusText.toUpperCase().startsWith('A') || statusText.toLowerCase() == 'active';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Column 1: Income Name & Status Badge
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF2D3436),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Column 2: Amount
          Expanded(
            flex: 3,
            child: Text(
              item.amount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF2D2E4D),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Column 3: Action Button
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildActionButton(item),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(FamilyTransactionItem item) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      onSelected: (value) {
        if (value == 'view') {
          _openViewScreen(item);
        } else if (value == 'edit') {
          _openEditScreen(item);
        } else if (value == 'close') {
          _toggleStatus(item);
        } else if (value == 'history') {
          _showHistoryBottomSheet(item);
        } else if (value == 'transaction') {
          _openTransactions(item);
        } else if (value == 'party') {
          _showPartyDetailsBottomSheet(item);
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF2D2E4D)),
              SizedBox(width: 10),
              Text('View', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2D2E4D)),
              SizedBox(width: 10),
              Text('Edit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'close',
          child: Row(
            children: [
              Icon(Icons.highlight_off_outlined, size: 18, color: Color(0xFF2D2E4D)),
              SizedBox(width: 10),
              Text('Mark as Closed', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'history',
          child: Row(
            children: [
              Icon(Icons.history, size: 18, color: Color(0xFF2D2E4D)),
              SizedBox(width: 10),
              Text('History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'transaction',
          child: Row(
            children: [
              Icon(Icons.account_balance_outlined, size: 18, color: Color(0xFF2D2E4D)),
              SizedBox(width: 10),
              Text('Transaction', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'party',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 18, color: Color(0xFF2D2E4D)),
              SizedBox(width: 10),
              Text('Party Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF7C5CFC),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C5CFC).withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Action',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStatus(FamilyTransactionItem item) async {
    final isCurrentlyActive = item.status.toUpperCase().startsWith('A') || item.status.toLowerCase() == 'active';
    final newStatus = isCurrentlyActive ? 'D' : 'A';
    final actionLabel = newStatus == 'D' ? 'Mark as Closed' : 'Activate';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionLabel Income'),
        content: Text('Are you sure you want to ${actionLabel.toLowerCase()} "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D2E4D)),
            child: Text(actionLabel, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final incomeId = int.tryParse(item.id) ?? 0;
        await AuthService.updateIncomeMaster(
          familyId: 1,
          incomeId: incomeId,
          incomeName: item.name,
          incomeType: item.type.isNotEmpty ? item.type : 'I',
          cycleMonths: 1,
          startDate: item.startDate,
          amount: int.tryParse(item.amount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
          nextDueDate: item.endDate,
          status: newStatus,
        );
        if (mounted) {
          UIUtils.showTopMessage(context, 'Status updated successfully');
          _loadData(showLoading: false);
        }
      } catch (e) {
        if (mounted) {
          UIUtils.showTopMessage(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
        }
      }
    }
  }

  void _showHistoryBottomSheet(FamilyTransactionItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Color(0xFF7C5CFC)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'History - ${item.name}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D2E4D)),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline, color: Colors.green),
              title: Text('Amount: ${item.amount}'),
              subtitle: Text('Date: ${item.date.isNotEmpty ? item.date : "N/A"} • Status: ${item.status.isNotEmpty ? item.status : "Active"}'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _openTransactions(FamilyTransactionItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MtdIncomeScreen()),
    );
  }

  void _showPartyDetailsBottomSheet(FamilyTransactionItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline, color: Color(0xFF7C5CFC)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Party Details',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D2E4D)),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildPartyRow('Source Name', item.name),
            _buildPartyRow('Amount / Balance', item.amount),
            _buildPartyRow('Status', item.status.isNotEmpty ? item.status : 'Active'),
            if (item.type.isNotEmpty) _buildPartyRow('Type', item.type),
            if (item.startDate.isNotEmpty) _buildPartyRow('Start Date', item.startDate),
            if (item.endDate.isNotEmpty) _buildPartyRow('End Date', item.endDate),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildPartyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D2E4D))),
        ],
      ),
    );
  }
}

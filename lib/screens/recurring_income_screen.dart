import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/auth_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/responsive_center.dart';
import 'add_recurring_income_screen.dart';

class RecurringIncomeScreen extends StatefulWidget {
  const RecurringIncomeScreen({super.key});

  @override
  State<RecurringIncomeScreen> createState() => _RecurringIncomeScreenState();
}

class _RecurringIncomeScreenState extends State<RecurringIncomeScreen> {
  List<FamilyTransactionItem> _items = [];
  bool _isLoading = false;
  String? _loadError;

  Future<void> _editIncome(FamilyTransactionItem item) async {
    final incomeId = int.tryParse(item.id);
    if (incomeId == null || incomeId <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Income id is not available for this item'),
          ),
        );
      }
      return;
    }

    FamilyTransactionItem? detail;
    String? nextDueDate;
    try {
      detail = await AuthService.getIncomeMasterDetail(incomeId: incomeId);
      nextDueDate = await AuthService.getNextDueDate(
        familyId: 1,
        incomeId: incomeId,
      );
    } catch (_) {}

    if (!mounted) return;

    final nameController = TextEditingController(
      text: detail?.name ?? item.name,
    );
    final amountController = TextEditingController(
      text: (detail?.amount ?? item.amount).replaceAll(RegExp(r'[^0-9]'), ''),
    );
    final statusController = TextEditingController(
      text: (detail?.status.isEmpty ?? true)
          ? 'A'
          : (detail?.status ?? item.status),
    );

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Income Master'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Income Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: statusController,
                  decoration: const InputDecoration(labelText: 'Status (A/D)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'name': nameController.text.trim(),
                  'amount': amountController.text.trim(),
                  'status': statusController.text.trim().isEmpty
                      ? 'A'
                      : statusController.text.trim(),
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    setState(() => _isLoading = true);
    try {
      await AuthService.updateIncomeMaster(
        familyId: 1,
        incomeId: incomeId,
        incomeName: result['name'] ?? item.name,
        incomeType: 'I',
        cycleMonths: 1,
        startDate: DateTime.now().toString().split(' ')[0],
        amount: int.tryParse(result['amount'] ?? '0') ?? 0,
        nextDueDate:
            nextDueDate ??
            DateTime.now()
                .add(const Duration(days: 30))
                .toString()
                .split(' ')[0],
        status: (result['status'] ?? 'A').toUpperCase(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Income updated successfully')),
        );
        await _loadData();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final items = await AuthService.getAllIncome(familyId: 1);
      if (mounted) {
        setState(() => _items = items);
      }
    } catch (error) {
      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
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
                      const Text(
                        'Recurring Fix Income',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2E4D),
                        ),
                      ),
                      Text(
                        '${_items.length} income sources',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
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
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: _isLoading
                            ? [
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ]
                            : _loadError != null
                            ? [
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
                              ]
                            : [
                                ..._items.map(
                                  (item) => GestureDetector(
                                    onTap: () => _editIncome(item),
                                    child: _buildItem(
                                      Icons.work_outline,
                                      item.name,
                                      item.status.isEmpty
                                          ? 'Pending'
                                          : item.status,
                                      item.amount,
                                    ),
                                  ),
                                ),
                              ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
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
                    await _loadData();
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

  Widget _buildItem(
    IconData icon,
    String title,
    String status,
    String? amount,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: status == 'Active'
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: status == 'Active' ? Colors.green : Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (amount != null)
            Text(
              amount,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            )
          else
            const Icon(Icons.remove, color: Colors.grey),
        ],
      ),
    );
  }
}

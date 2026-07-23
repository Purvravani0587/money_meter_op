import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/auth_service.dart';
import '../widgets/glass_container.dart';
import 'add_recurring_expense_screen.dart';

class RecurringExpensesScreen extends StatefulWidget {
  const RecurringExpensesScreen({super.key});

  @override
  State<RecurringExpensesScreen> createState() => _RecurringExpensesScreenState();
}

class _RecurringExpensesScreenState extends State<RecurringExpensesScreen> {
  List<FamilyTransactionItem> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final items = await AuthService.getExpenseTransactions(familyId: 1);
      if (mounted) {
        setState(() => _items = items);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _items = []);
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
                        'Recurring Fix Expenses',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2E4D),
                        ),
                      ),
                      const Text(
                        '4 fixed accounts',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: GlassContainer(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    borderRadius: 24,
                    child: ListView(
                      children: _isLoading
                          ? [const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 2)))]
                          : [
                              ..._items.map((item) => _buildItem(
                                    Icons.receipt_long_outlined,
                                    item.name,
                                    item.status.isEmpty ? 'Pending' : item.status,
                                    item.amount,
                                  )),
                            ],
                    ),
                  ),
                ),
                const SizedBox(height: 100), // Space for FAB
              ],
            ),
            
            // FAB
            Positioned(
              right: 24,
              bottom: 24,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddRecurringExpenseScreen()),
                  );
                },
                backgroundColor: const Color(0xFF2D2E4D),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(IconData icon, String title, String status, String? amount) {
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: status == 'Active' ? Colors.green.shade50 : Colors.red.shade50,
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
            Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
          else
            const Icon(Icons.remove, color: Colors.grey),
        ],
      ),
    );
  }
}

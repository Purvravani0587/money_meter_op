import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/auth_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/responsive_center.dart';

class UnbilledTransactionsScreen extends StatefulWidget {
  const UnbilledTransactionsScreen({super.key});

  @override
  State<UnbilledTransactionsScreen> createState() => _UnbilledTransactionsScreenState();
}

class _UnbilledTransactionsScreenState extends State<UnbilledTransactionsScreen> {
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
      final items = await AuthService.getUnbilledTransactions(familyId: 1);
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
        child: ResponsiveCenter(
          child: Column(
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
                    'Unbilled Transactions',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2E4D),
                    ),
                  ),
                  const Text(
                    'Axis Bank',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
            
            GlassContainer(
              margin: const EdgeInsets.symmetric(horizontal: 24.0),
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              borderRadius: 24,
              color: const Color(0xFF2D2E4D),
              opacity: 0.9,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL UNBILLED AMOUNT',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _items.fold<String>('₹0', (sum, item) {
                      final current = num.tryParse(item.amount.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0;
                      final existing = num.tryParse(sum.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0;
                      return '₹${(existing + current).toStringAsFixed(2)}';
                    }),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Expanded(
              child: GlassContainer(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                borderRadius: 24,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0EFFF),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 4, child: Text('MERCHANT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                          Expanded(flex: 3, child: Text('AMOUNT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('ACTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    if (_isLoading)
                      const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 2)))
                    else if (_items.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No unbilled items found')))
                    else ...[
                      ..._items.map((item) => _buildItem(item.name, item.amount)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildItem(String name, String amount) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text(amount, style: const TextStyle(fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D2E4D),
              foregroundColor: Colors.white,
              minimumSize: const Size(60, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('View', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

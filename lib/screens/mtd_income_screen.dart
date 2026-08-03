import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/auth_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/responsive_center.dart';

class MtdIncomeScreen extends StatefulWidget {
  const MtdIncomeScreen({super.key});

  @override
  State<MtdIncomeScreen> createState() => _MtdIncomeScreenState();
}

class _MtdIncomeScreenState extends State<MtdIncomeScreen> {
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
      final items = await AuthService.getIncomeTransactions(familyId: 1);
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
                    'MTD Income Received',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2E4D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: const TextSpan(
                      text: 'Rahul',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                      children: [
                        TextSpan(
                          text: ', your income received this month',
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
                        ),
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
                          Expanded(flex: 3, child: Text('NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('RECEIVED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('REMAINING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isLoading
                        ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                        : ListView.separated(
                            itemCount: _items.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return _buildRow(
                                item.name,
                                item.date,
                                item.amount,
                                item.remaining,
                                remainingColor: item.remaining.contains('₹0')
                                    ? Colors.black
                                    : Colors.red,
                              );
                            },
                          ),
                    ),
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

  Widget _buildRow(String name, String date, String received, String remaining, {Color remainingColor = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(flex: 2, child: Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey))),
          Expanded(flex: 2, child: Text(received, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(flex: 2, child: Text(remaining, style: TextStyle(color: remainingColor, fontWeight: FontWeight.bold, fontSize: 13))),
        ],
      ),
    );
  }
}

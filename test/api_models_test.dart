import 'package:flutter_test/flutter_test.dart';
import 'package:money_meter_op/models/api_models.dart';

void main() {
  group('HomeScreenSummary', () {
    test('parses nested API payload into currency values', () {
      final summary = HomeScreenSummary.fromJson({
        'data': {
          'mtdExpense': 1200,
          'mtdIncome': 1500,
          'projectedExpenses': 2000,
          'projectedIncome': 2500,
        },
      });

      expect(summary.mtdExpense, '₹1200');
      expect(summary.mtdIncome, '₹1500');
      expect(summary.projectedExpenses, '₹2000');
      expect(summary.projectedIncome, '₹2500');
    });
  });

  group('FamilyTransactionItem', () {
    test('parses an income master record wrapped in data', () {
      final items = FamilyTransactionItem.fromResponse({
        'data': {
          'fInc_id': 7,
          'fInc_sIncName': 'Salary',
          'fInc_iAmount': 25000,
          'fInc_dNextDueDate': '2026-08-01',
          'fInc_eStatus': 'A',
        },
      });

      expect(items, hasLength(1));
      expect(items.single.id, '7');
      expect(items.single.name, 'Salary');
      expect(items.single.amount, '₹25000');
      expect(items.single.date, '01/08/2026');
      expect(items.single.status, 'A');
    });

    test('parses an income list wrapped in memberIncome', () {
      final items = FamilyTransactionItem.fromResponse({
        'data': {
          'memberIncome': [
            {'fInc_id': 7, 'fInc_sIncName': 'Salary', 'fInc_iAmount': 25000},
          ],
        },
      });

      expect(items, hasLength(1));
      expect(items.single.name, 'Salary');
    });
  });
}

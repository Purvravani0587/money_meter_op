import 'package:flutter_test/flutter_test.dart';
import 'package:money_meter_op/models/api_models.dart';
import 'package:money_meter_op/services/auth_service.dart';

void main() {
  group('HomeScreenSummary', () {
    test('parses nested API payload into currency values', () {
      final summary = HomeScreenSummary.fromJson({
        'mtdExpense': 1200,
        'mtdIncome': 1500,
        'projectedExpenses': 2000,
        'projectedIncome': 2500,
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

    test('parses an expense master record wrapped in data', () {
      final items = FamilyTransactionItem.fromResponse({
        'data': {
          'fex_id': 2,
          'fex_sName': 'Electricity Bill',
          'fex_nAmount': 1500,
          'fex_dDate': '2026-08-01',
          'fex_eStatus': 'A',
        },
      });

      expect(items, hasLength(1));
      expect(items.single.id, '2');
      expect(items.single.name, 'Electricity Bill');
      expect(items.single.amount, '₹1500');
      expect(items.single.date, '01/08/2026');
      expect(items.single.status, 'A');
    });

    test('parses unwrapped member-expense/2 response directly', () {
      final items = FamilyTransactionItem.fromResponse({
        'fex_id': 2,
        'fex_sName': 'Rent C.G. Office',
        'fex_iAmount': 8000,
        'fex_dStartDate': '2026-04-01',
        'fex_dNextDueDate': '2026-09-01',
        'fex_eExpenseType': 'R',
        'fex_iCycleMonths': 1,
        'fex_eStatus': 'A',
      });

      expect(items, hasLength(1));
      expect(items.single.id, '2');
      expect(items.single.name, 'Rent C.G. Office');
      expect(items.single.amount, '₹8000');
      expect(items.single.startDate, '01/04/2026');
      expect(items.single.endDate, '01/09/2026');
      expect(items.single.type, 'R');
      expect(items.single.status, 'A');
    });
  });

  group('Expense API Request Builders', () {
    test('builds Add Expense (POST member-expense) request body', () {
      final body = AuthService.buildCreateExpenseMasterBody(
        familyId: 1,
        expenseName: 'Electricity Bill',
        expenseType: 'Utility',
        cycleMonths: 1,
        startDate: '2026-08-01',
        amount: 1500,
        nextDueDate: '2026-09-01',
      );

      expect(body['fEx_familyId'], '1');
      expect(body['fEx_sExpName'], 'Electricity Bill');
      expect(body['fEx_eExpType'], 'U');
      expect(body['fEx_iCycleMonths'], '1');
      expect(body['fEx_iAmount'], '1500');
    });

    test('builds Edit Expense Master (PATCH member-expense/{id}) request body', () {
      final body = AuthService.buildUpdateExpenseMasterBody(
        familyId: 1,
        expenseId: 2,
        expenseName: 'Updated Electricity Bill',
        expenseType: 'Utility',
        cycleMonths: 1,
        startDate: '2026-08-01',
        amount: 1800,
        nextDueDate: '2026-09-01',
        status: 'A',
      );

      expect(body['fEx_familyId'], '1');
      expect(body['fEx_id'], '2');
      expect(body['fEx_sExpName'], 'Updated Electricity Bill');
      expect(body['fEx_eExpType'], 'U');
      expect(body['fEx_eStatus'], 'A');
    });

    test('builds View Expense Master Grid query parameters', () {
      final params = AuthService.buildGetExpenseListQueryParameters(
        familyId: 1,
        startRow: 0,
      );

      expect(params['familyId'], '1');
      expect(params['startRow'], '0');
    });
  });
}

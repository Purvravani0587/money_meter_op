import 'package:flutter_test/flutter_test.dart';
import 'package:money_meter_op/services/auth_service.dart';

void main() {
  group('AuthService', () {
    test('builds login body with username and password', () {
      final body = AuthService.buildLoginBody(
        username: '9227219560',
        password: 'Deep@123',
      );

      expect(body['username'], '9227219560');
      expect(body['password'], 'Deep@123');
    });

    test('builds registration body with expected fields', () {
      final body = AuthService.buildRegisterBody(
        fullName: 'Deep',
        dob: '2002-01-01',
        gender: 'M',
        email: 'deep.wipra13@gmail.com',
        mobile: '9227219560',
        password: 'Deep@123',
        confirmPassword: 'Deep@123',
        address: 'Test',
        landmark: 'Law Gardan',
        latitude: '1',
        longitude: '1',
      );

      expect(body['fu_sName'], 'Deep');
      expect(body['fu_sMobileNo'], '9227219560');
      expect(body['fu_sPassword'], 'Deep@123');
      expect(body['confirmPassword'], 'Deep@123');
      expect(body['fm_sAddress'], 'Test');
    });

    test('builds home screen data body for family', () {
      final body = AuthService.buildHomeScreenDataBody(familyId: 1);

      expect(body['fInc_familyId'], '1');
    });

    test('builds family history body with start row', () {
      final body = AuthService.buildFamilyIncomeHistoryBody(
        familyId: 1,
        startRow: 0,
      );

      expect(body['fInc_familyId'], '1');
      expect(body['startRow'], '0');
    });

    test('builds income master update body for edit requests', () {
      final body = AuthService.buildUpdateIncomeMasterBody(
        familyId: 1,
        incomeId: 7,
        incomeName: 'Rent Income',
        incomeType: 'I',
        cycleMonths: 1,
        startDate: '2026-07-20',
        monthDuration: null,
        amount: 50,
        nextDueDate: '2026-08-01',
        status: 'A',
      );

      expect(body['fInc_familyId'], '1');
      expect(body['fInc_sIncName'], 'Rent Income');
      expect(body['fInc_id'], '7');
      expect(body['fInc_eIncType'], 'I');
      expect(body['fInc_iAmount'], '50');
      expect(body['fInc_eStatus'], 'A');
      expect(body['fInc_iMonthDuration'], '');
    });

    test('builds income master create body for recurring income setup', () {
      final body = AuthService.buildCreateIncomeMasterBody(
        familyId: 1,
        incomeName: 'Salary Income',
        incomeType: 'S',
        cycleMonths: 1,
        startDate: '2026-07-20',
        monthDuration: '12',
        amount: 5000,
        nextDueDate: '2026-08-01',
      );

      expect(body['fInc_familyId'], '1');
      expect(body['fInc_sIncName'], 'Salary Income');
      expect(body['fInc_eIncType'], 'S');
      expect(body['fInc_iAmount'], '5000');
      expect(body['fInc_iMonthDuration'], '12');
    });

    test('builds next due date body with income id', () {
      final body = AuthService.buildGetNextDueDateBody(
        familyId: 1,
        incomeId: 7,
      );

      expect(body['fInc_familyId'], '1');
      expect(body['fInc_id'], '7');
    });

    test('builds income list query parameters for get-all-income api', () {
      final query = AuthService.buildGetIncomeListQueryParameters(
        familyId: 1,
        startRow: 0,
      );

      expect(query['familyId'], '1');
      expect(query['startRow'], '0');
    });
  });
}

import 'package:get/get.dart';

import '../models/api_models.dart';
import '../services/auth_service.dart';

class HomeController extends GetxController {
  final userName = RxString('');
  final mtdExpense = RxString('₹0');
  final mtdIncome = RxString('₹0');
  final projExpenses = RxString('₹0');
  final projIncome = RxString('₹0');
  final recurringExpense = RxString('₹0');
  final recurringIncome = RxString('₹0');
  final totalRecurringAmount = RxString('₹0');
  final upcomingExpAmount = RxString('₹0');
  final upcomingExpCount = RxInt(0);
  final upcomingIncAmount = RxString('₹0');
  final upcomingIncCount = RxInt(0);
  final unbilledAmount = RxString('₹0');
  final unbilledCount = RxInt(0);
  final unpaidRecAmount = RxString('₹0');
  final unpaidRecCount = RxInt(0);
  final recentExpensesList = RxList<FamilyTransactionItem>([]);
  final totalExpenseListAmount = RxString('₹0');
  final hasLoadedHomeData = RxBool(false);
  final isLoadingHomeData = RxBool(false);

  @override
  void onInit() {
    super.onInit();
    _loadUserProfile();
    _loadHomeScreenData();
  }

  Future<void> _loadUserProfile() async {
    final name = await AuthService.getUserName();
    userName.value = (name == null || name.isEmpty) ? 'User' : name;
  }

  Future<void> _loadHomeScreenData({bool showLoading = true}) async {
    if (showLoading && !hasLoadedHomeData.value) isLoadingHomeData.value = true;

    try {
      final familyId = await AuthService.getFamilyId();
      final summary = await AuthService.getHomeScreenData(familyId: familyId);

      mtdExpense.value = summary.mtdExpense;
      mtdIncome.value = summary.mtdIncome;
      projExpenses.value = summary.projectedExpenses;
      projIncome.value = summary.projectedIncome;
      recurringExpense.value = summary.recurringExpenseAmount;
      recurringIncome.value = summary.recurringIncomeAmount;
      totalRecurringAmount.value = summary.totalRecurringAmount;
      upcomingExpAmount.value = summary.upcomingExpenseAmount;
      upcomingExpCount.value = summary.upcomingExpense.length;
      upcomingIncAmount.value = summary.upcomingIncomeAmount;
      upcomingIncCount.value = summary.upcomingIncome.length;
      unbilledAmount.value = summary.unbilledAmount;
      unbilledCount.value = summary.unbilledItems.length;
      unpaidRecAmount.value = summary.unpaidRecurringAmount;
      unpaidRecCount.value = 0;
      recentExpensesList.value = summary.expenses;
      totalExpenseListAmount.value = summary.totalExpenseAmount;
    } finally {
      hasLoadedHomeData.value = true;
      isLoadingHomeData.value = false;
    }
  }

  Future<void> refreshHomeData() => _loadHomeScreenData(showLoading: false);
}

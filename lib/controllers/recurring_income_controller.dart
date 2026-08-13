import 'package:get/get.dart';
import '../models/api_models.dart';
import '../services/auth_service.dart';

class RecurringIncomeController extends GetxController {
  final items = RxList<FamilyTransactionItem>([]);
  final isLoading = RxBool(false);
  final loadError = RxString('');
  final fromDate = Rx<DateTime?>(null);
  final toDate = Rx<DateTime?>(null);
  final totalRecurringAmount = RxString('₹0');

  List<FamilyTransactionItem> get filteredItems {
    if (fromDate.value == null && toDate.value == null) return items;

    return items.where((item) {
      final itemDt = _parseDateString(item.date) ??
          _parseDateString(item.startDate) ??
          _parseDateString(item.endDate);

      if (itemDt == null) return true;

      if (fromDate.value != null) {
        final start = DateTime(
            fromDate.value!.year, fromDate.value!.month, fromDate.value!.day);
        if (itemDt.isBefore(start)) return false;
      }

      if (toDate.value != null) {
        final end = DateTime(toDate.value!.year, toDate.value!.month,
            toDate.value!.day, 23, 59, 59);
        if (itemDt.isAfter(end)) return false;
      }

      return true;
    }).toList();
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

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData({bool showLoading = true}) async {
    if (items.isEmpty || showLoading) {
      isLoading.value = true;
      loadError.value = '';
    }
    try {
      final familyId = await AuthService.getFamilyId();
      final itemsResponse = await AuthService.getAllIncome(familyId: familyId);

      items.value = itemsResponse;
      final summary = await AuthService.getHomeScreenData(familyId: familyId);
      totalRecurringAmount.value = summary.recurringIncomeAmount;
      loadError.value = '';
    } catch (error) {
      if (items.isEmpty) {
        loadError.value = error.toString().replaceFirst('Exception: ', '');
      }
    } finally {
      isLoading.value = false;
    }
  }

  void setFromDate(DateTime? date) {
    fromDate.value = date;
  }

  void setToDate(DateTime? date) {
    toDate.value = date;
  }

  void clearDateFilters() {
    fromDate.value = null;
    toDate.value = null;
  }
}

class HomeScreenSummary {
  HomeScreenSummary({
    required this.mtdExpense,
    required this.mtdIncome,
    required this.projectedExpenses,
    required this.projectedIncome,
    this.upcomingIncome = const [],
    this.upcomingExpense = const [],
    this.unbilledItems = const [],
    this.rawJson,
  });

  final String mtdExpense;
  final String mtdIncome;
  final String projectedExpenses;
  final String projectedIncome;
  final List<FamilyTransactionItem> upcomingIncome;
  final List<FamilyTransactionItem> upcomingExpense;
  final List<FamilyTransactionItem> unbilledItems;
  final Map<String, dynamic>? rawJson;

  factory HomeScreenSummary.fromJson(Map<String, dynamic> json) {
    // Helper to merge nested metric objects (summary, totals, metrics, overview) if present
    final mergedJson = <String, dynamic>{...json};
    for (final key in ['summary', 'totals', 'metrics', 'overview', 'data']) {
      if (json[key] is Map) {
        mergedJson.addAll(Map<String, dynamic>.from(json[key]));
      }
    }

    String normalize(dynamic value) {
      if (value == null) return '₹0';
      if (value is num) {
        return '₹${value.toStringAsFixed(0)}';
      }
      final text = value.toString();
      final cleaned = text.replaceAll(RegExp(r'[^0-9.-]'), '');
      final parsed = num.tryParse(cleaned);
      if (parsed == null) return '₹0';
      return '₹${parsed.toStringAsFixed(parsed.truncateToDouble() == parsed ? 0 : 2)}';
    }

    dynamic findValue(List<String> keys) {
      for (final key in keys) {
        if (mergedJson.containsKey(key) && mergedJson[key] != null) {
          return mergedJson[key];
        }
      }
      return null;
    }

    List<FamilyTransactionItem> parseTransactionList(dynamic value) {
      if (value == null) return <FamilyTransactionItem>[];
      if (value is List) {
        return FamilyTransactionItem.fromResponse({'data': value});
      }
      if (value is Map) {
        return FamilyTransactionItem.fromResponse(Map<String, dynamic>.from(value));
      }
      return <FamilyTransactionItem>[];
    }

    final incomeListRaw = findValue([
      'upcomingIncome',
      'upcoming_income',
      'incomes',
      'incomeList',
      'income_list',
      'fInc_list',
      'memberIncome',
      'member_income',
    ]);

    final expenseListRaw = findValue([
      'upcomingExpense',
      'upcoming_expense',
      'expenses',
      'expenseList',
      'expense_list',
      'fex_list',
      'memberExpense',
      'member_expense',
    ]);

    final unbilledListRaw = findValue([
      'unbilledItems',
      'unbilled_items',
      'unbilled',
      'unbilledList',
      'unbilled_list',
    ]);

    return HomeScreenSummary(
      rawJson: json,
      mtdExpense: normalize(
        findValue([
          'mtdExpense',
          'mtd_expense',
          'expenseMtd',
          'expense_mtd',
          'monthlyExpense',
          'monthly_expense',
          'MTDExpense',
          'mtdExpenseAmount',
          'mtd_expense_amount',
          'Total_MTD_Expense',
          'total_mtd_expense',
          'fex_mtd_amount',
          'fex_mtd',
          'mtd_fex_amount',
          'mtd_fex',
        ]),
      ),
      mtdIncome: normalize(
        findValue([
          'mtdIncome',
          'mtd_income',
          'incomeMtd',
          'income_mtd',
          'monthlyIncome',
          'monthly_income',
          'MTDIncome',
          'mtdIncomeAmount',
          'mtd_income_amount',
          'Total_MTD_Income',
          'total_mtd_income',
          'fInc_mtd_amount',
          'finc_mtd',
          'mtd_finc_amount',
          'mtd_finc',
        ]),
      ),
      projectedExpenses: normalize(
        findValue([
          'projectedExpenses',
          'projected_expenses',
          'projExpense',
          'proj_expense',
          'projectedExpense',
          'projected_expense',
          'ProjectedExpense',
          'projected_expense_amount',
          'Total_Projected_Expense',
          'total_projected_expense',
          'fex_projected_amount',
          'fex_projected',
          'proj_fex_amount',
        ]),
      ),
      projectedIncome: normalize(
        findValue([
          'projectedIncome',
          'projected_incomes',
          'projIncome',
          'proj_income',
          'projectedIncome',
          'projected_income',
          'ProjectedIncome',
          'projected_income_amount',
          'Total_Projected_Income',
          'total_projected_income',
          'fInc_projected_amount',
          'finc_projected',
          'proj_finc_amount',
        ]),
      ),
      upcomingIncome: parseTransactionList(incomeListRaw),
      upcomingExpense: parseTransactionList(expenseListRaw),
      unbilledItems: parseTransactionList(unbilledListRaw),
    );
  }
}

class FamilyTransactionItem {
  FamilyTransactionItem({
    required this.id,
    required this.name,
    required this.date,
    required this.amount,
    required this.remaining,
    required this.status,
    this.startDate = '',
    this.endDate = '',
    this.type = '',
    this.paymentCycle = '',
    this.paymentMode = '',
    this.description = '',
    this.rawJson,
  });

  final String id;
  final String name;
  final String date;
  final String amount;
  final String remaining;
  final String status;
  final String startDate;
  final String endDate;
  final String type;
  final String paymentCycle;
  final String paymentMode;
  final String description;
  final Map<String, dynamic>? rawJson;

  static String _normalizeCurrency(dynamic value) {
    if (value == null) return '₹0';
    if (value is num) {
      return '₹${value.toStringAsFixed(0)}';
    }
    final text = value.toString();
    final cleaned = text.replaceAll(RegExp(r'[^0-9.-]'), '');
    final parsed = num.tryParse(cleaned);
    if (parsed == null) return '₹0';
    return '₹${parsed.toStringAsFixed(parsed.truncateToDouble() == parsed ? 0 : 2)}';
  }

  static String _normalizeDate(dynamic value) {
    if (value == null) return '';
    final text = value.toString().trim();
    if (text.isEmpty) return '';
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return text;
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  static String _extractString(
    Map<String, dynamic> json,
    List<String> keys, {
    required String defaultValue,
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return defaultValue;
  }

  static String _extractCurrency(
    Map<String, dynamic> json,
    List<String> keys, {
    String defaultValue = '₹0',
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return _normalizeCurrency(value);
      }
    }
    return defaultValue;
  }

  static String _extractStatus(Map<String, dynamic> json) {
    final status = _extractString(json, [
      'status',
      'paymentStatus',
      'transactionStatus',
      'payStatus',
      'state',
      'fInc_eStatus',
      'fex_eStatus',
      'fEx_eStatus',
    ], defaultValue: '');
    if (status.isNotEmpty) return status;
    if (json['isPaid'] == true) return 'Paid';
    if (json['isPaid'] == false) return 'Pending';
    if (json['isActive'] == true) return 'Active';
    if (json['isActive'] == false) return 'Closed';
    return '';
  }

  factory FamilyTransactionItem.fromJson(Map<String, dynamic> json) {
    final rawDateStr = _extractString(json, [
      'date',
      'entryDate',
      'createdAt',
      'transactionDate',
      'paymentDate',
      'dueDate',
      'fInc_dDate',
      'fInc_dNextDueDate',
      'fex_dDate',
      'fex_dNextDueDate',
      'fEx_dNextDueDate',
    ], defaultValue: '');

    final rawStartDateStr = _extractString(json, [
      'fInc_dStartDate',
      'fex_dStartDate',
      'fEx_dStartDate',
      'startDate',
      'dStartDate',
      'sDate',
      'start_date',
    ], defaultValue: rawDateStr);

    final rawEndDateStr = _extractString(json, [
      'fInc_dNextDueDate',
      'fex_dNextDueDate',
      'fEx_dNextDueDate',
      'fInc_dEndDate',
      'fex_dEndDate',
      'fEx_dEndDate',
      'endDate',
      'nextDueDate',
      'dNextDueDate',
      'dueDate',
    ], defaultValue: rawDateStr);

    return FamilyTransactionItem(
      id: _extractString(json, [
        'id',
        'fInc_id',
        'fex_id',
        'fEx_id',
        'incomeId',
        'expenseId',
        'transactionId',
      ], defaultValue: ''),
      name: _extractString(json, [
        'name',
        'title',
        'itemName',
        'incomeName',
        'expenseName',
        'sName',
        'transactionName',
        'fInc_sName',
        'fInc_sIncName',
        'fex_sName',
        'fex_sExpName',
        'fEx_sExpName',
      ], defaultValue: 'Unnamed'),
      date: _normalizeDate(rawDateStr),
      amount: _extractCurrency(json, [
        'amount',
        'totalAmount',
        'amt',
        'paidAmount',
        'receivedAmount',
        'expectedAmount',
        'invoiceAmount',
        'fInc_nAmount',
        'fInc_iAmount',
        'fex_nAmount',
        'fex_iAmount',
        'fEx_nAmount',
        'fEx_iAmount',
        'value',
      ]),
      remaining: _extractCurrency(json, [
        'remaining',
        'balance',
        'balanceAmount',
        'remainingAmount',
        'outstandingAmount',
        'unpaidAmount',
        'dueAmount',
      ]),
      status: _extractStatus(json),
      startDate: _normalizeDate(rawStartDateStr),
      endDate: _normalizeDate(rawEndDateStr),
      type: _extractString(json, [
        'fInc_eIncType',
        'fex_eExpenseType',
        'fEx_eExpType',
        'incomeType',
        'expenseType',
        'type',
        'eIncType',
        'eExpenseType',
        'eType',
      ], defaultValue: ''),
      paymentCycle: _extractString(json, [
        'fInc_iCycleMonths',
        'fex_iCycleMonths',
        'fEx_iCycleMonths',
        'cycleMonths',
        'paymentCycle',
        'cycle',
        'iCycleMonths',
      ], defaultValue: ''),
      paymentMode: _extractString(json, [
        'paymentMode',
        'mode',
        'pMode',
        'fInc_ePaymentMode',
        'fex_ePaymentMode',
        'fEx_ePaymentMode',
        'payMode',
      ], defaultValue: ''),
      description: _extractString(json, [
        'description',
        'remarks',
        'details',
        'beneficiary',
        'beneficiaryDetails',
        'note',
        'notes',
        'fInc_sDescription',
        'fex_sDescription',
        'fEx_sDescription',
      ], defaultValue: ''),
      rawJson: json,
    );
  }

  static List<FamilyTransactionItem> fromResponse(dynamic response) {
    final items = <FamilyTransactionItem>[];

    if (response is List) {
      for (final item in response) {
        if (item is Map<String, dynamic>) {
          items.add(FamilyTransactionItem.fromJson(item));
        } else if (item is Map) {
          items.add(
            FamilyTransactionItem.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
      return items;
    }

    if (response is Map) {
      final map = Map<String, dynamic>.from(response);
      final data = map['data'];
      if (data is List) {
        return fromResponse(data);
      }
      if (data is Map) {
        final nested =
            data['data'] ??
            data['items'] ??
            data['result'] ??
            data['list'] ??
            data['incomes'] ??
            data['income'] ??
            data['memberIncome'] ??
            data['member_income'] ??
            data['rows'];
        if (nested is List) {
          return fromResponse(nested);
        }
        if (nested is Map) {
          final nestedItems =
              nested['items'] ??
              nested['data'] ??
              nested['list'] ??
              nested['incomes'] ??
              nested['income'] ??
              nested['memberIncome'] ??
              nested['member_income'] ??
              nested['rows'];
          if (nestedItems is List) {
            return fromResponse(nestedItems);
          }
          if (nestedItems is Map) {
            return fromResponse(nestedItems);
          }
        }

        // A single-income response commonly wraps the record directly in
        // `data`, rather than putting it in a list.
        return [
          FamilyTransactionItem.fromJson(Map<String, dynamic>.from(data)),
        ];
      }

      final nestedList =
          map['items'] ??
          map['result'] ??
          map['list'] ??
          map['incomes'] ??
          map['income'] ??
          map['memberIncome'] ??
          map['member_income'] ??
          map['rows'];
      if (nestedList is List) {
        return fromResponse(nestedList);
      }

      // Also support endpoints that return an unwrapped income or expense record.
      if (map.containsKey('fInc_id') ||
          map.containsKey('incomeId') ||
          map.containsKey('fex_id') ||
          map.containsKey('fEx_id') ||
          map.containsKey('expenseId') ||
          map.containsKey('fex_sName') ||
          map.containsKey('fex_sExpName') ||
          map.containsKey('fEx_sExpName') ||
          map.containsKey('fInc_sName') ||
          map.containsKey('fInc_sIncName') ||
          map.containsKey('id')) {
        return [FamilyTransactionItem.fromJson(map)];
      }
    }

    return items;
  }
}

## Recurring Fixed Expense & Income - Complete Flow

### Storage Keys (lib/services/auth_service.dart)
```dart
_kRecurringExpenseKey = 'expence'      // Stores Recurring Fixed Expenses
_kRecurringIncomeKey = 'income'        // Stores Recurring Fixed Income
_kProjectedExpenseKey = 'p_expence'    // Stores Projected Expenses
_kProjectedIncomeKey = 'p_income'      // Stores Projected Income
```

### 1️⃣ RECURRING FIXED EXPENSES FLOW

**Screen:** `lib/screens/recurring_expenses_screen.dart`

```
User Opens RecurringExpensesScreen
        ↓
_loadData() calls:
  - AuthService.getExpenseMasterGrid(familyId) → Fetch all recurring expense records
  - CalculationUtils.calculateTotalSum(items) → SUM all amounts (numeric)
  - CalculationUtils.formatVal(totalSum) → Format as ₹ currency
  - AuthService.saveRecurringExpense(totalAmount) → Store to SharedPreferences
        ↓
SharedPreferences stored with key: 'expence'
```

**Key Details:**
- Fetches from: `AuthService.getExpenseMasterGrid()`
- Calculation: Numeric SUM using `calculateTotalSum()`
- Storage: `AuthService.saveRecurringExpense(amount)`
- Storage Key: `'expence'`
- Format: `₹{amount}` (e.g., ₹5000 or ₹5000.50)

---

### 2️⃣ RECURRING FIXED INCOME FLOW

**Screen:** `lib/screens/recurring_income_screen.dart`

```
User Opens RecurringIncomeScreen
        ↓
_loadData() calls:
  - AuthService.getAllIncome(familyId) → Fetch all income records
  - CalculationUtils.calculateTotalSum(items) → SUM all amounts (numeric)
  - CalculationUtils.formatVal(totalSum) → Format as ₹ currency
  - AuthService.saveRecurringIncome(totalAmount) → Store to SharedPreferences
        ↓
SharedPreferences stored with key: 'income'
```

**Key Details:**
- Fetches from: `AuthService.getAllIncome()`
- Calculation: Numeric SUM using `calculateTotalSum()`
- Storage: `AuthService.saveRecurringIncome(amount)`
- Storage Key: `'income'`
- Format: `₹{amount}` (e.g., ₹15000 or ₹15000.75)

---

### 3️⃣ HOME SCREEN DASHBOARD USAGE

**Screen:** `lib/screens/home_screen.dart` → `_loadHomeScreenData()`

```
Home Screen Loads:
        ↓
Fetches stored amounts:
  - recurringExpenseStr = AuthService.getRecurringExpense() → Gets from 'expence' key
  - recurringIncomeStr = AuthService.getRecurringIncome() → Gets from 'income' key
        ↓
Parse amounts (handles null/empty safely):
  - recurringExpenseNum = CalculationUtils.parseAmount(recurringExpenseStr)
  - recurringIncomeNum = CalculationUtils.parseAmount(recurringIncomeStr)
        ↓
Add to Dashboard Totals:
  - MTD Income = (sum of all income records) + recurringIncomeNum
  - Projected Expenses = (sum of all expense records) + recurringExpenseNum
        ↓
Display in Cards:
  - MTD INCOME card
  - PROJ. EXPENSES card
```

---

## 4️⃣ DATA SAFETY & VALIDATION

✅ **Null/Empty Handling:**
- Empty SharedPreferences returns: `'₹0'`
- parseAmount() converts any string to number (returns 0 if invalid)
- No crashes on missing data

✅ **Numeric Calculations:**
- SUM using `fold<num>()` - proper numeric operation
- No string concatenation
- Decimal places preserved in formatting

✅ **Auto-Refresh:**
- Called on screen load
- Called after navigation returns
- New/edited/deleted records update totals automatically

✅ **Fallback Logic:**
- Try-catch around all API calls
- Default to empty list if API fails
- Default to ₹0 if calculation fails

---

## 5️⃣ CALCULATION UTILITY (lib/utils/calculation_utils.dart)

```dart
// Extract amount from transaction item
getItemAmount(item) → Parse item.amount, check rawJson fields, return num

// Calculate total sum from list
calculateTotalSum(items) → items.fold<num>(0, (prev, item) => prev + getItemAmount(item))

// Parse string amount
parseAmount(str) → Remove special chars, convert to num, return 0 if invalid

// Format number as currency
formatVal(num) → ₹{number.toStringAsFixed(decimals)}
```

---

## 6️⃣ API ENDPOINTS USED

| Operation | Endpoint | Returns |
|-----------|----------|---------|
| Get Recurring Expenses | `getExpenseMasterGrid()` | List<FamilyTransactionItem> |
| Get Recurring Income | `getAllIncome()` | List<FamilyTransactionItem> |
| Store Expense Amount | `saveRecurringExpense(amount)` | Void |
| Store Income Amount | `saveRecurringIncome(amount)` | Void |
| Fetch Stored Expense | `getRecurringExpense()` | String (₹format) |
| Fetch Stored Income | `getRecurringIncome()` | String (₹format) |

---

## ✅ VERIFICATION CHECKLIST

- [x] Recurring Fixed Expenses fetches from `getExpenseMasterGrid()`
- [x] Recurring Fixed Income fetches from `getAllIncome()`
- [x] Both calculate numeric SUM (not string concat)
- [x] Both store formatted amounts to SharedPreferences
- [x] Home screen fetches and uses stored amounts
- [x] Amounts added to MTD and Projected calculations
- [x] Handles null/empty values safely (shows ₹0)
- [x] Auto-refreshes when records change
- [x] No hardcoded values
- [x] Proper error handling throughout
- [x] Storage keys: 'expence' (expense), 'income'
- [x] Format: ₹{amount} with proper decimal handling

---

## 🎯 SUMMARY

**Recurring Fixed Expenses** and **Recurring Fixed Income** are fully implemented:
1. ✅ Data fetched from API
2. ✅ Amounts summed numerically
3. ✅ Stored to SharedPreferences with proper keys
4. ✅ Used in Home Dashboard calculations
5. ✅ Auto-refresh on data changes
6. ✅ Safe handling of edge cases

// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../providers/account_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/recurring_provider.dart';
import '../services/currency_rate_service.dart';
import '../services/refresh_service.dart';
import 'account_screen.dart';
import 'all_transactions_screen.dart';
import 'expense_list_screen.dart';
import 'income_list_screen.dart';
import 'loans_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'savings_goal_screen.dart';
import 'summary_screen.dart';
import 'dual_balance_section.dart';
import 'collapsible_monthly_summary.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _balanceVisible = true;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadMonthPreference();
    Future.microtask(() async {
      if (!mounted) return;
      await ref.read(recurringProvider.notifier).processDue();
      if (!mounted) return;
      ref.invalidate(incomeProvider);
      ref.invalidate(expenseProvider);
    });
  }

  Future<void> _loadMonthPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMonth = prefs.getString('selectedMonth');
    if (savedMonth != null) {
      setState(() {
        _selectedMonth = DateTime.parse(savedMonth);
      });
    }
  }

  Future<void> _saveMonthPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedMonth', _selectedMonth.toIso8601String());
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      _saveMonthPreference();
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      _saveMonthPreference();
    });
  }

  void _goToCurrentMonth() {
    setState(() {
      _selectedMonth = DateTime.now();
      _saveMonthPreference();
    });
  }

  @override
  Widget build(BuildContext context) {
    final incomeAsync = ref.watch(incomeProvider);
    final expenseAsync = ref.watch(expenseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => refreshAll(ref),
          ),
          Consumer(
            builder: (context, ref, _) {
              final selected = ref.watch(selectedCurrencyProvider);
              return PopupMenuButton<String>(
                initialValue: selected,
                tooltip: 'Display currency',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                  child: Text(selected,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                onSelected: (currency) => ref
                    .read(selectedCurrencyProvider.notifier)
                    .state = currency,
                itemBuilder: (_) => CurrencyRateService.supported
                    .map((c) => PopupMenuItem(
                          value: c,
                          child: Text('$c  ${CurrencyRateService.symbolFor(c)}'),
                        ))
                    .toList(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(incomeProvider);
          ref.invalidate(expenseProvider);
        },
        child: incomeAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (incomes) => expenseAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (expenses) => _Body(
              incomes: incomes,
              expenses: expenses,
              balanceVisible: _balanceVisible,
              selectedMonth: _selectedMonth,
              onToggleBalance: () =>
                  setState(() => _balanceVisible = !_balanceVisible),
              onPreviousMonth: _previousMonth,
              onNextMonth: _nextMonth,
              onGoToCurrentMonth: _goToCurrentMonth,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Month Selector Widget ────────────────────────────────────────────────────
class _MonthSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCurrent;

  const _MonthSelector({
    required this.selectedMonth,
    required this.onPrevious,
    required this.onNext,
    required this.onCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentMonth = DateTime.now().year == selectedMonth.year &&
        DateTime.now().month == selectedMonth.month;
    final monthFormat = DateFormat('MMMM yyyy');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: onPrevious,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  monthFormat.format(selectedMonth),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isCurrentMonth)
                  GestureDetector(
                    onTap: onCurrent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Back to Current',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: onNext,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  final List<IncomeModel> incomes;
  final List<ExpenseModel> expenses;
  final bool balanceVisible;
  final DateTime selectedMonth;
  final VoidCallback onToggleBalance;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onGoToCurrentMonth;

  const _Body({
    required this.incomes,
    required this.expenses,
    required this.balanceVisible,
    required this.selectedMonth,
    required this.onToggleBalance,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onGoToCurrentMonth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCurrency = ref.watch(selectedCurrencyProvider);
    final ratesAsync = ref.watch(exchangeRatesProvider);

    return ratesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildBody(
          context, ref, selectedCurrency, CurrencyRateService.fallbackRates),
      data: (rates) => _buildBody(context, ref, selectedCurrency, rates),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref,
      String selectedCurrency, Map<String, double> rates) {
    final fmt = NumberFormat('#,##0.00');
    final symbol = CurrencyRateService.symbolFor(selectedCurrency);

    final loanAsync = ref.watch(loanProvider);
    final loans = loanAsync.value ?? [];
    final totalLentRemaining = loans
        .where((l) => l.isLent && !l.isSettled)
        .fold(0.0, (sum, l) => sum + l.remaining);
    final totalBorrowedRemaining = loans
        .where((l) => !l.isLent && !l.isSettled)
        .fold(0.0, (sum, l) => sum + l.remaining);

    const loanSectors = {
      'Loan Given',
      'Loan Received',
      'Loan Borrowed',
      'Loan Repaid',
    };

    double allTimeConvertedIncome = incomes.fold(
        0.0,
        (sum, i) =>
            sum +
            convertAmount(
                amount: i.amount,
                fromCurrency: i.currency,
                toCurrency: selectedCurrency,
                rates: rates));
    double allTimeConvertedExpense = expenses.fold(
        0.0,
        (sum, e) =>
            sum +
            convertAmount(
                amount: e.amount,
                fromCurrency: e.currency,
                toCurrency: selectedCurrency,
                rates: rates));

    double allTimeDisplayIncome = incomes
        .where((i) => !loanSectors.contains(i.sector))
        .fold(
            0.0,
            (sum, i) =>
                sum +
                convertAmount(
                    amount: i.amount,
                    fromCurrency: i.currency,
                    toCurrency: selectedCurrency,
                    rates: rates));
    double allTimeDisplayExpense = expenses
        .where((e) => !loanSectors.contains(e.sector))
        .fold(
            0.0,
            (sum, e) =>
                sum +
                convertAmount(
                    amount: e.amount,
                    fromCurrency: e.currency,
                    toCurrency: selectedCurrency,
                    rates: rates));

    final accountAsync = ref.watch(accountProvider);
    final accounts = accountAsync.value ?? [];
    final accountBalance = accounts.fold(0.0, (sum, a) => sum + a.balance);

    final allTimeCashBalance =
        allTimeConvertedIncome - allTimeConvertedExpense - accountBalance;
    final allTimeTotalBalance = allTimeCashBalance + accountBalance;

    final monthlyIncomes = incomes
        .where((i) =>
            i.date.year == selectedMonth.year &&
            i.date.month == selectedMonth.month)
        .toList();
    final monthlyExpenses = expenses
        .where((e) =>
            e.date.year == selectedMonth.year &&
            e.date.month == selectedMonth.month)
        .toList();

    double monthlyIncome = monthlyIncomes
        .where((i) => !loanSectors.contains(i.sector))
        .fold(
            0.0,
            (sum, i) =>
                sum +
                convertAmount(
                    amount: i.amount,
                    fromCurrency: i.currency,
                    toCurrency: selectedCurrency,
                    rates: rates));

    double monthlyExpense = monthlyExpenses
        .where((e) => !loanSectors.contains(e.sector))
        .fold(
            0.0,
            (sum, e) =>
                sum +
                convertAmount(
                    amount: e.amount,
                    fromCurrency: e.currency,
                    toCurrency: selectedCurrency,
                    rates: rates));

    final monthlyCashBalance = monthlyIncome - monthlyExpense;
    final monthlyTotalBalance = monthlyCashBalance;

    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recent = _mergeAndSort(incomes, expenses)
        .where((t) => (t['date'] as DateTime).isAfter(oneWeekAgo))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(0),
      children: [
        const SizedBox(height: 12),
        _MonthSelector(
          selectedMonth: selectedMonth,
          onPrevious: onPreviousMonth,
          onNext: onNextMonth,
          onCurrent: onGoToCurrentMonth,
        ),
        
        // ── Dual Balance Section (from external file) ──
        DualBalanceSection(
          allTimeCash: allTimeCashBalance,
          allTimeAccount: accountBalance,
          allTimeTotal: allTimeTotalBalance,
          allTimeIncome: allTimeDisplayIncome,
          allTimeExpense: allTimeDisplayExpense,
          allTimeLentRemaining: totalLentRemaining,
          allTimeBorrowedRemaining: totalBorrowedRemaining,
          monthlyCash: monthlyCashBalance,
          monthlyAccount: 0,
          monthlyTotal: monthlyTotalBalance,
          monthlyIncome: monthlyIncome,
          monthlyExpense: monthlyExpense,
          balanceVisible: balanceVisible,
          onToggleBalance: onToggleBalance,
          symbol: symbol,
          fmt: fmt,
          selectedMonth: selectedMonth,
        ),
        
        const SizedBox(height: 20),
        
        // ── Navigation Buttons ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            children: [
              Row(
                children: [
                  _NavButton(
                    label: 'Income',
                    icon: Icons.arrow_downward_rounded,
                    color: const Color(0xFF1D9E75),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const IncomeListScreen())),
                  ),
                  const SizedBox(width: 12),
                  _NavButton(
                    label: 'Expense',
                    icon: Icons.arrow_upward_rounded,
                    color: const Color(0xFFD85A30),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ExpenseListScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _NavButton(
                    label: 'Summary',
                    icon: Icons.bar_chart_rounded,
                    color: const Color(0xFF378ADD),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SummaryScreen())),
                  ),
                  const SizedBox(width: 12),
                  _NavButton(
                    label: 'All Transactions',
                    icon: Icons.list_alt_rounded,
                    color: const Color(0xFF888780),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AllTransactionsScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _NavButton(
                    label: 'Accounts',
                    icon: Icons.account_balance_wallet,
                    color: const Color(0xFF378ADD),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AccountsScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _NavButton(
                    label: 'Goals',
                    icon: Icons.track_changes_rounded,
                    color: const Color(0xFF1D9E75),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SavingsGoalsScreen())),
                  ),
                  const SizedBox(width: 12),
                  _NavButton(
                    label: 'Loans',
                    icon: Icons.handshake_outlined,
                    color: const Color(0xFFD85A30),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const LoansScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // ── Collapsible Monthly Summary (from external file) ──
              CollapsibleMonthlySummary(
                balanceVisible: balanceVisible,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // ── Recent Transactions ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Text('Recent Transactions',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Text('Last 7 days', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('No transactions in the last 7 days.')),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              children:
                  recent.map((t) => _TransactionTile(transaction: t)).toList(),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  List<Map<String, dynamic>> _mergeAndSort(
    List<IncomeModel> incomes,
    List<ExpenseModel> expenses,
  ) {
    final list = <Map<String, dynamic>>[];
    for (final i in incomes) {
      list.add({
        'type': 'income',
        'sector': i.sector,
        'amount': i.amount,
        'currency': i.currency,
        'date': i.date,
      });
    }
    for (final e in expenses) {
      list.add({
        'type': 'expense',
        'sector': e.sector,
        'amount': e.amount,
        'currency': e.currency,
        'date': e.date,
      });
    }
    list.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    return list;
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w500, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction['type'] == 'income';
    final color = isIncome ? const Color(0xFF1D9E75) : const Color(0xFFD85A30);
    final fmt = NumberFormat('#,##0.00');
    final date = transaction['date'] as DateTime;
    final dateStr = '${date.day}/${date.month}/${date.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isIncome ? const Color(0xFFEAF3DE) : const Color(0xFFFAECE7),
          child: Icon(
            isIncome
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            color: color,
            size: 18,
          ),
        ),
        title: Text(transaction['sector']),
        subtitle: Text(dateStr, style: const TextStyle(fontSize: 12)),
        trailing: Text(
          '${isIncome ? '+' : '-'} ৳ ${fmt.format(transaction['amount'])}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
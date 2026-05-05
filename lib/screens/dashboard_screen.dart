// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../providers/auth_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/recurring_provider.dart';
import '../services/currency_rate_service.dart';
import '../services/refresh_service.dart';
import 'all_transactions_screen.dart';
import 'budget_screen.dart';
import 'expense_list_screen.dart';
import 'income_list_screen.dart';
import 'loans_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'recurring_screen.dart';
import 'savings_goal_screen.dart';
import 'summary_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _balanceVisible = true;
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      await ref.read(recurringProvider.notifier).processDue();
      if (!mounted) return;
      ref.invalidate(incomeProvider);
      ref.invalidate(expenseProvider);
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
          // Currency switcher
          Consumer(
            builder: (context, ref, _) {
              final selected = ref.watch(selectedCurrencyProvider);
              return PopupMenuButton<String>(
                initialValue: selected,
                tooltip: 'Display currency',
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                  child: Text(
                    selected,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                onSelected: (currency) => ref
                    .read(selectedCurrencyProvider.notifier)
                    .state = currency,
                itemBuilder: (_) => CurrencyRateService.supported
                    .map((c) => PopupMenuItem(
                          value: c,
                          child:
                              Text('$c  ${CurrencyRateService.symbolFor(c)}'),
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
              onToggleBalance: () =>
                  setState(() => _balanceVisible = !_balanceVisible),
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final List<IncomeModel> incomes;
  final List<ExpenseModel> expenses;
  final bool balanceVisible;
  final VoidCallback onToggleBalance;

  const _Body({
    required this.incomes,
    required this.expenses,
    required this.balanceVisible,
    required this.onToggleBalance,
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

    // Get all unsettled loans
    final loanAsync = ref.watch(loanProvider);
    final loans = loanAsync.value ?? [];

    final totalLentRemaining = loans
        .where((l) => l.isLent && !l.isSettled)
        .fold(0.0, (sum, l) => sum + l.remaining);

    final totalBorrowedRemaining = loans
        .where((l) => !l.isLent && !l.isSettled)
        .fold(0.0, (sum, l) => sum + l.remaining);

    // Loan-related sectors to exclude from displayed totals
    const loanSectors = {
      'Loan Given',
      'Loan Received',
      'Loan Borrowed',
      'Loan Repaid',
    };

// Balance uses ALL entries including loans (keeps balance correct)
    double convertedIncome = incomes.fold(0.0, (sum, i) {
      return sum +
          convertAmount(
            amount: i.amount,
            fromCurrency: i.currency,
            toCurrency: selectedCurrency,
            rates: rates,
          );
    });

    double convertedExpense = expenses.fold(0.0, (sum, e) {
      return sum +
          convertAmount(
            amount: e.amount,
            fromCurrency: e.currency,
            toCurrency: selectedCurrency,
            rates: rates,
          );
    });

// Displayed totals EXCLUDE loan entries
    double displayIncome =
        incomes.where((i) => !loanSectors.contains(i.sector)).fold(
            0.0,
            (sum, i) =>
                sum +
                convertAmount(
                  amount: i.amount,
                  fromCurrency: i.currency,
                  toCurrency: selectedCurrency,
                  rates: rates,
                ));

    double displayExpense =
        expenses.where((e) => !loanSectors.contains(e.sector)).fold(
            0.0,
            (sum, e) =>
                sum +
                convertAmount(
                  amount: e.amount,
                  fromCurrency: e.currency,
                  toCurrency: selectedCurrency,
                  rates: rates,
                ));

    final balance = convertedIncome - convertedExpense;
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

    final recent = _mergeAndSort(incomes, expenses)
        .where((t) => (t['date'] as DateTime).isAfter(oneWeekAgo))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Balance card ──────────────────────────
        Card(
          color: Theme.of(context).colorScheme.primary,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Current Balance',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 14,
                        )),
                    GestureDetector(
                      onTap: onToggleBalance,
                      child: Icon(
                        balanceVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withOpacity(0.8),
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  balanceVisible ? '$symbol ${fmt.format(balance)}' : '****',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: balanceVisible ? 0 : 4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _BalancePill(
                      label: 'Income',
                      amount: balanceVisible
                          ? '$symbol ${fmt.format(displayIncome)}'
                          : '****',
                      color: Colors.greenAccent,
                    ),
                    _BalancePill(
                      label: 'Expense',
                      amount: balanceVisible
                          ? '$symbol ${fmt.format(displayExpense)}'
                          : '****',
                      color: Colors.redAccent,
                    ),
                  ],
                ),
                // After the Income/Expense pills row
                if (totalLentRemaining > 0 || totalBorrowedRemaining > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        if (totalBorrowedRemaining > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Loan Borrowed (Have to pay)',
                                style: TextStyle(
                                  color: Colors.greenAccent.shade100,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                balanceVisible
                                    ? '+ $symbol ${fmt.format(totalBorrowedRemaining)}'
                                    : '****',
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        if (totalLentRemaining > 0) ...[
                          if (totalBorrowedRemaining > 0)
                            const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Loan Lent (Have to receive)',
                                style: TextStyle(
                                  color: Colors.redAccent.shade100,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                balanceVisible
                                    ? '- $symbol ${fmt.format(totalLentRemaining)}'
                                    : '****',
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Nav buttons ───────────────────────────
        Row(
          children: [
            _NavButton(
              label: 'Income',
              icon: Icons.arrow_downward_rounded,
              color: const Color(0xFF1D9E75),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const IncomeListScreen())),
            ),
            const SizedBox(width: 12),
            _NavButton(
              label: 'Expense',
              icon: Icons.arrow_upward_rounded,
              color: const Color(0xFFD85A30),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ExpenseListScreen())),
            ),
            const SizedBox(width: 12),
            _NavButton(
              label: 'Summary',
              icon: Icons.bar_chart_rounded,
              color: const Color(0xFF378ADD),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SummaryScreen())),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            _NavButton(
              label: 'Budget',
              icon: Icons.account_balance_wallet_outlined,
              color: const Color(0xFF7F77DD),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const BudgetScreen())),
            ),
            const SizedBox(width: 12),
            _NavButton(
              label: 'Recurring',
              icon: Icons.repeat,
              color: const Color(0xFF5DCAA5),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RecurringScreen())),
            ),
            const SizedBox(width: 12),
            _NavButton(
              label: 'All',
              icon: Icons.list_alt_rounded,
              color: const Color(0xFF888780),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AllTransactionsScreen())),
            ),
          ],
        ),

        const SizedBox(height: 24),
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

        // ── Recent 7 days ─────────────────────────
        Row(
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
              child: const Text('Last 7 days', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (recent.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('No transactions in the last 7 days.')),
          )
        else
          ...recent.map((t) => _TransactionTile(transaction: t)),
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
// ── Small widgets ──────────────────────────────────────

class _BalancePill extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _BalancePill({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 12)),
        const SizedBox(height: 4),
        Text(amount,
            style: TextStyle(
                color: color, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
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

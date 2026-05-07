// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
          Consumer(
            builder: (context, ref, _) {
              final selected = ref.watch(selectedCurrencyProvider);
              return PopupMenuButton<String>(
                initialValue: selected,
                tooltip: 'Display currency',
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                  child: Text(selected,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
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

// ── Balance card with three views ─────────────────────────────────────────────

class _BalanceCard extends StatefulWidget {
  final double cashBalance;
  final double accountBalance;
  final double totalBalance;
  final double displayIncome;
  final double displayExpense;
  final double totalLentRemaining;
  final double totalBorrowedRemaining;
  final bool balanceVisible;
  final VoidCallback onToggleBalance;
  final String symbol;
  final NumberFormat fmt;

  const _BalanceCard({
    required this.cashBalance,
    required this.accountBalance,
    required this.totalBalance,
    required this.displayIncome,
    required this.displayExpense,
    required this.totalLentRemaining,
    required this.totalBorrowedRemaining,
    required this.balanceVisible,
    required this.onToggleBalance,
    required this.symbol,
    required this.fmt,
  });

  @override
  State<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<_BalanceCard>
    with SingleTickerProviderStateMixin {
  // 0 = cash, 1 = account, 2 = total
  int _view = 0;
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _switchView(int newView) {
    if (newView == _view) return;
    _ctrl.reverse().then((_) {
      setState(() => _view = newView);
      _ctrl.forward();
    });
  }

  String get _currentLabel {
    switch (_view) {
      case 1:
        return 'Account Balance';
      case 2:
        return 'Total Balance';
      default:
        return 'Cash Balance';
    }
  }

  double get _currentAmount {
    switch (_view) {
      case 1:
        return widget.accountBalance;
      case 2:
        return widget.totalBalance;
      default:
        return widget.cashBalance;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = widget.fmt;
    final symbol = widget.symbol;
    final vis = widget.balanceVisible;

    return Card(
      color: Theme.of(context).colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Label + eye ────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Text(
                    _currentLabel,
                    key: ValueKey(_view),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onToggleBalance,
                  child: Icon(
                    vis
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

            // ── Main balance amount ────────────────
            FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Text(
                  vis ? '$symbol ${fmt.format(_currentAmount)}' : '****',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: vis ? 0 : 4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Three tap toggles ──────────────────
            Row(
              children: [
                _ViewToggle(
                  label: 'Cash',
                  icon: Icons.wallet_outlined,
                  selected: _view == 0,
                  onTap: () => _switchView(0),
                ),
                const SizedBox(width: 8),
                _ViewToggle(
                  label: 'Accounts',
                  icon: Icons.account_balance_outlined,
                  selected: _view == 1,
                  onTap: () => _switchView(1),
                ),
                const SizedBox(width: 8),
                _ViewToggle(
                  label: 'Total',
                  icon: Icons.account_balance_wallet_outlined,
                  selected: _view == 2,
                  onTap: () => _switchView(2),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Income / Expense pills ─────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _BalancePill(
                  label: 'Income',
                  amount: vis
                      ? '$symbol ${fmt.format(widget.displayIncome)}'
                      : '****',
                  color: Colors.greenAccent,
                ),
                _BalancePill(
                  label: 'Expense',
                  amount: vis
                      ? '$symbol ${fmt.format(widget.displayExpense)}'
                      : '****',
                  color: Colors.redAccent,
                ),
              ],
            ),

            // ── Loan pending section ───────────────
            if (widget.totalLentRemaining > 0 ||
                widget.totalBorrowedRemaining > 0) ...[
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
                    if (widget.totalBorrowedRemaining > 0)
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
                            vis
                                ? '+ $symbol ${fmt.format(widget.totalBorrowedRemaining)}'
                                : '****',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    if (widget.totalLentRemaining > 0) ...[
                      if (widget.totalBorrowedRemaining > 0)
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
                            vis
                                ? '- $symbol ${fmt.format(widget.totalLentRemaining)}'
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
    );
  }
}

// Small toggle button inside the card
class _ViewToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ViewToggle({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withOpacity(0.25)
                : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  selected ? Colors.white.withOpacity(0.6) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: Colors.white.withOpacity(selected ? 1.0 : 0.55),
                  size: 16),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(selected ? 1.0 : 0.55),
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

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

    // Loans
    final loanAsync = ref.watch(loanProvider);
    final loans = loanAsync.value ?? [];
    final totalLentRemaining = loans
        .where((l) => l.isLent && !l.isSettled)
        .fold(0.0, (sum, l) => sum + l.remaining);
    final totalBorrowedRemaining = loans
        .where((l) => !l.isLent && !l.isSettled)
        .fold(0.0, (sum, l) => sum + l.remaining);

    // Loan sectors to exclude from display totals
    const loanSectors = {
      'Loan Given',
      'Loan Received',
      'Loan Borrowed',
      'Loan Repaid',
    };

    // Full income/expense for balance calculation
    double convertedIncome = incomes.fold(
        0.0,
        (sum, i) =>
            sum +
            convertAmount(
                amount: i.amount,
                fromCurrency: i.currency,
                toCurrency: selectedCurrency,
                rates: rates));
    double convertedExpense = expenses.fold(
        0.0,
        (sum, e) =>
            sum +
            convertAmount(
                amount: e.amount,
                fromCurrency: e.currency,
                toCurrency: selectedCurrency,
                rates: rates));

    // Display totals exclude loan entries
    double displayIncome = incomes
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
    double displayExpense = expenses
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

    // Account balance
    final accountAsync = ref.watch(accountProvider);
    final accounts = accountAsync.value ?? [];
    final accountBalance = accounts.fold(0.0, (sum, a) => sum + a.balance);

    // Cash balance = income - expense (no accounts)
    final cashBalance = convertedIncome - convertedExpense - accountBalance;

    // Total = cash + accounts
    final totalBalance = cashBalance + accountBalance;

    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recent = _mergeAndSort(incomes, expenses)
        .where((t) => (t['date'] as DateTime).isAfter(oneWeekAgo))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        // ── Balance card ──────────────────────────
        _BalanceCard(
          cashBalance: cashBalance,
          accountBalance: accountBalance,
          totalBalance: totalBalance,
          displayIncome: displayIncome,
          displayExpense: displayExpense,
          totalLentRemaining: totalLentRemaining,
          totalBorrowedRemaining: totalBorrowedRemaining,
          balanceVisible: balanceVisible,
          onToggleBalance: onToggleBalance,
          symbol: symbol,
          fmt: fmt,
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
        const SizedBox(height: 12),
        Row(
          children: [
            _NavButton(
              label: 'Accounts',
              icon: Icons.account_balance_wallet,
              color: const Color(0xFF378ADD),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AccountsScreen())),
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
        const SizedBox(height: 12),

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

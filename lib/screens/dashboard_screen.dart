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
import 'current_month_summary_card.dart';

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
  final bool isMonthly;
  final DateTime? monthDate;

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
    this.isMonthly = false,
    this.monthDate,
  });

  @override
  State<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<_BalanceCard>
    with SingleTickerProviderStateMixin {
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
    String baseLabel;
    switch (_view) {
      case 1:
        baseLabel = 'Account Balance';
        break;
      case 2:
        baseLabel = 'Total Balance';
        break;
      default:
        baseLabel = 'Cash Balance';
    }

    if (widget.isMonthly) {
      return baseLabel;
    }
    return baseLabel;
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isMonthly && widget.monthDate != null)
                      Text(
                        DateFormat('MMMM yyyy').format(widget.monthDate!),
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (widget.isMonthly && widget.monthDate != null)
                      const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: Text(
                        _currentLabel,
                        key: ValueKey(_view),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: widget.isMonthly ? 13 : 14,
                          fontWeight: widget.isMonthly
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
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
            FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Text(
                  vis ? '$symbol ${fmt.format(_currentAmount)}' : '****',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: widget.isMonthly ? 28 : 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: vis ? 0 : 4,
                  ),
                ),
              ),
            ),
            SizedBox(height: widget.isMonthly ? 12 : 16),
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
            if (!widget.isMonthly &&
                (widget.totalLentRemaining > 0 ||
                    widget.totalBorrowedRemaining > 0)) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              color: selected ? Colors.white.withOpacity(0.6) : Colors.transparent,
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

// ── Collapsible Dual Balance Section ────────────────────────────────────────
class _DualBalanceSection extends StatefulWidget {
  final double allTimeCash;
  final double allTimeAccount;
  final double allTimeTotal;
  final double allTimeIncome;
  final double allTimeExpense;
  final double allTimeLentRemaining;
  final double allTimeBorrowedRemaining;

  final double monthlyCash;
  final double monthlyAccount;
  final double monthlyTotal;
  final double monthlyIncome;
  final double monthlyExpense;

  final bool balanceVisible;
  final VoidCallback onToggleBalance;
  final String symbol;
  final NumberFormat fmt;
  final DateTime selectedMonth;

  const _DualBalanceSection({
    required this.allTimeCash,
    required this.allTimeAccount,
    required this.allTimeTotal,
    required this.allTimeIncome,
    required this.allTimeExpense,
    required this.allTimeLentRemaining,
    required this.allTimeBorrowedRemaining,
    required this.monthlyCash,
    required this.monthlyAccount,
    required this.monthlyTotal,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.balanceVisible,
    required this.onToggleBalance,
    required this.symbol,
    required this.fmt,
    required this.selectedMonth,
  });

  @override
  State<_DualBalanceSection> createState() => _DualBalanceSectionState();
}

class _DualBalanceSectionState extends State<_DualBalanceSection>
    with SingleTickerProviderStateMixin {
  bool _allTimeExpanded = false;
  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnim = CurvedAnimation(
      parent: _expandCtrl,
      curve: Curves.easeInOut,
    );
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('showAllTimeBalance');
    if (saved != null && mounted) {
      setState(() {
        _allTimeExpanded = saved;
        if (_allTimeExpanded) {
          _expandCtrl.value = 1.0;
        }
      });
    }
  }

  Future<void> _savePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showAllTimeBalance', _allTimeExpanded);
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  void _toggleAllTime() {
    setState(() {
      _allTimeExpanded = !_allTimeExpanded;
      if (_allTimeExpanded) {
        _expandCtrl.forward();
      } else {
        _expandCtrl.reverse();
      }
      _savePreference();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BalanceCard(
          cashBalance: widget.monthlyCash,
          accountBalance: widget.monthlyAccount,
          totalBalance: widget.monthlyTotal,
          displayIncome: widget.monthlyIncome,
          displayExpense: widget.monthlyExpense,
          totalLentRemaining: 0,
          totalBorrowedRemaining: 0,
          balanceVisible: widget.balanceVisible,
          onToggleBalance: widget.onToggleBalance,
          symbol: widget.symbol,
          fmt: widget.fmt,
          isMonthly: true,
          monthDate: widget.selectedMonth,
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _expandAnim,
          builder: (context, child) {
            return ClipRect(
              child: Align(
                heightFactor: _expandAnim.value,
                child: child,
              ),
            );
          },
          child: Column(
            children: [
              _BalanceCard(
                cashBalance: widget.allTimeCash,
                accountBalance: widget.allTimeAccount,
                totalBalance: widget.allTimeTotal,
                displayIncome: widget.allTimeIncome,
                displayExpense: widget.allTimeExpense,
                totalLentRemaining: widget.allTimeLentRemaining,
                totalBorrowedRemaining: widget.allTimeBorrowedRemaining,
                balanceVisible: widget.balanceVisible,
                onToggleBalance: widget.onToggleBalance,
                symbol: widget.symbol,
                fmt: widget.fmt,
                isMonthly: false,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: InkWell(
            onTap: _toggleAllTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: _allTimeExpanded
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _allTimeExpanded
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedRotation(
                    turns: _allTimeExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: _allTimeExpanded
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _allTimeExpanded
                        ? 'Hide All-Time Summary'
                        : 'Show All-Time Summary',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _allTimeExpanded
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    _allTimeExpanded
                        ? Icons.visibility
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: _allTimeExpanded
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Collapsible Monthly Summary Section ────────────────────────────────────────
class _CollapsibleMonthlySummary extends StatefulWidget {
  final bool balanceVisible;

  const _CollapsibleMonthlySummary({
    required this.balanceVisible,
  });

  @override
  State<_CollapsibleMonthlySummary> createState() => _CollapsibleMonthlySummaryState();
}

class _CollapsibleMonthlySummaryState extends State<_CollapsibleMonthlySummary>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnim = CurvedAnimation(
      parent: _expandCtrl,
      curve: Curves.easeInOut,
    );
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('showMonthlySummary');
    if (saved != null && mounted) {
      setState(() {
        _isExpanded = saved;
        if (_isExpanded) {
          _expandCtrl.value = 1.0;
        }
      });
    }
  }

  Future<void> _savePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showMonthlySummary', _isExpanded);
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandCtrl.forward();
      } else {
        _expandCtrl.reverse();
      }
      _savePreference();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toggle Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: _isExpanded
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isExpanded
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: _isExpanded
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _isExpanded
                        ? 'Hide Monthly Summary'
                        : 'Show Monthly Summary',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isExpanded
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    _isExpanded
                        ? Icons.visibility
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: _isExpanded
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Collapsible Content
        AnimatedBuilder(
          animation: _expandAnim,
          builder: (context, child) {
            return ClipRect(
              child: Align(
                heightFactor: _expandAnim.value,
                child: child,
              ),
            );
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 0),
            child: CurrentMonthSummaryCard(),
          ),
        ),
      ],
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
        _DualBalanceSection(
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
        
        // ── Collapsible Monthly Summary Card ──
        _CollapsibleMonthlySummary(
          balanceVisible: balanceVisible,
        ),
            ],
          ),
        ),
        const SizedBox(height: 12),
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
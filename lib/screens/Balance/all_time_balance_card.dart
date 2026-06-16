import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BalanceCard extends StatefulWidget {
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

  const BalanceCard({
    super.key,
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
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> with SingleTickerProviderStateMixin {
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
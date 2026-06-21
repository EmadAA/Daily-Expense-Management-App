// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'all_time_balance_card.dart';

class DualBalanceSection extends StatefulWidget {
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

  const DualBalanceSection({
    super.key,
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
  State<DualBalanceSection> createState() => _DualBalanceSectionState();
}

class _DualBalanceSectionState extends State<DualBalanceSection>
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
        BalanceCard(
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
              BalanceCard(
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
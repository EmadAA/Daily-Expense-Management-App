import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/savings_goal_provider.dart';
import '../services/refresh_service.dart';
import 'expense_form_screen.dart';

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseAsync = ref.watch(expenseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => refreshAll(ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD85A30),
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExpenseFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: expenseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (expenses) {
          if (expenses.isEmpty) {
            return const Center(
              child: Text('No expenses yet. Tap + to add.'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(expenseProvider),
            child: ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return _ExpenseCard(expense: expense);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ExpenseCard extends ConsumerWidget {
  final ExpenseModel expense;
  const _ExpenseCard({required this.expense});

String _getCategoryIcon(String category) {
  switch (category) {
    case 'Food':
      return '🍔';
    case 'Groceries':
      return '🛒';
    case 'Shopping':
      return '🛍️';
    case 'Internet+Recharge':
      return '📱';
    case 'Bike':
      return '🏍️';
    case 'Car':
      return '🚗';
    case 'Gym':
      return '💪';
    case 'Medicine+Doctor':
      return '💊';
    case 'Sports':
      return '⚽';
    case 'Tour':
      return '✈️';
    case 'Clothes':
      return '👕';
    case 'Shoes':
      return '👟';
    case 'Gift':
      return '🎁';
    case 'Education':
      return '📚';
    case 'Electronics':
      return '📱';
    case 'Subscription':
      return '📺';
    case 'Study':
      return '📖';
    case 'Books':
      return '📚';
    case 'Cosmetics':
      return '💄';
    default:
      return '📌';
  }
}

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return const Color(0xFFD85A30);
      case 'Groceries':
        return const Color(0xFF378ADD);
      case 'Internet+Recharge':
        return const Color(0xFF7F77DD);
      case 'Bike':
        return const Color(0xFFEF9F27);
      case 'Car':
        return const Color(0xFFD85A30);
      case 'Gym':
        return const Color(0xFFD4537E);
      case 'Medicine+Doctor':
        return const Color(0xFFD85A30);
      case 'Sports':
        return const Color(0xFF1D9E75);
      case 'Tour':
        return const Color(0xFF378ADD);
      case 'Clothes':
        return const Color(0xFFD4537E);
      case 'Shoes':
        return const Color(0xFFEF9F27);
      case 'Gift':
        return const Color(0xFFD4537E);
      case 'Education':
        return const Color(0xFF378ADD);
      case 'Entertainment':
        return const Color(0xFF7F77DD);
      case 'Electronics':
        return const Color(0xFF378ADD);
      case 'Loan Given':
        return const Color(0xFF1D9E75);
      case 'Loan Repaid':
        return const Color(0xFFD85A30);
      case 'Savings':
        return const Color(0xFF1D9E75);
      default:
        return const Color(0xFF888780);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat('#,##0.00');
    final dateStr =
        '${expense.date.day}/${expense.date.month}/${expense.date.year}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Sector name + Category Badge ──────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    expense.sector,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(expense.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getCategoryColor(expense.category).withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getCategoryIcon(expense.category),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        expense.category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _getCategoryColor(expense.category),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Details ──────────────────────────
            if (expense.details.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                expense.details,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // ── Date ─────────────────────────────
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Amount + buttons ──────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Amount
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD85A30).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_upward_rounded,
                        color: Color(0xFFD85A30),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '৳ ${fmt.format(expense.amount)}',
                        style: const TextStyle(
                          color: Color(0xFFD85A30),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // Edit + Delete buttons
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 20, color: Colors.grey),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExpenseFormScreen(expense: expense),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: Colors.red),
                      onPressed: () => _confirmDelete(context, ref),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Delete this expense?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await ref
                          .read(expenseProvider.notifier)
                          .delete(expense.id);
                      try {
                        ref.invalidate(loanProvider);
                        ref.invalidate(savingsGoalProvider);
                      } catch (_) {}
                    },
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
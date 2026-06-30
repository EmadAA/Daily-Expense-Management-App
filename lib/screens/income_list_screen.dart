import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/income_model.dart';
import '../providers/income_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/savings_goal_provider.dart';
import '../services/refresh_service.dart';
import 'income_form_screen.dart';

class IncomeListScreen extends ConsumerWidget {
  const IncomeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(incomeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Income'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => refreshAll(ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const IncomeFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: incomeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (incomes) {
          if (incomes.isEmpty) {
            return const Center(
              child: Text('No income yet. Tap + to add.'),
            );
          }

          // Group incomes by date
          final Map<DateTime, List<IncomeModel>> groupedIncomes = {};
          for (final income in incomes) {
            final date = DateTime(
              income.date.year,
              income.date.month,
              income.date.day,
            );
            if (!groupedIncomes.containsKey(date)) {
              groupedIncomes[date] = [];
            }
            groupedIncomes[date]!.add(income);
          }

          // Sort dates in descending order (newest first)
          final sortedDates = groupedIncomes.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(incomeProvider),
            child: ListView.builder(
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final dateIncomes = groupedIncomes[date]!;

                // Sort incomes within each date (newest first by date)
                final sortedIncomes = dateIncomes.toList()
                  ..sort((a, b) => b.date.compareTo(a.date));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date header with divider
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D9E75).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              DateFormat('EEEE, d MMMM yyyy').format(date),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D9E75),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Income cards for this date
                    ...sortedIncomes.map((income) => _IncomeCard(
                      income: income,
                    )),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _IncomeCard extends ConsumerWidget {
  final IncomeModel income;
  const _IncomeCard({required this.income});

  String _getCategoryIcon(String category) {
    switch (category) {
      case 'Salary':
        return '💼';
      case 'Bonus':
        return '🎁';
      case 'Freelance Project':
        return '💻';
      case 'Business':
        return '🏢';
      case 'Gift':
        return '🎁';
      case 'Loan Borrowed':
        return '💰';
      default:
        return '📌';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Salary':
        return const Color(0xFF1D9E75);
      case 'Bonus':
        return const Color(0xFFEF9F27);
      case 'Freelance Project':
        return const Color(0xFF378ADD);
      case 'Business':
        return const Color(0xFF7F77DD);
      case 'Gift':
        return const Color(0xFFD4537E);
      case 'Loan Borrowed':
        return const Color(0xFFD85A30);
      default:
        return const Color(0xFF888780);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat('#,##0.00');

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
                    income.sector,
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
                    color: _getCategoryColor(income.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getCategoryColor(income.category).withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getCategoryIcon(income.category),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        income.category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _getCategoryColor(income.category),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Details ──────────────────────────
            if (income.details.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                income.details,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

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
                    color: const Color(0xFF1D9E75).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_downward_rounded,
                        color: Color(0xFF1D9E75),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '৳ ${fmt.format(income.amount)}',
                        style: const TextStyle(
                          color: Color(0xFF1D9E75),
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
                          builder: (_) => IncomeFormScreen(income: income),
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
              'Delete this income?',
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
                      await ref.read(incomeProvider.notifier).delete(income.id);
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
// ignore_for_file: deprecated_member_use, unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/expense_model.dart';
import '../../models/income_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/income_provider.dart';

class CurrentMonthSummaryCard extends ConsumerWidget {
  const CurrentMonthSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(incomeProvider);
    final expenseAsync = ref.watch(expenseProvider);

    return incomeAsync.when(
      loading: () => _buildLoadingCard(context),
      error: (e, _) => _buildErrorCard(context, e),
      data: (allIncomes) => expenseAsync.when(
        loading: () => _buildLoadingCard(context),
        error: (e, _) => _buildErrorCard(context, e),
        data: (allExpenses) {
          final currentMonth = DateTime.now();
          
          // Filter current month
          final monthlyIncomes = allIncomes.where((i) =>
              i.date.year == currentMonth.year &&
              i.date.month == currentMonth.month).toList();
          
          final monthlyExpenses = allExpenses.where((e) =>
              e.date.year == currentMonth.year &&
              e.date.month == currentMonth.month).toList();

          // Calculate totals
          final totalIncome = monthlyIncomes.fold(0.0, (sum, i) => sum + i.amount);
          final totalExpense = monthlyExpenses.fold(0.0, (sum, e) => sum + e.amount);
          final balance = totalIncome - totalExpense;

          // Calculate days in month
          final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
          
          // Calculate days passed in the month (today's day)
          final today = DateTime.now();
          final daysPassed = today.day;
          
          // Calculate daily average based on days passed
          final double dailyAverage = daysPassed > 0 ? totalExpense / daysPassed : 0.0;

          // Find top spending categories (top 3)
          final Map<String, double> categorySpending = {};
          for (final expense in monthlyExpenses) {
            categorySpending[expense.category] = 
                (categorySpending[expense.category] ?? 0.0) + expense.amount;
          }
          
          // Sort categories by amount (highest first) and take top 3
          final sortedCategories = categorySpending.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          
          final topCategories = sortedCategories.take(3).toList();

          // Calculate days remaining
          final daysRemaining = daysInMonth - today.day;
          
          // Calculate projected monthly expense
          final projectedExpense = dailyAverage * daysInMonth;
          
          return _buildSummaryCard(
            context: context,
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            balance: balance,
            dailyAverage: dailyAverage,
            topCategories: topCategories,
            daysRemaining: daysRemaining,
            daysInMonth: daysInMonth,
            daysPassed: daysPassed,
            projectedExpense: projectedExpense,
            transactionCount: monthlyIncomes.length + monthlyExpenses.length,
          );
        },
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, dynamic error) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Error loading summary: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required double totalIncome,
    required double totalExpense,
    required double balance,
    required double dailyAverage,
    required List<MapEntry<String, double>> topCategories,
    required int daysRemaining,
    required int daysInMonth,
    required int daysPassed,
    required double projectedExpense,
    required int transactionCount,
  }) {
    final fmt = NumberFormat('#,##0.00');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasCategories = topCategories.isNotEmpty;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1D9E75).withOpacity(0.2),
                    const Color(0xFF1D9E75).withOpacity(0.05),
                  ]
                : [
                    const Color(0xFF1D9E75).withOpacity(0.1),
                    const Color(0xFF1D9E75).withOpacity(0.02),
                  ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D9E75).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_month,
                      color: Color(0xFF1D9E75),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This Month',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          '${DateFormat('MMMM yyyy').format(DateTime.now())} · Day $daysPassed of $daysInMonth',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: transactionCount > 0
                          ? const Color(0xFF1D9E75).withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$transactionCount trx',
                      style: TextStyle(
                        fontSize: 10,
                        color: transactionCount > 0
                            ? const Color(0xFF1D9E75)
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Balance
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Net Balance',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${balance >= 0 ? '+' : ''}৳ ${fmt.format(balance)}',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: balance >= 0
                                ? const Color(0xFF1D9E75)
                                : const Color(0xFFD85A30),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.trending_down,
                      label: 'Expense',
                      value: '৳ ${fmt.format(totalExpense)}',
                      color: const Color(0xFFD85A30),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.trending_up,
                      label: 'Income',
                      value: '৳ ${fmt.format(totalIncome)}',
                      color: const Color(0xFF1D9E75),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Additional info - 2 items in a row
              Row(
                children: [
                  Expanded(
                    child: _buildInfoTile(
                      icon: Icons.analytics,
                      label: 'Daily Avg',
                      value: '৳ ${fmt.format(dailyAverage)}',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoTile(
                      icon: Icons.trending_up,
                      label: 'Estimated Month End',
                      value: '৳ ${fmt.format(projectedExpense)}',
                      isDark: isDark,
                      color: projectedExpense > totalIncome ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Days remaining row
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: daysRemaining <= 7
                              ? Colors.red
                              : isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$daysRemaining days remaining in ${DateFormat('MMMM').format(DateTime.now())}',
                          style: TextStyle(
                            fontSize: 12,
                            color: daysRemaining <= 7
                                ? Colors.red
                                : isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            fontWeight: daysRemaining <= 7 ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    if (daysRemaining > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (projectedExpense > totalIncome)
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          projectedExpense > totalIncome
                              ? '⚠️ Over budget'
                              : '✅ On track',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: projectedExpense > totalIncome
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Top 3 Expense Categories ──
              if (hasCategories) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : const Color(0xFFD85A30).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : const Color(0xFFD85A30).withOpacity(0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.trending_up_rounded,
                            size: 16,
                            color: Color(0xFFD85A30),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Top ${topCategories.length} Expense Categories',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFD85A30),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...topCategories.asMap().entries.map((entry) {
                        final index = entry.key;
                        final category = entry.value.key;
                        final amount = entry.value.value;
                        
                        // Different colors for top 3
                        final List<Color> colors = [
                          const Color(0xFFD85A30), // Red for #1
                          const Color(0xFFEF9F27), // Orange for #2
                          const Color(0xFF378ADD), // Blue for #3
                        ];
                        final Color categoryColor = colors[index % colors.length];
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: categoryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: categoryColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '৳ ${fmt.format(amount)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: categoryColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],

              if (transactionCount == 0) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'No transactions this month yet',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? (isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color ?? (isDark ? Colors.white : Colors.black87),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
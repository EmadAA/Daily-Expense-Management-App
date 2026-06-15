import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../services/refresh_service.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  late DateTime _selectedMonth;
  int _touchedIndex = -1;
  bool _showIncomeChart = false;
  String _selectedTimeRange = 'Monthly';

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _previousPeriod() {
    setState(() {
      switch (_selectedTimeRange) {
        case 'Monthly':
          _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
          break;
        case 'Quarterly':
          _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 3);
          break;
        case 'Yearly':
          _selectedMonth = DateTime(_selectedMonth.year - 1, _selectedMonth.month);
          break;
      }
      _touchedIndex = -1;
    });
  }

  void _nextPeriod() {
    setState(() {
      switch (_selectedTimeRange) {
        case 'Monthly':
          _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
          break;
        case 'Quarterly':
          _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 3);
          break;
        case 'Yearly':
          _selectedMonth = DateTime(_selectedMonth.year + 1, _selectedMonth.month);
          break;
      }
      _touchedIndex = -1;
    });
  }

  List<IncomeModel> _filterIncomes(List<IncomeModel> all) {
    switch (_selectedTimeRange) {
      case 'Monthly':
        return all.where((i) =>
            i.date.year == _selectedMonth.year &&
            i.date.month == _selectedMonth.month).toList();
      case 'Quarterly':
        final startMonth = _selectedMonth.month - 2;
        final startDate = DateTime(_selectedMonth.year, startMonth, 1);
        final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
        return all.where((i) =>
            i.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            i.date.isBefore(endDate.add(const Duration(days: 1)))).toList();
      case 'Yearly':
        return all.where((i) => i.date.year == _selectedMonth.year).toList();
      default:
        return [];
    }
  }

  List<ExpenseModel> _filterExpenses(List<ExpenseModel> all) {
    switch (_selectedTimeRange) {
      case 'Monthly':
        return all.where((e) =>
            e.date.year == _selectedMonth.year &&
            e.date.month == _selectedMonth.month).toList();
      case 'Quarterly':
        final startMonth = _selectedMonth.month - 2;
        final startDate = DateTime(_selectedMonth.year, startMonth, 1);
        final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
        return all.where((e) =>
            e.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            e.date.isBefore(endDate.add(const Duration(days: 1)))).toList();
      case 'Yearly':
        return all.where((e) => e.date.year == _selectedMonth.year).toList();
      default:
        return [];
    }
  }

  Map<String, double> _groupByCategory(List<dynamic> items) {
    final Map<String, double> result = {};
    for (final item in items) {
      final category = item.category as String;
      final amount = item.amount as double;
      result[category] = (result[category] ?? 0) + amount;
    }
    final sorted = Map.fromEntries(
      result.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    return sorted;
  }

  String _getPeriodLabel() {
    switch (_selectedTimeRange) {
      case 'Monthly':
        return DateFormat('MMMM yyyy').format(_selectedMonth);
      case 'Quarterly':
        final startMonth = _selectedMonth.month - 2;
        final start = DateFormat('MMM').format(DateTime(_selectedMonth.year, startMonth));
        final end = DateFormat('MMM yyyy').format(_selectedMonth);
        return '$start - $end';
      case 'Yearly':
        return _selectedMonth.year.toString();
      default:
        return '';
    }
  }

  static const _colors = [
    Color(0xFF1D9E75),
    Color(0xFF378ADD),
    Color(0xFFEF9F27),
    Color(0xFFD85A30),
    Color(0xFF7F77DD),
    Color(0xFF5DCAA5),
    Color(0xFFD4537E),
    Color(0xFF639922),
    Color(0xFF888780),
    Color(0xFFF0997B),
  ];

  @override
  Widget build(BuildContext context) {
    final incomeAsync = ref.watch(incomeProvider);
    final expenseAsync = ref.watch(expenseProvider);
    final periodLabel = _getPeriodLabel();
    final fmt = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Summary'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => refreshAll(ref),
          ),
        ],
      ),
      body: incomeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allIncomes) => expenseAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (allExpenses) {
            final incomes = _filterIncomes(allIncomes);
            final expenses = _filterExpenses(allExpenses);

            const loanCategories = {
              'Loan Borrowed',
              'Loan Given',
              'Loan Repaid',
              'Loan Received',
            };

            final filteredIncomes =
                incomes.where((i) => !loanCategories.contains(i.category)).toList();
            final filteredExpenses =
                expenses.where((e) => !loanCategories.contains(e.category)).toList();

            final totalIncome =
                filteredIncomes.fold(0.0, (s, i) => s + i.amount);
            final totalExpense =
                filteredExpenses.fold(0.0, (s, e) => s + e.amount);
            final balance = totalIncome - totalExpense;

            final incomeByCategory = _groupByCategory(filteredIncomes);
            final expenseByCategory = _groupByCategory(filteredExpenses);

            final hasIncomeData = incomeByCategory.isNotEmpty;
            final hasExpenseData = expenseByCategory.isNotEmpty;
            
            // Get current chart data
            final currentChartData = _showIncomeChart ? incomeByCategory : expenseByCategory;
            final hasCurrentData = currentChartData.isNotEmpty;

            return RefreshIndicator(
              onRefresh: () async {
                refreshAll(ref);
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Period Selector ──────────────────────
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Time range selector
                            Wrap(
  spacing: 8,
  runSpacing: 8,
  alignment: WrapAlignment.center,
  children: [
    for (final range in ['Monthly', 'Quarterly', 'Yearly'])
      ChoiceChip(
        label: Text(range),
        selected: _selectedTimeRange == range,
        selectedColor: Theme.of(context).colorScheme.primary,
        labelStyle: TextStyle(
          color: _selectedTimeRange == range
              ? Colors.white
              : Colors.black, // Changed from null to Colors.black
          fontSize: 13,
        ),
        onSelected: (_) {
          setState(() {
            _selectedTimeRange = range;
            _touchedIndex = -1;
          });
        },
      ),
  ],
),
                            const SizedBox(height: 16),
                            // Period navigation
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.chevron_left, size: 20),
                                  ),
                                  onPressed: _previousPeriod,
                                ),
                                Flexible(
                                  child: Text(
                                    periodLabel,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.chevron_right, size: 20),
                                  ),
                                  onPressed: _nextPeriod,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Overview Stats Card ─────────────────────
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primaryContainer,
                              Theme.of(context).colorScheme.surface,
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _OverviewRow(
                                label: 'Total Income',
                                amount: '৳ ${fmt.format(totalIncome)}',
                                color: const Color(0xFF1D9E75),
                                icon: Icons.arrow_downward_rounded,
                              ),
                              const Divider(height: 24),
                              _OverviewRow(
                                label: 'Total Expense',
                                amount: '৳ ${fmt.format(totalExpense)}',
                                color: const Color(0xFFD85A30),
                                icon: Icons.arrow_upward_rounded,
                              ),
                              const Divider(height: 24),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (balance >= 0
                                      ? const Color(0xFF1D9E75)
                                      : const Color(0xFFD85A30)).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: _OverviewRow(
                                  label: 'Net Balance',
                                  amount: '৳ ${fmt.format(balance.abs())}',
                                  color: balance >= 0
                                      ? const Color(0xFF1D9E75)
                                      : const Color(0xFFD85A30),
                                  isBold: true,
                                  prefix: balance >= 0 ? '+' : '-',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Pie Chart Section with proper empty state handling ──
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Toggle income/expense
                           Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    ChoiceChip(
      label: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_upward_rounded, size: 16),
          SizedBox(width: 4),
          Text('Expense'),
        ],
      ),
      selected: !_showIncomeChart,
      selectedColor: const Color(0xFFD85A30),
      labelStyle: TextStyle(
        color: !_showIncomeChart
            ? Colors.white
            : Colors.black, // Changed from null to Colors.black
      ),
      onSelected: (_) {
        if (hasExpenseData) {
          setState(() {
            _showIncomeChart = false;
            _touchedIndex = -1;
          });
        }
      },
    ),
    const SizedBox(width: 12),
    ChoiceChip(
      label: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_downward_rounded, size: 16),
          SizedBox(width: 4),
          Text('Income'),
        ],
      ),
      selected: _showIncomeChart,
      selectedColor: const Color(0xFF1D9E75),
      labelStyle: TextStyle(
        color: _showIncomeChart
            ? Colors.white
            : Colors.black, // Changed from null to Colors.black
      ),
      onSelected: (_) {
        if (hasIncomeData) {
          setState(() {
            _showIncomeChart = true;
            _touchedIndex = -1;
          });
        }
      },
    ),
  ],
),
                            const SizedBox(height: 24),
                            
                            // Chart or Empty State
                            if (hasCurrentData) ...[
                              SizedBox(
                                height: 250,
                                child: PieChart(
                                  PieChartData(
                                    pieTouchData: PieTouchData(
                                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                        setState(() {
                                          if (!event.isInterestedForInteractions ||
                                              pieTouchResponse == null ||
                                              pieTouchResponse.touchedSection == null) {
                                            _touchedIndex = -1;
                                            return;
                                          }
                                          _touchedIndex = pieTouchResponse
                                              .touchedSection!.touchedSectionIndex;
                                        });
                                      },
                                    ),
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 60,
                                    sections: _buildSections(currentChartData),
                                    borderData: FlBorderData(show: false),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Legend
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: currentChartData.entries.toList().asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final category = entry.value.key;
                                  final amount = entry.value.value;
                                  final total = currentChartData.values.fold(0.0, (a, b) => a + b);
                                  final percentage = total > 0 ? (amount / total * 100) : 0.0;
                                  final color = _colors[idx % _colors.length];
                                  final isTouched = idx == _touchedIndex;
                                  
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isTouched ? color.withOpacity(0.1) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          category,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isTouched ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '(${percentage.toStringAsFixed(1)}%)',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ] else ...[
                              // Empty state for chart
                              Container(
                                height: 200,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _showIncomeChart ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _showIncomeChart 
                                          ? 'No income data for this period'
                                          : 'No expense data for this period',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add some ${_showIncomeChart ? "income" : "expense"} transactions to see the chart',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
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
                    const SizedBox(height: 24),

                    // ── Income by Category ──────────────────
                    if (incomeByCategory.isNotEmpty) ...[
                      _SectionHeader(
                        label: 'Income Breakdown',
                        color: const Color(0xFF1D9E75),
                        icon: Icons.arrow_downward_rounded,
                        total: totalIncome,
                      ),
                      const SizedBox(height: 8),
                      ...incomeByCategory.entries.map(
                        (e) => _CategoryRow(
                          category: e.key,
                          amount: e.value,
                          total: totalIncome,
                          color: const Color(0xFF1D9E75),
                          bgColor: const Color(0xFFEAF3DE),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Expense by Category ─────────────────
                    if (expenseByCategory.isNotEmpty) ...[
                      _SectionHeader(
                        label: 'Expense Breakdown',
                        color: const Color(0xFFD85A30),
                        icon: Icons.arrow_upward_rounded,
                        total: totalExpense,
                      ),
                      const SizedBox(height: 8),
                      ...expenseByCategory.entries.map(
                        (e) => _CategoryRow(
                          category: e.key,
                          amount: e.value,
                          total: totalExpense,
                          color: const Color(0xFFD85A30),
                          bgColor: const Color(0xFFFAECE7),
                        ),
                      ),
                    ],

                    if (incomes.isEmpty && expenses.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            Icon(
                              Icons.insert_chart_outlined,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No transactions for this period',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add some transactions to see your summary',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections(Map<String, double> data) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    final entries = data.entries.toList();

    return entries.asMap().entries.map((entry) {
      final idx = entry.key;
      final amount = entry.value.value;
      final percent = total > 0 ? (amount / total * 100) : 0.0;
      final isTouched = idx == _touchedIndex;
      final color = _colors[idx % _colors.length];

      return PieChartSectionData(
        color: color,
        value: amount,
        title: percent > 5 ? '${percent.toStringAsFixed(1)}%' : '',
        radius: isTouched ? 70 : 60,
        titleStyle: TextStyle(
          fontSize: isTouched ? 13 : 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        showTitle: true,
      );
    }).toList();
  }
}

class _OverviewRow extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final bool isBold;
  final IconData? icon;
  final String? prefix;

  const _OverviewRow({
    required this.label,
    required this.amount,
    required this.color,
    this.isBold = false,
    this.icon,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: isBold ? 16 : 15,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          '${prefix ?? ''}$amount',
          style: TextStyle(
            color: color,
            fontSize: isBold ? 20 : 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final double total;

  const _SectionHeader({
    required this.label,
    required this.color,
    required this.icon,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Total: ৳ ${fmt.format(total)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String category;
  final double amount;
  final double total;
  final Color color;
  final Color bgColor;

  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.total,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final percentage = total > 0 ? (amount / total) : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            category.isNotEmpty ? category[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: color,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '৳ ${fmt.format(amount)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(percentage * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: bgColor,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
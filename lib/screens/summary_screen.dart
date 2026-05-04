import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  late DateTime _selectedMonth;
  int _touchedIndex = -1;
  bool _showIncomeChart = false; // toggle between income/expense pie

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _previousMonth() => setState(() {
        _selectedMonth =
            DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _selectedMonth =
            DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      });

  List<IncomeModel> _filterIncomes(List<IncomeModel> all) => all
      .where((i) =>
          i.date.year == _selectedMonth.year &&
          i.date.month == _selectedMonth.month)
      .toList();

  List<ExpenseModel> _filterExpenses(List<ExpenseModel> all) => all
      .where((e) =>
          e.date.year == _selectedMonth.year &&
          e.date.month == _selectedMonth.month)
      .toList();

  Map<String, double> _groupBySector(List<dynamic> items) {
    final Map<String, double> result = {};
    for (final item in items) {
      final sector = item.sector as String;
      final amount = item.amount as double;
      result[sector] = (result[sector] ?? 0) + amount;
    }
    final sorted = Map.fromEntries(
      result.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    return sorted;
  }

  // Color palette for pie slices
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
    Color(0xFFD85A30),
  ];

  @override
  Widget build(BuildContext context) {
    final incomeAsync = ref.watch(incomeProvider);
    final expenseAsync = ref.watch(expenseProvider);
    final monthLabel = DateFormat('MMMM yyyy').format(_selectedMonth);
    final fmt = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Summary')),
      body: incomeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allIncomes) => expenseAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (allExpenses) {
            final incomes = _filterIncomes(allIncomes);
            final expenses = _filterExpenses(allExpenses);

            const loanSectors = {
              'Loan Given',
              'Loan Received',
              'Loan Borrowed',
              'Loan Repaid',
            };

// Filter out loan sectors from summary display
            final filteredIncomes =
                incomes.where((i) => !loanSectors.contains(i.sector)).toList();
            final filteredExpenses =
                expenses.where((e) => !loanSectors.contains(e.sector)).toList();

            final totalIncome =
                filteredIncomes.fold(0.0, (s, i) => s + i.amount);
            final totalExpense =
                filteredExpenses.fold(0.0, (s, e) => s + e.amount);
            final balance = totalIncome - totalExpense;

            final incomeBySector = _groupBySector(filteredIncomes);
            final expenseBySector = _groupBySector(filteredExpenses);

            final chartData =
                _showIncomeChart ? incomeBySector : expenseBySector;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Month picker ──────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _previousMonth,
                    ),
                    Text(monthLabel,
                        style: Theme.of(context).textTheme.titleLarge),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Overview card ─────────────────────
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _OverviewRow(
                          label: 'Total Income',
                          amount: '৳ ${fmt.format(totalIncome)}',
                          color: const Color(0xFF1D9E75),
                        ),
                        const Divider(height: 24),
                        _OverviewRow(
                          label: 'Total Expense',
                          amount: '৳ ${fmt.format(totalExpense)}',
                          color: const Color(0xFFD85A30),
                        ),
                        const Divider(height: 24),
                        _OverviewRow(
                          label: 'Balance',
                          amount: '৳ ${fmt.format(balance)}',
                          color: balance >= 0
                              ? const Color(0xFF1D9E75)
                              : const Color(0xFFD85A30),
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Pie chart ─────────────────────────
                if (chartData.isNotEmpty) ...[
                  // Toggle income / expense
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('Expense'),
                        selected: !_showIncomeChart,
                        selectedColor: const Color(0xFFD85A30),
                        labelStyle: TextStyle(
                          color: !_showIncomeChart ? Colors.white : null,
                        ),
                        onSelected: (_) => setState(() {
                          _showIncomeChart = false;
                          _touchedIndex = -1;
                        }),
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('Income'),
                        selected: _showIncomeChart,
                        selectedColor: const Color(0xFF1D9E75),
                        labelStyle: TextStyle(
                          color: _showIncomeChart ? Colors.white : null,
                        ),
                        onSelected: (_) => setState(() {
                          _showIncomeChart = true;
                          _touchedIndex = -1;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Pie chart
                  SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
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
                        centerSpaceRadius: 48,
                        sections: _buildSections(chartData),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Legend
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children:
                        chartData.entries.toList().asMap().entries.map((entry) {
                      final idx = entry.key;
                      final sector = entry.value.key;
                      final color = _colors[idx % _colors.length];
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(sector, style: const TextStyle(fontSize: 12)),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Income by sector ──────────────────
                if (incomeBySector.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'Income by Sector',
                    color: const Color(0xFF1D9E75),
                    icon: Icons.arrow_downward_rounded,
                  ),
                  const SizedBox(height: 8),
                  ...incomeBySector.entries.map(
                    (e) => _SectorRow(
                      sector: e.key,
                      amount: e.value,
                      total: totalIncome,
                      color: const Color(0xFF1D9E75),
                      bgColor: const Color(0xFFEAF3DE),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Expense by sector ─────────────────
                if (expenseBySector.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'Expense by Sector',
                    color: const Color(0xFFD85A30),
                    icon: Icons.arrow_upward_rounded,
                  ),
                  const SizedBox(height: 8),
                  ...expenseBySector.entries.map(
                    (e) => _SectorRow(
                      sector: e.key,
                      amount: e.value,
                      total: totalExpense,
                      color: const Color(0xFFD85A30),
                      bgColor: const Color(0xFFFAECE7),
                    ),
                  ),
                ],

                if (incomes.isEmpty && expenses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child:
                        Center(child: Text('No transactions for this month.')),
                  ),

                const SizedBox(height: 32),
              ],
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
        title: '${percent.toStringAsFixed(1)}%',
        radius: isTouched ? 65 : 55,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}

// ── Small widgets (same as before) ────────────────────

class _OverviewRow extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final bool isBold;

  const _OverviewRow({
    required this.label,
    required this.amount,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            )),
        Text(amount,
            style: TextStyle(
              color: color,
              fontSize: isBold ? 18 : 15,
              fontWeight: FontWeight.bold,
            )),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _SectionHeader({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            )),
      ],
    );
  }
}

class _SectorRow extends StatelessWidget {
  final String sector;
  final double amount;
  final double total;
  final Color color;
  final Color bgColor;

  const _SectorRow({
    required this.sector,
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: bgColor,
                      child: Text(
                        sector[0].toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(sector,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('৳ ${fmt.format(amount)}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        )),
                    Text('${(percentage * 100).toStringAsFixed(1)}%',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: bgColor,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final _sectorCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _sectorCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _showAddDialog({String? existingSector, double? existingAmount}) {
    _sectorCtrl.text = existingSector ?? '';
    _amountCtrl.text = existingAmount != null ? existingAmount.toString() : '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:
            Text(existingSector != null ? 'Edit Budget' : 'Set Budget Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _sectorCtrl,
              readOnly: existingSector != null,
              decoration: const InputDecoration(
                labelText: 'Sector name',
                hintText: 'e.g. Food, Transport',
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monthly limit (৳)',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _sectorCtrl.clear();
              _amountCtrl.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_sectorCtrl.text.trim().isEmpty ||
                  _amountCtrl.text.trim().isEmpty) return;
              final amount = double.tryParse(_amountCtrl.text.trim());
              if (amount == null || amount <= 0) return;

              await ref.read(budgetProvider.notifier).upsert(
                    _sectorCtrl.text.trim(),
                    amount,
                  );
              if (mounted) {
                _sectorCtrl.clear();
                _amountCtrl.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetAsync = ref.watch(budgetProvider);
    final expenseAsync = ref.watch(expenseProvider);
    final fmt = NumberFormat('#,##0.00');
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Budget Limits')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
      body: budgetAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (budgets) => expenseAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (expenses) {
            if (budgets.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        size: 64, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 16),
                    const Text('No budget limits set yet.'),
                    const SizedBox(height: 8),
                    const Text('Tap + to add one.',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            // Calculate this month's spending per sector
            final thisMonthExpenses = expenses.where(
                (e) => e.date.year == now.year && e.date.month == now.month);

            final Map<String, double> spent = {};
            for (final e in thisMonthExpenses) {
              spent[e.sector] = (spent[e.sector] ?? 0) + e.amount;
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'This month\'s budget status',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 12),
                ...budgets.entries.map((entry) {
                  final sector = entry.key;
                  final limit = entry.value;
                  final used = spent[sector] ?? 0.0;
                  final percent = limit > 0 ? (used / limit) : 0.0;

                  Color statusColor;
                  String statusLabel;
                  if (percent >= 1.0) {
                    statusColor = Colors.red;
                    statusLabel = 'Exceeded!';
                  } else if (percent >= 0.8) {
                    statusColor = Colors.orange;
                    statusLabel = 'Near limit';
                  } else {
                    statusColor = const Color(0xFF1D9E75);
                    statusLabel = 'On track';
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(sector,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(statusLabel,
                                        style: TextStyle(
                                            color: statusColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18),
                                    onPressed: () => _showAddDialog(
                                      existingSector: sector,
                                      existingAmount: limit,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18, color: Colors.red),
                                    onPressed: () async {
                                      await ref
                                          .read(budgetProvider.notifier)
                                          .delete(sector);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '৳ ${fmt.format(used)} spent',
                                style:
                                    TextStyle(color: statusColor, fontSize: 13),
                              ),
                              Text(
                                'Limit: ৳ ${fmt.format(limit)}',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percent.clamp(0.0, 1.0),
                              backgroundColor: statusColor.withOpacity(0.1),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(statusColor),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(percent * 100).clamp(0, 100).toStringAsFixed(1)}% used  ·  ৳ ${fmt.format((limit - used).clamp(0, double.infinity))} remaining',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

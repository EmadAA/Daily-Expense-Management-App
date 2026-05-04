import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/recurring_model.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/recurring_provider.dart';

class RecurringScreen extends ConsumerStatefulWidget {
  const RecurringScreen({super.key});

  @override
  ConsumerState<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends ConsumerState<RecurringScreen> {
  final _sectorCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _type = 'expense';
  int _dayOfMonth = 1;

  @override
  void dispose() {
    _sectorCtrl.dispose();
    _detailsCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    _sectorCtrl.clear();
    _detailsCtrl.clear();
    _amountCtrl.clear();
    _type = 'expense';
    _dayOfMonth = 1;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Add Recurring'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Type toggle
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Expense'),
                        selected: _type == 'expense',
                        selectedColor: const Color(0xFFD85A30),
                        labelStyle: TextStyle(
                          color: _type == 'expense' ? Colors.white : null,
                        ),
                        onSelected: (_) => setInner(() => _type = 'expense'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Income'),
                        selected: _type == 'income',
                        selectedColor: const Color(0xFF1D9E75),
                        labelStyle: TextStyle(
                          color: _type == 'income' ? Colors.white : null,
                        ),
                        onSelected: (_) => setInner(() => _type = 'income'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _sectorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Sector name',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _detailsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Details (optional)',
                    prefixIcon: Icon(Icons.edit_note_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount (৳)',
                    prefixIcon: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Text('৳',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Day of month picker
                Row(
                  children: [
                    const Text('Day of month:', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<int>(
                        value: _dayOfMonth,
                        isExpanded: true,
                        items: List.generate(28, (i) => i + 1)
                            .map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text('$d'),
                                ))
                            .toList(),
                        onChanged: (v) => setInner(() => _dayOfMonth = v!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_sectorCtrl.text.trim().isEmpty ||
                    _amountCtrl.text.trim().isEmpty) return;
                final amount = double.tryParse(_amountCtrl.text.trim());
                if (amount == null || amount <= 0) return;

                await ref.read(recurringProvider.notifier).add(
                      RecurringModel(
                        id: '',
                        type: _type,
                        sector: _sectorCtrl.text.trim(),
                        details: _detailsCtrl.text.trim(),
                        amount: amount,
                        dayOfMonth: _dayOfMonth,
                      ),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recurringAsync = ref.watch(recurringProvider);
    final fmt = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Transactions'),
        actions: [
          // Manual process button
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Process due now',
            onPressed: () async {
              await ref.read(recurringProvider.notifier).processDue();
              ref.invalidate(incomeProvider);
              ref.invalidate(expenseProvider);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Recurring transactions processed!')),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: recurringAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.repeat,
                      size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  const Text('No recurring transactions yet.'),
                  const SizedBox(height: 8),
                  const Text('Tap + to add one.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final r = list[index];
              final isIncome = r.type == 'income';
              final color =
                  isIncome ? const Color(0xFF1D9E75) : const Color(0xFFD85A30);
              final bgColor =
                  isIncome ? const Color(0xFFEAF3DE) : const Color(0xFFFAECE7);

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: bgColor,
                    child: Icon(Icons.repeat, color: color, size: 18),
                  ),
                  title: Text(r.sector,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (r.details.isNotEmpty)
                        Text(r.details, style: const TextStyle(fontSize: 12)),
                      Text(
                        'Every month on day ${r.dayOfMonth}',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      if (r.lastAdded != null)
                        Text(
                          'Last added: ${r.lastAdded!.day}/${r.lastAdded!.month}/${r.lastAdded!.year}',
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${isIncome ? '+' : '-'} ৳ ${fmt.format(r.amount)}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                        onPressed: () async {
                          await ref
                              .read(recurringProvider.notifier)
                              .delete(r.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

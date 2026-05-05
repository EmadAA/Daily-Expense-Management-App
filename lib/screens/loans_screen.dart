import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../models/loan_model.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/loan_provider.dart';
import '../services/refresh_service.dart';

class LoansScreen extends ConsumerStatefulWidget {
  const LoansScreen({super.key});

  @override
  ConsumerState<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends ConsumerState<LoansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _paidCtrl = TextEditingController();
  String _type = 'borrowed';
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _paidCtrl.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    _nameCtrl.clear();
    _amountCtrl.clear();
    _noteCtrl.clear();
    _type = 'borrowed';
    _dueDate = null;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Add Loan / Debt'),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Type toggle
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('I Borrowed'),
                        selected: _type == 'borrowed',
                        selectedColor: const Color(0xFFD85A30),
                        labelStyle: TextStyle(
                          color: _type == 'borrowed' ? Colors.white : null,
                        ),
                        onSelected: (_) => setInner(() => _type = 'borrowed'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('I Lent'),
                        selected: _type == 'lent',
                        selectedColor: const Color(0xFF1D9E75),
                        labelStyle: TextStyle(
                          color: _type == 'lent' ? Colors.white : null,
                        ),
                        onSelected: (_) => setInner(() => _type = 'lent'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: _type == 'lent'
                        ? 'Lent to (name)'
                        : 'Borrowed from (name)',
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),

                // Amount
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
                const SizedBox(height: 16),

                // Note
                TextField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    prefixIcon: Icon(Icons.edit_note_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Due date
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setInner(() => _dueDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Due date (optional)',
                      prefixIcon: Icon(Icons.date_range_outlined),
                    ),
                    child: Text(
                      _dueDate != null
                          ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                          : 'No due date',
                      style: TextStyle(
                        color: _dueDate != null
                            ? null
                            : Theme.of(ctx).colorScheme.outline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
                if (_nameCtrl.text.trim().isEmpty ||
                    _amountCtrl.text.trim().isEmpty) return;
                final amount = double.tryParse(_amountCtrl.text.trim());
                if (amount == null || amount <= 0) return;

                // Close dialog FIRST before any async work
                Navigator.pop(context);

                final loan = LoanModel(
                  id: '',
                  type: _type,
                  personName: _nameCtrl.text.trim(),
                  amount: amount,
                  paidAmount: 0,
                  dueDate: _dueDate,
                  note: _noteCtrl.text.trim(),
                  createdAt: DateTime.now(),
                );

                final loanId = await ref.read(loanProvider.notifier).add(loan);

                if (_type == 'lent') {
                  await ref.read(expenseProvider.notifier).add(
                        ExpenseModel(
                          id: '',
                          sector: 'Loan Given',
                          details: 'Lent to ${_nameCtrl.text.trim()}'
                              '${_noteCtrl.text.trim().isNotEmpty ? ' — ${_noteCtrl.text.trim()}' : ''}',
                          amount: amount,
                          date: DateTime.now(),
                          currency: 'BDT',
                          sourceType: 'loan',
                          sourceId: loanId,
                        ),
                      );
                } else {
                  await ref.read(incomeProvider.notifier).add(
                        IncomeModel(
                          id: '',
                          sector: 'Loan Borrowed',
                          details: 'Borrowed from ${_nameCtrl.text.trim()}'
                              '${_noteCtrl.text.trim().isNotEmpty ? ' — ${_noteCtrl.text.trim()}' : ''}',
                          amount: amount,
                          date: DateTime.now(),
                          currency: 'BDT',
                          sourceType: 'loan',
                          sourceId: loanId,
                        ),
                      );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMarkPaidDialog(LoanModel loan) {
    _paidCtrl.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:
            Text(loan.isLent ? '${loan.personName} paid back' : 'I paid back'),
        content: TextField(
          controller: _paidCtrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText:
                'Amount (remaining: ৳ ${NumberFormat('#,##0.00').format(loan.remaining)})',
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text('৳',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(_paidCtrl.text.trim());
              if (amount == null || amount <= 0) return;

              // Close dialog FIRST before any async work
              Navigator.pop(context);

              await ref.read(loanProvider.notifier).markPaid(loan.id, amount);

              if (loan.isLent) {
                await ref.read(incomeProvider.notifier).add(
                      IncomeModel(
                        id: '',
                        sector: 'Loan Received',
                        details: 'Paid back by ${loan.personName}',
                        amount: amount,
                        date: DateTime.now(),
                        currency: 'BDT',
                        sourceType: 'loan_repayment',
                        sourceId: loan.id,
                      ),
                    );
              } else {
                await ref.read(expenseProvider.notifier).add(
                      ExpenseModel(
                        id: '',
                        sector: 'Loan Repaid',
                        details: 'Paid back to ${loan.personName}',
                        amount: amount,
                        date: DateTime.now(),
                        currency: 'BDT',
                        sourceType: 'loan_repayment',
                        sourceId: loan.id,
                      ),
                    );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanCard(LoanModel loan) {
    final fmt = NumberFormat('#,##0.00');
    final isLent = loan.isLent;
    final color = isLent ? const Color(0xFF1D9E75) : const Color(0xFFD85A30);
    final bgColor = isLent ? const Color(0xFFEAF3DE) : const Color(0xFFFAECE7);
    final percentage =
        loan.amount > 0 ? (loan.paidAmount / loan.amount).clamp(0.0, 1.0) : 0.0;

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
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: bgColor,
                      child: Text(
                        loan.personName[0].toUpperCase(),
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loan.personName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        Text(
                          isLent ? 'I lent' : 'I borrowed',
                          style: TextStyle(color: color, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (loan.isSettled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D9E75).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Settled',
                            style: TextStyle(
                                color: Color(0xFF1D9E75),
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 20),
                      onPressed: () async {
                        await ref.read(loanProvider.notifier).delete(loan.id);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '৳ ${fmt.format(loan.amount)}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Remaining: ৳ ${fmt.format(loan.remaining)}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
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
            if (loan.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(loan.note,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
            if (loan.dueDate != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 12,
                    color: loan.daysUntilDue != null && loan.daysUntilDue! <= 3
                        ? Colors.red
                        : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${loan.dueDate!.day}/${loan.dueDate!.month}/${loan.dueDate!.year}'
                    '${loan.daysUntilDue != null ? "  (${loan.daysUntilDue! > 0 ? '${loan.daysUntilDue} days left' : 'Overdue!'})" : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          loan.daysUntilDue != null && loan.daysUntilDue! <= 3
                              ? Colors.red
                              : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
            if (!loan.isSettled) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showMarkPaidDialog(loan),
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(isLent ? 'Mark as received' : 'Mark as paid'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loanAsync = ref.watch(loanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans & Debts'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'I Borrowed'),
            Tab(text: 'I Lent'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => refreshAll(ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: loanAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (loans) {
          final borrowed = loans.where((l) => l.type == 'borrowed').toList();
          final lent = loans.where((l) => l.type == 'lent').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              borrowed.isEmpty
                  ? const Center(child: Text('No borrowed records.'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: borrowed.map(_buildLoanCard).toList(),
                    ),
              lent.isEmpty
                  ? const Center(child: Text('No lent records.'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: lent.map(_buildLoanCard).toList(),
                    ),
            ],
          );
        },
      ),
    );
  }
}

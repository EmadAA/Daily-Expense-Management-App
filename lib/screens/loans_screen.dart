// ignore_for_file: unused_element, deprecated_member_use

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
    _tabController = TabController(length: 3, vsync: this);
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

  Color _parseColor(String hex) =>
      Color(int.parse(hex.replaceFirst('#', '0xFF')));

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMMM d, yyyy').format(date);
    }
  }

  List<Widget> _buildGroupedLoanList(List<LoanModel> loans) {
    if (loans.isEmpty) return [];

    // Group loans by date
    final Map<String, List<LoanModel>> groupedLoans = {};

    for (final loan in loans) {
      final dateKey = DateFormat('yyyy-MM-dd').format(loan.createdAt);
      if (!groupedLoans.containsKey(dateKey)) {
        groupedLoans[dateKey] = [];
      }
      groupedLoans[dateKey]!.add(loan);
    }

    // Sort dates
    final sortedDates = groupedLoans.keys.toList()
      ..sort((a, b) {
        return b.compareTo(a); // Newest first
      });

    final List<Widget> widgets = [];

    for (final dateKey in sortedDates) {
      final date = DateTime.parse(dateKey);
      final formattedDate = _getFormattedDate(date);
      final loansOnDate = groupedLoans[dateKey]!;

      // Add date divider
      widgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${loansOnDate.length} item${loansOnDate.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      // Add loans for this date
      for (final loan in loansOnDate) {
        widgets.add(_buildLoanCard(loan));
      }
    }

    return widgets;
  }

  void _showAddDialog() {
    _nameCtrl.clear();
    _amountCtrl.clear();
    _noteCtrl.clear();
    _type = 'borrowed';
    _dueDate = null;

    showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: BoxDecoration(
                color: Theme.of(context).dialogBackgroundColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Add Loan / Debt',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Track money you borrowed or lent to others.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setInner(() => _type = 'borrowed'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _type == 'borrowed'
                                    ? const Color(0xFFD85A30)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_type == 'borrowed')
                                    const Icon(Icons.check,
                                        color: Colors.white, size: 18),
                                  if (_type == 'borrowed')
                                    const SizedBox(width: 6),
                                  Text(
                                    'I Borrowed',
                                    style: TextStyle(
                                      color: _type == 'borrowed'
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                      fontWeight: _type == 'borrowed'
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setInner(() => _type = 'lent'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _type == 'lent'
                                    ? const Color(0xFF1D9E75)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_type == 'lent')
                                    const Icon(Icons.check,
                                        color: Colors.white, size: 18),
                                  if (_type == 'lent') const SizedBox(width: 6),
                                  Text(
                                    'I Lent',
                                    style: TextStyle(
                                      color: _type == 'lent'
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                      fontWeight: _type == 'lent'
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: _type == 'lent'
                            ? 'Lent to (name)'
                            : 'Borrowed from (name)',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount (৳)',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Text('৳',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _noteCtrl,
                      decoration: InputDecoration(
                        labelText: 'Note (optional)',
                        prefixIcon: const Icon(Icons.edit_note_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate:
                              DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setInner(() => _dueDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Due date (optional)',
                          prefixIcon: const Icon(Icons.date_range_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
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
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_nameCtrl.text.trim().isEmpty ||
                              _amountCtrl.text.trim().isEmpty) return;
                          final amount =
                              double.tryParse(_amountCtrl.text.trim());
                          if (amount == null || amount <= 0) return;

                          Navigator.pop(ctx);

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

                          final loanId =
                              await ref.read(loanProvider.notifier).add(loan);

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
                                    details:
                                        'Borrowed from ${_nameCtrl.text.trim()}'
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
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: _type == 'lent'
                              ? const Color(0xFF1D9E75)
                              : const Color(0xFFD85A30),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMarkPaidDialog(LoanModel loan) {
    _paidCtrl.clear();
    showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            decoration: BoxDecoration(
              color: Theme.of(context).dialogBackgroundColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          loan.isLent ? 'Receive Payment' : 'Make Payment',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_outlined),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loan.isLent
                        ? '${loan.personName} paying back'
                        : 'Paying back to ${loan.personName}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (loan.isLent
                              ? const Color(0xFF1D9E75)
                              : const Color(0xFFD85A30))
                          .withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: loan.isLent
                              ? const Color(0xFF1D9E75)
                              : const Color(0xFFD85A30),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Remaining: ৳ ${NumberFormat('#,##0.00').format(loan.remaining)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: loan.isLent
                                  ? const Color(0xFF1D9E75)
                                  : const Color(0xFFD85A30),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _paidCtrl,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount (৳)',
                      prefixIcon: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Text('৳',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final amount = double.tryParse(_paidCtrl.text.trim());
                        if (amount == null || amount <= 0) return;

                        Navigator.pop(ctx);

                        await ref
                            .read(loanProvider.notifier)
                            .markPaid(loan.id, amount);

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
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: loan.isLent
                            ? const Color(0xFF1D9E75)
                            : const Color(0xFFD85A30),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: bgColor,
                  child: Text(
                    loan.personName[0].toUpperCase(),
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.personName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isLent ? 'I lent' : 'I borrowed',
                        style: TextStyle(color: color, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
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
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Record'),
                            content: Text(
                              'Delete ${loan.isLent ? 'lent' : 'borrowed'} record for ${loan.personName}?\n\nThis will also remove related transactions.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await ref.read(loanProvider.notifier).delete(loan.id);
                        }
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
                Expanded(
                  child: Text(
                    '৳ ${fmt.format(loan.amount)}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Remaining: ৳ ${fmt.format(loan.remaining)}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
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
              Text(
                loan.note,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (loan.dueDate != null && !loan.isSettled) ...[
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
                  Expanded(
                    child: Text(
                      'Due: ${loan.dueDate!.day}/${loan.dueDate!.month}/${loan.dueDate!.year}'
                      '${loan.daysUntilDue != null ? "  (${loan.daysUntilDue! > 0 ? '${loan.daysUntilDue} days left' : 'Overdue!'})" : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            loan.daysUntilDue != null && loan.daysUntilDue! <= 3
                                ? Colors.red
                                : Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (loan.dueDate != null && loan.isSettled) ...[
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 12,
                    color: Colors.green,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Settled on time',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green,
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
            Tab(text: 'Settled'),
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
          final borrowed =
              loans.where((l) => l.type == 'borrowed' && !l.isSettled).toList();
          final lent =
              loans.where((l) => l.type == 'lent' && !l.isSettled).toList();
          final settled = loans.where((l) => l.isSettled).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // I Borrowed Tab
              borrowed.isEmpty
                  ? const Center(child: Text('No borrowed records.'))
                  : ListView(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      children: _buildGroupedLoanList(borrowed),
                    ),

              // I Lent Tab
              lent.isEmpty
                  ? const Center(child: Text('No lent records.'))
                  : ListView(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      children: _buildGroupedLoanList(lent),
                    ),

              // Settled Tab
              settled.isEmpty
                  ? const Center(child: Text('No settled records.'))
                  : ListView(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      children: _buildGroupedLoanList(settled),
                    ),
            ],
          );
        },
      ),
    );
  }
}

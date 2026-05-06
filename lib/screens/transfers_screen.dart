import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/account_model.dart';
import '../providers/account_provider.dart';
import '../providers/transfer_provider.dart';
import '../services/refresh_service.dart';

class TransfersScreen extends ConsumerStatefulWidget {
  const TransfersScreen({super.key});

  @override
  ConsumerState<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends ConsumerState<TransfersScreen> {
  final _noteCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _fromAccountId;
  String? _toAccountId;

  @override
  void dispose() {
    _noteCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  /// ✅ Check if user has enough accounts to transfer
  bool _canTransfer(AsyncValue<List<AccountModel>> accountsAsync) {
    return accountsAsync.when(
      data: (accounts) => accounts.length >= 2,
      loading: () => false,
      error: (_, __) => false,
    );
  }

  /// 🚫 Show alert when transfer is not possible
  void _showInsufficientAccountsAlert() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon:
            const Icon(Icons.info_outline, color: Color(0xFF378ADD), size: 48),
        title: const Text('Need More Accounts'),
        content: const Text(
          'To transfer money, you need at least 2 accounts.\n\nGo to Accounts page and create another one first.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to Accounts
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create Account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF378ADD),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 🚨 Show friendly alert for insufficient balance
  void _showInsufficientBalanceAlert(
      String accountName, double balance, double requested) {
    final fmt = NumberFormat('#,##0.00');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.warning_amber_rounded,
            color: Color(0xFFD85A30), size: 48),
        title: const Text('Insufficient Balance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You cannot transfer more than what\'s available in "$accountName".',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Available:', style: TextStyle(fontSize: 13)),
                      Text('৳ ${fmt.format(balance)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D9E75))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Requested:', style: TextStyle(fontSize: 13)),
                      Text('৳ ${fmt.format(requested)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD85A30))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Short by:', style: TextStyle(fontSize: 13)),
                      Text('৳ ${fmt.format(requested - balance)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK, I understand'),
          ),
        ],
      ),
    );
  }

  void _showTransferDialog() {
    // ✅ Validate account count BEFORE opening dialog
    final accountsAsync = ref.read(accountProvider);
    if (!_canTransfer(accountsAsync)) {
      _showInsufficientAccountsAlert();
      return;
    }

    _noteCtrl.clear();
    _amountCtrl.clear();
    _selectedDate = DateTime.now();
    _fromAccountId = null;
    _toAccountId = null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Transfer Between Accounts'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _fromAccountId,
                  decoration: const InputDecoration(
                      labelText: 'From Account',
                      prefixIcon: Icon(Icons.arrow_upward_rounded)),
                  items: _buildAccountDropdownItems(ref),
                  onChanged: (v) {
                    setInner(() => _fromAccountId = v);
                    if (_toAccountId == v) setInner(() => _toAccountId = null);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _toAccountId,
                  decoration: const InputDecoration(
                      labelText: 'To Account',
                      prefixIcon: Icon(Icons.arrow_downward_rounded)),
                  items: _buildAccountDropdownItems(ref,
                      excludeId: _fromAccountId),
                  onChanged: (v) => setInner(() => _toAccountId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Amount (৳)',
                      prefixIcon: Icon(Icons.monetization_on_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      prefixIcon: Icon(Icons.note_outlined)),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                        context: ctx,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100));
                    if (picked != null) setInner(() => _selectedDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today_outlined)),
                    child: Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (_fromAccountId == null || _toAccountId == null) return;
                final amount = double.tryParse(_amountCtrl.text.trim());
                if (amount == null || amount <= 0) return;

                // ✅ Pre-check balance before attempting transfer
                final accounts = ref.read(accountProvider).value ?? [];
                final fromAccount = accounts.firstWhere(
                  (a) => a.id == _fromAccountId,
                  orElse: () => AccountModel(
                      id: '', name: '', balance: 0, createdAt: DateTime.now()),
                );

                if (amount > fromAccount.balance) {
                  Navigator.pop(ctx); // Close dialog first
                  _showInsufficientBalanceAlert(
                    fromAccount.name,
                    fromAccount.balance,
                    amount,
                  );
                  return;
                }

                Navigator.pop(ctx);
                try {
                  await ref.read(transferProvider.notifier).transfer(
                        fromAccountId: _fromAccountId!,
                        toAccountId: _toAccountId!,
                        amount: amount,
                        note: _noteCtrl.text.trim(),
                        date: _selectedDate,
                      );
                  // Refresh accounts to show updated balances immediately
                  ref.invalidate(accountProvider);
                } catch (e) {
                  if (ctx.mounted) {
                    // Fallback for any other unexpected errors
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Transfer'),
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildAccountDropdownItems(WidgetRef ref,
      {String? excludeId}) {
    final accountsAsync = ref.watch(accountProvider);
    return accountsAsync.when(
      data: (accounts) => accounts
          .where((a) => a.id != excludeId)
          .map((a) => DropdownMenuItem(
              value: a.id,
              child: Text(
                  '${a.name} (৳ ${NumberFormat('#,##0.00').format(a.balance)})')))
          .toList(),
      loading: () => [
        const DropdownMenuItem(value: '', child: Text('Loading accounts...'))
      ],
      error: (_, __) =>
          [const DropdownMenuItem(value: '', child: Text('No accounts found'))],
    );
  }

  @override
  Widget build(BuildContext context) {
    final transferAsync = ref.watch(transferProvider);
    final accountsAsync = ref.watch(accountProvider);
    final fmt = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer History'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: () => refreshAll(ref))
        ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            // ✅ Check account count on FAB tap too
            if (!_canTransfer(accountsAsync)) {
              _showInsufficientAccountsAlert();
              return;
            }
            _showTransferDialog();
          },
          child: const Icon(Icons.swap_horiz)),
      body: transferAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (transfers) {
          if (transfers.isEmpty) {
            return Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Icon(Icons.swap_horiz,
                      size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  const Text('No transfers yet.'),
                  const SizedBox(height: 8),
                  const Text('Tap + to move money between accounts.',
                      style: TextStyle(color: Colors.grey)),
                ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transfers.length,
            itemBuilder: (context, index) {
              final t = transfers[index];
              final accountsAsync = ref.watch(accountProvider);
              return accountsAsync.when(
                data: (accounts) {
                  final fromAcc = accounts.firstWhere(
                      (a) => a.id == t.fromAccountId,
                      orElse: () => AccountModel(
                          id: '',
                          name: 'Unknown',
                          balance: 0.0,
                          createdAt: DateTime.now()));
                  final toAcc = accounts.firstWhere(
                      (a) => a.id == t.toAccountId,
                      orElse: () => AccountModel(
                          id: '',
                          name: 'Unknown',
                          balance: 0.0,
                          createdAt: DateTime.now()));
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                          backgroundColor:
                              const Color(0xFF378ADD).withOpacity(0.15),
                          child: const Icon(Icons.swap_horiz,
                              color: Color(0xFF378ADD))),
                      title: Text('${fromAcc.name} → ${toAcc.name}'),
                      subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (t.note.isNotEmpty)
                              Text(t.note,
                                  style: const TextStyle(fontSize: 12)),
                            Text('${t.date.day}/${t.date.month}/${t.date.year}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          ]),
                      isThreeLine: t.note.isNotEmpty,
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('৳ ${fmt.format(t.amount)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF378ADD))),
                        IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 20),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                        title: const Text('Delete Transfer?'),
                                        content: const Text(
                                            'This will reverse the balances for both accounts.'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel')),
                                          ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  foregroundColor:
                                                      Colors.white),
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Delete'))
                                        ],
                                      ));
                              if (confirm == true) {
                                await ref
                                    .read(transferProvider.notifier)
                                    .delete(t.id,
                                        fromAccountId: t.fromAccountId,
                                        toAccountId: t.toAccountId,
                                        amount: t.amount);
                                ref.invalidate(accountProvider);
                              }
                            }),
                      ]),
                    ),
                  );
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              );
            },
          );
        },
      ),
    );
  }
}

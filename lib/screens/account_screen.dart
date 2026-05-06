import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/account_model.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../providers/account_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../screens/transfers_screen.dart';
import '../services/refresh_service.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _selectedColor = '#378ADD';

  static const _colorOptions = [
    '#378ADD',
    '#1D9E75',
    '#D85A30',
    '#7F77DD',
    '#EF9F27',
    '#D4537E',
    '#888780'
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) =>
      Color(int.parse(hex.replaceFirst('#', '0xFF')));

  void _showAddDialog() {
    _nameCtrl.clear();
    _selectedColor = '#378ADD';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Add New Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Account Name',
                      hintText: 'e.g. Bank, Cash, Bkash',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined))),
              const SizedBox(height: 16),
              const Align(
                  alignment: Alignment.centerLeft, child: Text('Color')),
              const SizedBox(height: 8),
              Wrap(
                  spacing: 10,
                  children: _colorOptions.map((c) {
                    final selected = _selectedColor == c;
                    return GestureDetector(
                        onTap: () => setInner(() => _selectedColor = c),
                        child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                                color: _parseColor(c),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: selected
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: 2)),
                            child: selected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 16)
                                : null));
                  }).toList()),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () async {
                  if (_nameCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  await ref.read(accountProvider.notifier).add(AccountModel(
                      id: '',
                      name: _nameCtrl.text.trim(),
                      balance: 0.0,
                      color: _selectedColor,
                      createdAt: DateTime.now()));
                },
                child: const Text('Create')),
          ],
        ),
      ),
    );
  }

  void _showTransactionDialog(AccountModel account, {required bool isDeposit}) {
    _amountCtrl.clear();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(isDeposit
                  ? 'Deposit to ${account.name}'
                  : 'Withdraw from ${account.name}'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                    'Current Balance: ৳ ${NumberFormat('#,##0.00').format(account.balance)}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                TextField(
                    controller: _amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    decoration: const InputDecoration(
                        labelText: 'Amount (৳)',
                        prefixIcon: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Text('৳',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold))))),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () async {
                      final amount = double.tryParse(_amountCtrl.text.trim());
                      if (amount == null || amount <= 0) return;
                      if (!isDeposit && amount > account.balance) {
                        if (ctx.mounted)
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                              content: Text(
                                  'Insufficient balance for withdrawal.')));
                        return;
                      }
                      Navigator.pop(ctx);
                      final now = DateTime.now();
                      if (isDeposit) {
                        await ref
                            .read(accountProvider.notifier)
                            .adjustBalance(account.id, amount);
                        await ref.read(expenseProvider.notifier).add(
                            ExpenseModel(
                                id: '',
                                sector: 'Account Deposit',
                                details: 'Deposit to ${account.name}',
                                amount: amount,
                                date: now,
                                currency: 'BDT',
                                sourceType: 'account',
                                sourceId: account.id));
                      } else {
                        await ref
                            .read(accountProvider.notifier)
                            .adjustBalance(account.id, -amount);
                        await ref.read(incomeProvider.notifier).add(IncomeModel(
                            id: '',
                            sector: 'Account Withdraw',
                            details: 'Withdraw from ${account.name}',
                            amount: amount,
                            date: now,
                            currency: 'BDT',
                            sourceType: 'account',
                            sourceId: account.id));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: isDeposit
                            ? const Color(0xFF1D9E75)
                            : const Color(0xFFD85A30),
                        foregroundColor: Colors.white),
                    child: Text(isDeposit ? 'Deposit' : 'Withdraw')),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    final accountAsync = ref.watch(accountProvider);
    final fmt = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TransfersScreen())),
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('Transfer Balances'),
              style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: () => refreshAll(ref))
        ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: _showAddDialog, child: const Icon(Icons.add)),
      body: accountAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (accounts) {
          if (accounts.isEmpty) {
            return Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Icon(Icons.account_balance_wallet,
                      size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  const Text('No accounts added yet.'),
                  const SizedBox(height: 8),
                  const Text('Tap + to create one.',
                      style: TextStyle(color: Colors.grey))
                ]));
          }
          return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final acc = accounts[index];
                final color = _parseColor(acc.color);
                return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                CircleAvatar(
                                    backgroundColor: color.withOpacity(0.15),
                                    child: Icon(Icons.account_balance_wallet,
                                        color: color)),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Text(acc.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16))),
                                Text('৳ ${fmt.format(acc.balance)}',
                                    style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18))
                              ]),
                              const SizedBox(height: 16),
                              Row(children: [
                                Expanded(
                                    child: OutlinedButton.icon(
                                        onPressed: () => _showTransactionDialog(
                                            acc,
                                            isDeposit: true),
                                        icon: const Icon(Icons.arrow_downward,
                                            size: 18),
                                        label: const Text('Deposit'),
                                        style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                const Color(0xFF1D9E75),
                                            side: const BorderSide(
                                                color: Color(0xFF1D9E75))))),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: OutlinedButton.icon(
                                        onPressed: () => _showTransactionDialog(
                                            acc,
                                            isDeposit: false),
                                        icon: const Icon(Icons.arrow_upward,
                                            size: 18),
                                        label: const Text('Withdraw'),
                                        style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                const Color(0xFFD85A30),
                                            side: const BorderSide(
                                                color: Color(0xFFD85A30))))),
                                const SizedBox(width: 12),
                                IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red, size: 24),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                                  title: const Text(
                                                      'Delete Account'),
                                                  content: Text(
                                                      'Delete "${acc.name}"? All related deposit/withdraw records will be removed.'),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, false),
                                                        child: const Text(
                                                            'Cancel')),
                                                    ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                                backgroundColor:
                                                                    Colors.red,
                                                                foregroundColor:
                                                                    Colors
                                                                        .white),
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, true),
                                                        child: const Text(
                                                            'Delete'))
                                                  ]));
                                      if (confirm == true) {
                                        await ref
                                            .read(accountProvider.notifier)
                                            .delete(acc.id);
                                        ref.invalidate(incomeProvider);
                                        ref.invalidate(expenseProvider);
                                      }
                                    })
                              ]),
                            ])));
              });
        },
      ),
    );
  }
}

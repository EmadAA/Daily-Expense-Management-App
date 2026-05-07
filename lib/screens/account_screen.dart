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

  // Matched exactly to your image order
  static const _colorOptions = [
    '#378ADD', // Blue
    '#1D9E75', // Green
    '#D85A30', // Red/Orange
    '#7F77DD', // Purple
    '#EF9F27', // Yellow
    '#D4537E', // Pink
    '#888780', // Grey
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) =>
      Color(int.parse(hex.replaceFirst('#', '0xFF')));

  /// 🎨 Dialog with fixed simple color picker
  void _showAddDialog() {
    _nameCtrl.clear();
    _selectedColor = '#378ADD';
    showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            decoration: BoxDecoration(
              color: Theme.of(context).dialogBackgroundColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 24,
                    offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('New Account',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    IconButton(
                        icon: const Icon(Icons.close_outlined),
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Create a new place to store your money.',
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Account Name',
                    hintText: 'e.g. Brac Bank, Cash, Bkash',
                    prefixIcon:
                        const Icon(Icons.account_balance_wallet_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Choose a tag color',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                // 🔽 SIMPLE COLOR PICKER (Matches your image exactly, no errors) 🔽
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _colorOptions.map((c) {
                    final selected = _selectedColor == c;
                    final color = _parseColor(c);
                    return GestureDetector(
                      onTap: () => setInner(() => _selectedColor = c),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                // 🔼 END OF SIMPLE COLOR PICKER 🔼
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
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
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      backgroundColor: const Color(0xFF378ADD),
                      elevation: 0,
                    ),
                    child: const Text('Create Account',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
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
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: () => refreshAll(ref))
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF378ADD),
        label: const Row(children: [
          Icon(Icons.add, size: 20, color: Colors.white),
          SizedBox(width: 6),
          Text('New Account', style: TextStyle(color: Colors.white))
        ]),
      ),
      body: accountAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (accounts) {
          return Column(
            children: [
              //  Transfer Button (Moved below AppBar)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: InkWell(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TransfersScreen())),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF378ADD).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF378ADD).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF378ADD).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.swap_horiz,
                                  color: Color(0xFF378ADD), size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text('Transfer Balances',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF378ADD))),
                          ],
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            size: 14, color: Color(0xFF378ADD)),
                      ],
                    ),
                  ),
                ),
              ),

              // 📜 Account List / Empty State
              Expanded(
                child: accounts.isEmpty
                    ? Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            Icon(Icons.account_balance_wallet,
                                size: 64,
                                color: Theme.of(context).colorScheme.outline),
                            const SizedBox(height: 16),
                            const Text('No accounts added yet.'),
                            const SizedBox(height: 8),
                            const Text('Tap + to create one.',
                                style: TextStyle(color: Colors.grey))
                          ]))
                    : ListView.builder(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          CircleAvatar(
                                              backgroundColor:
                                                  color.withOpacity(0.15),
                                              child: Icon(
                                                  Icons.account_balance_wallet,
                                                  color: color)),
                                          const SizedBox(width: 12),
                                          Expanded(
                                              child: Text(acc.name,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                              onPressed: () =>
                                                  _showTransactionDialog(acc,
                                                      isDeposit: true),
                                              icon: const Icon(
                                                  Icons.arrow_downward,
                                                  size: 16),
                                              label: const Text(
                                                'Deposit',
                                                style: TextStyle(fontSize: 13),
                                                maxLines: 1,
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    const Color(0xFF1D9E75),
                                                side: const BorderSide(
                                                    color: Color(0xFF1D9E75)),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 12),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () =>
                                                  _showTransactionDialog(acc,
                                                      isDeposit: false),
                                              icon: const Icon(
                                                  Icons.arrow_upward,
                                                  size: 16),
                                              label: const Text(
                                                'Withdraw',
                                                style: TextStyle(fontSize: 13),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    const Color(0xFFD85A30),
                                                side: const BorderSide(
                                                    color: Color(0xFFD85A30)),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 12),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          IconButton(
                                              icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red,
                                                  size: 24),
                                              onPressed: () async {
                                                final confirm = await showDialog<
                                                        bool>(
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
                                                                          context,
                                                                          false),
                                                                  child: const Text(
                                                                      'Cancel')),
                                                              ElevatedButton(
                                                                  style: ElevatedButton.styleFrom(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .red,
                                                                      foregroundColor:
                                                                          Colors
                                                                              .white),
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                          context,
                                                                          true),
                                                                  child: const Text(
                                                                      'Delete'))
                                                            ]));
                                                if (confirm == true) {
                                                  await ref
                                                      .read(accountProvider
                                                          .notifier)
                                                      .delete(acc.id);
                                                  ref.invalidate(
                                                      incomeProvider);
                                                  ref.invalidate(
                                                      expenseProvider);
                                                }
                                              })
                                        ]),
                                      ])));
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

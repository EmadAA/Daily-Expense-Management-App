import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../services/refresh_service.dart';

class AllTransactionsScreen extends ConsumerStatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  ConsumerState<AllTransactionsScreen> createState() =>
      _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends ConsumerState<AllTransactionsScreen> {
  final _searchCtrl = TextEditingController();
  String _searchText = '';
  String _filterType = 'All';
  String _filterCategory = 'All'; // All / Loan / Goal / Savings / Recurring
  String _sortOrder = 'Oldest';
  DateTime? _selectedMonth;

  // Sector tags used by each category
  static const _loanSectors = {
    'Loan Given',
    'Loan Received',
    'Loan Borrowed',
    'Loan Repaid'
  };
  static const _goalSectors = {'Savings'};
  static const _recurringTag =
      '(auto)'; // recurring entries have "(auto)" in details

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMonth(BuildContext context) async {
    int pickerYear = _selectedMonth?.year ?? DateTime.now().year;
    int pickerMonth = _selectedMonth?.month ?? DateTime.now().month;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Select Month'),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setInner(() => pickerYear--),
                    ),
                    Text('$pickerYear',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setInner(() => pickerYear++),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 12,
                  itemBuilder: (_, i) {
                    final month = i + 1;
                    final selected = pickerMonth == month;
                    final label =
                        DateFormat('MMM').format(DateTime(2000, month));
                    return GestureDetector(
                      onTap: () => setInner(() => pickerMonth = month),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(label,
                            style: TextStyle(
                              color: selected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            )),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _selectedMonth = null);
                Navigator.pop(ctx);
              },
              child: const Text('Clear'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(
                    () => _selectedMonth = DateTime(pickerYear, pickerMonth));
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesCategory(Map<String, dynamic> t) {
    if (_filterCategory == 'All') return true;

    final sector = t['sector'] as String;
    final details = t['details'] as String;

    switch (_filterCategory) {
      case 'Loan':
        return _loanSectors.contains(sector);
      case 'Goal':
        return _goalSectors.contains(sector);
      case 'Recurring':
        return details.contains(_recurringTag);
      default:
        return true;
    }
  }

  List<Map<String, dynamic>> _buildList(
    List<IncomeModel> incomes,
    List<ExpenseModel> expenses,
  ) {
    final list = <Map<String, dynamic>>[];

    if (_filterType != 'Expense') {
      for (final i in incomes) {
        list.add({
          'type': 'income',
          'sector': i.sector,
          'details': i.details,
          'amount': i.amount,
          'date': i.date,
        });
      }
    }
    if (_filterType != 'Income') {
      for (final e in expenses) {
        list.add({
          'type': 'expense',
          'sector': e.sector,
          'details': e.details,
          'amount': e.amount,
          'date': e.date,
        });
      }
    }

    // Category filter
    list.retainWhere(_matchesCategory);

    // Month filter
    if (_selectedMonth != null) {
      list.retainWhere((t) {
        final d = t['date'] as DateTime;
        return d.year == _selectedMonth!.year &&
            d.month == _selectedMonth!.month;
      });
    }

    // Search filter
    if (_searchText.isNotEmpty) {
      final q = _searchText.toLowerCase();
      list.retainWhere((t) =>
          (t['sector'] as String).toLowerCase().contains(q) ||
          (t['details'] as String).toLowerCase().contains(q) ||
          t['amount'].toString().contains(q));
    }

    // Sort
    list.sort((a, b) {
      final dateA = a['date'] as DateTime;
      final dateB = b['date'] as DateTime;
      return _sortOrder == 'Oldest'
          ? dateA.compareTo(dateB)
          : dateB.compareTo(dateA);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final incomeAsync = ref.watch(incomeProvider);
    final expenseAsync = ref.watch(expenseProvider);
    final fmt = NumberFormat('#,##0.00');
    final monthLabel = _selectedMonth != null
        ? DateFormat('MMMM yyyy').format(_selectedMonth!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
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
        data: (incomes) => expenseAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (expenses) {
            final list = _buildList(incomes, expenses);

            return Column(
              children: [
                // ── Search bar ──────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by name, amount...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchText.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchText = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) => setState(() => _searchText = v),
                  ),
                ),

                // ── Row 1: Month + Type + Sort ──────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Month chip
                        GestureDetector(
                          onTap: () => _pickMonth(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedMonth != null
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceVariant,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_month_outlined,
                                    size: 16,
                                    color: _selectedMonth != null
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant),
                                const SizedBox(width: 6),
                                Text(
                                  monthLabel ?? 'All months',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _selectedMonth != null
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                                ),
                                if (_selectedMonth != null) ...[
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedMonth = null),
                                    child: Icon(Icons.close,
                                        size: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Type chips
                        for (final type in ['All', 'Income', 'Expense'])
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(type,
                                  style: const TextStyle(fontSize: 12)),
                              selected: _filterType == type,
                              onSelected: (_) =>
                                  setState(() => _filterType = type),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),

                        const SizedBox(width: 4),

                        // Sort toggle
                        IconButton(
                          tooltip: _sortOrder,
                          icon: Icon(
                            _sortOrder == 'Oldest'
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 20,
                          ),
                          onPressed: () => setState(() {
                            _sortOrder =
                                _sortOrder == 'Oldest' ? 'Newest' : 'Oldest';
                          }),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Row 2: Category filters ─────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final entry in [
                          {'label': 'All', 'icon': Icons.list_alt_rounded},
                          {'label': 'Loan', 'icon': Icons.handshake_outlined},
                          {'label': 'Goal', 'icon': Icons.track_changes},
                          {'label': 'Recurring', 'icon': Icons.repeat},
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              avatar: Icon(
                                entry['icon'] as IconData,
                                size: 14,
                                color: _filterCategory == entry['label']
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                              label: Text(
                                entry['label'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _filterCategory == entry['label']
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : null,
                                ),
                              ),
                              selected: _filterCategory == entry['label'],
                              selectedColor:
                                  Theme.of(context).colorScheme.primary,
                              onSelected: (_) => setState(() =>
                                  _filterCategory = entry['label'] as String),
                              visualDensity: VisualDensity.compact,
                              showCheckmark: false,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // ── Count ───────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '${list.length} transaction${list.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      if (monthLabel != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '· $monthLabel',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (_filterCategory != 'All') ...[
                        const SizedBox(width: 6),
                        Text(
                          '· $_filterCategory',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // ── Transaction list ────────────────
                Expanded(
                  child: list.isEmpty
                      ? const Center(child: Text('No transactions found.'))
                      : ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final t = list[index];
                            final isIncome = t['type'] == 'income';
                            final color = isIncome
                                ? const Color(0xFF1D9E75)
                                : const Color(0xFFD85A30);
                            final bgColor = isIncome
                                ? const Color(0xFFEAF3DE)
                                : const Color(0xFFFAECE7);
                            final date = t['date'] as DateTime;
                            final dateStr =
                                '${date.day}/${date.month}/${date.year}';

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: bgColor,
                                  child: Icon(
                                    isIncome
                                        ? Icons.arrow_downward_rounded
                                        : Icons.arrow_upward_rounded,
                                    color: color,
                                    size: 18,
                                  ),
                                ),
                                title: Text(t['sector'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if ((t['details'] as String).isNotEmpty)
                                      Text(t['details'],
                                          style: const TextStyle(fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    Text(dateStr,
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                                isThreeLine:
                                    (t['details'] as String).isNotEmpty,
                                trailing: Text(
                                  '${isIncome ? '+' : '-'} ৳ ${fmt.format(t['amount'])}',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

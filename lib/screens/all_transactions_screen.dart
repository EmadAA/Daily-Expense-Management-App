// ignore_for_file: unnecessary_cast

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
  String _filterCategory = 'All'; // All, Loan, Goal, Savings, or specific categories
  String _sortOrder = 'Oldest';
  DateTime? _selectedMonth;

  // Category filter options
  static const List<Map<String, dynamic>> _categoryFilters = [
    {'label': 'All', 'icon': Icons.list_alt_rounded, 'value': 'All'},
    {'label': 'Loan', 'icon': Icons.handshake_outlined, 'value': 'Loan'},
    {'label': 'Savings', 'icon': Icons.savings, 'value': 'Savings'},
    {'label': 'Food', 'icon': Icons.restaurant, 'value': 'Food'},
    {'label': 'Groceries', 'icon': Icons.shopping_cart, 'value': 'Groceries'},
    {'label': 'Salary', 'icon': Icons.work, 'value': 'Salary'},
    {'label': 'Gift', 'icon': Icons.card_giftcard, 'value': 'Gift'},
    {'label': 'Others', 'icon': Icons.category, 'value': 'Other'},
  ];

  // Loan-related categories
  static const List<String> _loanCategories = [
    'Loan Borrowed',
    'Loan Given',
    'Loan Repaid',
  ];

  // Savings category
  static const String _savingsCategory = 'Savings';

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

  bool _matchesCategory(dynamic transaction) {
    if (_filterCategory == 'All') return true;

    // Get category from transaction
    String category;
    if (transaction is IncomeModel) {
      category = transaction.category;
    } else if (transaction is ExpenseModel) {
      category = transaction.category;
    } else {
      return true;
    }

    switch (_filterCategory) {
      case 'Loan':
        return _loanCategories.contains(category);
      case 'Savings':
        return category == _savingsCategory;
      default:
        // For specific categories like Food, Salary, etc.
        return category == _filterCategory;
    }
  }

  List<dynamic> _buildList(
    List<IncomeModel> incomes,
    List<ExpenseModel> expenses,
  ) {
    final list = <dynamic>[];

    if (_filterType != 'Expense') {
      for (final i in incomes) {
        list.add(i);
      }
    }
    if (_filterType != 'Income') {
      for (final e in expenses) {
        list.add(e);
      }
    }

    // Category filter
    list.retainWhere(_matchesCategory);

    // Month filter
    if (_selectedMonth != null) {
      list.retainWhere((t) {
        final d = t.date;
        return d.year == _selectedMonth!.year &&
            d.month == _selectedMonth!.month;
      });
    }

    // Search filter - NOW INCLUDES CATEGORY SEARCH
    if (_searchText.isNotEmpty) {
      final q = _searchText.toLowerCase();
      list.retainWhere((t) {
        // Get category from transaction
        String category;
        if (t is IncomeModel) {
          category = t.category;
        } else if (t is ExpenseModel) {
          category = t.category;
        } else {
          category = '';
        }
        
        return t.sector.toLowerCase().contains(q) ||
            t.details.toLowerCase().contains(q) ||
            t.amount.toString().contains(q) ||
            category.toLowerCase().contains(q); // Added category search
      });
    }

    // Sort
    list.sort((a, b) {
      final dateA = a.date;
      final dateB = b.date;
      return _sortOrder == 'Oldest'
          ? dateA.compareTo(dateB)
          : dateB.compareTo(dateA);
    });

    return list;
  }

  // Method to calculate total amount for a list of transactions
  double _calculateTotal(List<dynamic> transactions) {
    double total = 0;
    for (final transaction in transactions) {
      if (transaction is IncomeModel) {
        total += transaction.amount;
      } else if (transaction is ExpenseModel) {
        total -= transaction.amount; // Expenses are negative
      }
    }
    return total;
  }

  // Method to group transactions by date with totals
  List<dynamic> _buildGroupedList(List<dynamic> transactions) {
    if (transactions.isEmpty) return [];

    final grouped = <String, List<dynamic>>{};

    for (final transaction in transactions) {
      final date = transaction.date;
      final dateKey = DateFormat('yyyy-MM-dd').format(date);

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
    }

    final result = <dynamic>[];

    // Sort dates
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) {
        final dateA = DateTime.parse(a);
        final dateB = DateTime.parse(b);
        return _sortOrder == 'Oldest'
            ? dateA.compareTo(dateB)
            : dateB.compareTo(dateA);
      });

    for (final dateKey in sortedDates) {
      final date = DateTime.parse(dateKey);
      final formattedDate = _getFormattedDate(date);
      final transactionsOnDate = grouped[dateKey]!;
      final dailyTotal = _calculateTotal(transactionsOnDate);

      // Add divider header with total
      result.add({
        'isDivider': true,
        'date': date,
        'formattedDate': formattedDate,
        'transactionCount': transactionsOnDate.length,
        'dailyTotal': dailyTotal,
      });

      // Add transactions for this date
      result.addAll(transactionsOnDate);
    }

    return result;
  }

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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Groceries':
        return Icons.shopping_cart;
      case 'Internet+Recharge':
        return Icons.wifi;
      case 'Bike':
        return Icons.two_wheeler;
      case 'Car':
        return Icons.directions_car;
      case 'Gym':
        return Icons.fitness_center;
      case 'Medicine+Doctor':
        return Icons.medical_services;
      case 'Sports':
        return Icons.sports_soccer;
      case 'Tour':
        return Icons.flight_takeoff;
      case 'Clothes':
        return Icons.checkroom;
      case 'Shoes':
        return Icons.shopping_bag;
      case 'Gift':
        return Icons.card_giftcard;
      case 'Education':
        return Icons.school;
      case 'Entertainment':
        return Icons.movie;
      case 'Electronics':
        return Icons.electrical_services;
      case 'Salary':
        return Icons.work;
      case 'Bonus':
        return Icons.card_giftcard;
      case 'Freelance Project':
        return Icons.computer;
      case 'Business':
        return Icons.business_center;
      case 'Loan Borrowed':
        return Icons.paypal;
      case 'Loan Given':
        return Icons.handshake;
      case 'Loan Repaid':
        return Icons.assignment_turned_in;
      case 'Savings':
        return Icons.savings;
      default:
        return Icons.category;
    }
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
            final groupedList = _buildGroupedList(list);
            final totalAmount = _calculateTotal(list);

            return Column(
              children: [
                // ── Search bar ──────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by name, amount, or category...',
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

                // ── Search suggestions / active filters ──
                if (_searchText.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Searching: "$_searchText"',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

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
                        for (final filter in _categoryFilters)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              avatar: Icon(
                                filter['icon'] as IconData,
                                size: 14,
                                color: _filterCategory == filter['value']
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                              label: Text(
                                filter['label'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _filterCategory == filter['value']
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : null,
                                ),
                              ),
                              selected: _filterCategory == filter['value'],
                              selectedColor:
                                  Theme.of(context).colorScheme.primary,
                              onSelected: (_) => setState(() =>
                                  _filterCategory = filter['value'] as String),
                              visualDensity: VisualDensity.compact,
                              showCheckmark: false,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // ── Count and Total ───────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left side: transaction count
                      Row(
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
                          if (_searchText.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '· Search: "$_searchText"',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.secondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      // Right side: total amount
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: totalAmount >= 0
                              ? const Color(0xFF1D9E75).withOpacity(0.1)
                              : const Color(0xFFD85A30).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              totalAmount >= 0
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              size: 14,
                              color: totalAmount >= 0
                                  ? const Color(0xFF1D9E75)
                                  : const Color(0xFFD85A30),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${totalAmount >= 0 ? '+' : ''}৳ ${fmt.format(totalAmount.abs())}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: totalAmount >= 0
                                    ? const Color(0xFF1D9E75)
                                    : const Color(0xFFD85A30),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // ── Transaction list with dividers ───
                Expanded(
                  child: groupedList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchText.isNotEmpty
                                    ? 'No transactions match "$_searchText"'
                                    : 'No transactions found.',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              if (_searchText.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchText = '');
                                  },
                                  icon: const Icon(Icons.clear),
                                  label: const Text('Clear Search'),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: groupedList.length,
                          itemBuilder: (context, index) {
                            final item = groupedList[index];

                            // Check if this is a divider
                            if (item is Map && item['isDivider'] == true) {
                              final dailyTotal = item['dailyTotal'] as double;
                              
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Left side: date and count
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            item['formattedDate'],
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primaryContainer,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${item['transactionCount']} items',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Right side: daily total
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: dailyTotal >= 0
                                            ? const Color(0xFF1D9E75).withOpacity(0.1)
                                            : const Color(0xFFD85A30).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${dailyTotal >= 0 ? '+' : ''}৳ ${fmt.format(dailyTotal.abs())}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: dailyTotal >= 0
                                              ? const Color(0xFF1D9E75)
                                              : const Color(0xFFD85A30),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Regular transaction item
                            final transaction = item;
                            final isIncome = transaction is IncomeModel;
                            final color = isIncome
                                ? const Color(0xFF1D9E75)
                                : const Color(0xFFD85A30);
                            final bgColor = isIncome
                                ? const Color(0xFFEAF3DE)
                                : const Color(0xFFFAECE7);
                            final date = transaction.date;
                            final dateStr =
                                '${date.day}/${date.month}/${date.year}';
                            final category = isIncome
                                ? (transaction as IncomeModel).category
                                : (transaction as ExpenseModel).category;

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
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        transaction.sector,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getCategoryIcon(category),
                                            size: 10,
                                            color: color,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            category,
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: color,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (transaction.details.isNotEmpty)
                                      Text(transaction.details,
                                          style: const TextStyle(fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    Text(dateStr,
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                                isThreeLine: transaction.details.isNotEmpty,
                                trailing: Text(
                                  '${isIncome ? '+' : '-'} ৳ ${fmt.format(transaction.amount)}',
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
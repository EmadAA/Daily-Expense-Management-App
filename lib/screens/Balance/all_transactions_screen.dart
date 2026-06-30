// ignore_for_file: deprecated_member_use, unnecessary_cast

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/expense_model.dart';
import '../../models/income_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/income_provider.dart';
import '../../services/refresh_service.dart';

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
  String _filterCategory = 'All';
  String _sortOrder = 'Newest';
  DateTime? _selectedMonth;

  static const List<Map<String, dynamic>> _categoryFilters = [
    {'label': 'All', 'icon': Icons.list_alt_rounded, 'value': 'All'},
    {'label': 'Loan', 'icon': Icons.handshake_outlined, 'value': 'Loan'},
    {'label': 'Savings', 'icon': Icons.savings, 'value': 'Savings'},
    {'label': 'Food', 'icon': Icons.restaurant, 'value': 'Food'},
    {'label': 'Groceries', 'icon': Icons.shopping_cart, 'value': 'Groceries'},
    {'label': 'Shopping', 'icon': Icons.shopping_bag, 'value': 'Shopping'},
    {'label': 'Subscription', 'icon': Icons.money, 'value': 'Subscription'},
    {'label': 'Study', 'icon': Icons.menu_book, 'value': 'Study'},
    {'label': 'Books', 'icon': Icons.library_books, 'value': 'Books'},
    {'label': 'Cosmetics', 'icon': Icons.face, 'value': 'Cosmetics'},
    {'label': 'Mobile Recharge', 'icon': Icons.phone, 'value': 'Internet+Recharge'},
    {'label': 'Bike', 'icon': Icons.two_wheeler, 'value': 'Bike'},
    {'label': 'Car', 'icon': Icons.directions_car, 'value': 'Car'},
    {'label': 'Gym', 'icon': Icons.fitness_center, 'value': 'Gym'},
    {'label': 'Medicine+Doctor', 'icon': Icons.medical_services, 'value': 'Medicine+Doctor'},
    {'label': 'Sports', 'icon': Icons.sports_soccer, 'value': 'Sports'},
    {'label': 'Tour', 'icon': Icons.travel_explore, 'value': 'Tour'},
    {'label': 'Clothes', 'icon': Icons.checkroom, 'value': 'Clothes'},
    {'label': 'Shoes', 'icon': Icons.shopping_bag, 'value': 'Shoes'},
    {'label': 'Gift', 'icon': Icons.card_giftcard, 'value': 'Gift'},
    {'label': 'Education', 'icon': Icons.school, 'value': 'Education'},
    {'label': 'Electronics', 'icon': Icons.electrical_services, 'value': 'Electronics'},
    {'label': 'Salary', 'icon': Icons.work, 'value': 'Salary'},
    {'label': 'Bonus', 'icon': Icons.card_giftcard, 'value': 'Bonus'},
    {'label': 'Freelance Project', 'icon': Icons.computer, 'value': 'Freelance Project'},
    {'label': 'Business', 'icon': Icons.business_center, 'value': 'Business'},
    {'label': 'Others', 'icon': Icons.category, 'value': 'Other'},
  ];

  static const List<String> _loanCategories = [
    'Loan Borrowed',
    'Loan Given',
    'Loan Repaid',
    'Loan Received',
  ];

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

    list.retainWhere(_matchesCategory);

    if (_selectedMonth != null) {
      list.retainWhere((t) {
        final d = t.date;
        return d.year == _selectedMonth!.year &&
            d.month == _selectedMonth!.month;
      });
    }

    if (_searchText.isNotEmpty) {
      final q = _searchText.toLowerCase();
      list.retainWhere((t) {
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
            category.toLowerCase().contains(q);
      });
    }

    list.sort((a, b) {
      final dateA = a.date;
      final dateB = b.date;
      return _sortOrder == 'Oldest'
          ? dateA.compareTo(dateB)
          : dateB.compareTo(dateA);
    });

    return list;
  }

  double _calculateTotal(List<dynamic> transactions) {
    double total = 0;
    for (final transaction in transactions) {
      if (transaction is IncomeModel) {
        total += transaction.amount;
      } else if (transaction is ExpenseModel) {
        total -= transaction.amount;
      }
    }
    return total;
  }

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

      result.add({
        'isDivider': true,
        'date': date,
        'formattedDate': formattedDate,
        'transactionCount': transactionsOnDate.length,
        'dailyTotal': dailyTotal,
      });

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
      case 'Shopping':
        return Icons.shopping_bag;
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
      case 'Electronics':
        return Icons.electrical_services;
      case 'Subscription':
        return Icons.subscriptions;
      case 'Study':
        return Icons.menu_book;
      case 'Books':
        return Icons.library_books;
      case 'Cosmetics':
        return Icons.face;
      case 'Savings':
        return Icons.savings;
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
      case 'Loan Received':
        return Icons.assignment_turned_in;
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
      backgroundColor: const Color(0xFFF5F8FA),
      appBar: AppBar(
        title: const Text(
          'All Transactions',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Color(0xFF1A1A2E),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1A1A2E),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: 'Refresh',
              onPressed: () => refreshAll(ref),
              style: IconButton.styleFrom(
                foregroundColor: const Color(0xFF1D9E75),
              ),
            ),
          ),
        ],
      ),
      body: incomeAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1D9E75),
          ),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (incomes) => expenseAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF1D9E75),
            ),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (expenses) {
            final list = _buildList(incomes, expenses);
            final groupedList = _buildGroupedList(list);
            final totalAmount = _calculateTotal(list);

            return Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search transactions...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.grey.shade400,
                        ),
                        suffixIcon: _searchText.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: Colors.grey.shade400,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchText = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (v) => setState(() => _searchText = v),
                    ),
                  ),
                ),

                if (_searchText.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D9E75).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 14,
                            color: const Color(0xFF1D9E75),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Results for "$_searchText"',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF1D9E75),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Filter chips row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Month picker
                        GestureDetector(
                          onTap: () => _pickMonth(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedMonth != null
                                  ? const Color(0xFF1D9E75)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _selectedMonth != null
                                    ? const Color(0xFF1D9E75)
                                    : Colors.grey.shade200,
                                width: 1,
                              ),
                              boxShadow: [
                                if (_selectedMonth == null)
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_month_outlined,
                                  size: 16,
                                  color: _selectedMonth != null
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  monthLabel ?? 'All months',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _selectedMonth != null
                                        ? Colors.white
                                        : const Color(0xFF1A1A2E),
                                  ),
                                ),
                                if (_selectedMonth != null) ...[
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => setState(() => _selectedMonth = null),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
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
                              label: Text(
                                type,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: type == _filterType
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                              selected: _filterType == type,
                              onSelected: (_) => setState(() => _filterType = type),
                              selectedColor: const Color(0xFF1D9E75),
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: _filterType == type
                                    ? Colors.white
                                    : const Color(0xFF1A1A2E),
                              ),
                              side: BorderSide(
                                color: _filterType == type
                                    ? const Color(0xFF1D9E75)
                                    : Colors.grey.shade200,
                                width: 1,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        // Sort button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              _sortOrder == 'Oldest'
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 18,
                              color: const Color(0xFF1A1A2E),
                            ),
                            onPressed: () => setState(() {
                              _sortOrder = _sortOrder == 'Oldest' ? 'Newest' : 'Oldest';
                            }),
                            tooltip: _sortOrder,
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Category filter chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final filter in _categoryFilters)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              avatar: Icon(
                                filter['icon'] as IconData,
                                size: 14,
                                color: _filterCategory == filter['value']
                                    ? Colors.white
                                    : Colors.grey.shade600,
                              ),
                              label: Text(
                                filter['label'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: _filterCategory == filter['value']
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                              selected: _filterCategory == filter['value'],
                              selectedColor: const Color(0xFF1D9E75),
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: _filterCategory == filter['value']
                                    ? Colors.white
                                    : const Color(0xFF1A1A2E),
                              ),
                              side: BorderSide(
                                color: _filterCategory == filter['value']
                                    ? const Color(0xFF1D9E75)
                                    : Colors.grey.shade200,
                                width: 1,
                              ),
                              onSelected: (_) => setState(() =>
                                  _filterCategory = filter['value'] as String),
                              visualDensity: VisualDensity.compact,
                              showCheckmark: false,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Count and Total
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.receipt_long_rounded,
                                  size: 14,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${list.length} transaction${list.length != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (monthLabel != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1D9E75).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      monthLabel,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: const Color(0xFF1D9E75),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                                if (_filterCategory != 'All') ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1D9E75).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _filterCategory,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: const Color(0xFF1D9E75),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: totalAmount >= 0
                                  ? [
                                      const Color(0xFF1D9E75).withOpacity(0.1),
                                      const Color(0xFF1D9E75).withOpacity(0.05),
                                    ]
                                  : [
                                      const Color(0xFFD85A30).withOpacity(0.1),
                                      const Color(0xFFD85A30).withOpacity(0.05),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: totalAmount >= 0
                                  ? const Color(0xFF1D9E75).withOpacity(0.2)
                                  : const Color(0xFFD85A30).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                totalAmount >= 0
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                                size: 14,
                                color: totalAmount >= 0
                                    ? const Color(0xFF1D9E75)
                                    : const Color(0xFFD85A30),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${totalAmount >= 0 ? '+' : ''}৳ ${fmt.format(totalAmount.abs())}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
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
                ),
                const SizedBox(height: 6),

                // Transaction list with dividers
                Expanded(
                  child: groupedList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchText.isNotEmpty
                                    ? 'No transactions match "$_searchText"'
                                    : 'No transactions found',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_searchText.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchText = '');
                                  },
                                  icon: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: const Color(0xFF1D9E75),
                                  ),
                                  label: Text(
                                    'Clear Search',
                                    style: TextStyle(
                                      color: const Color(0xFF1D9E75),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: groupedList.length,
                          itemBuilder: (context, index) {
                            final item = groupedList[index];

                            if (item is Map && item['isDivider'] == true) {
                              final dailyTotal = item['dailyTotal'] as double;
                              
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1D9E75).withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.calendar_today_rounded,
                                              size: 14,
                                              color: const Color(0xFF1D9E75),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Flexible(
                                            child: Text(
                                              item['formattedDate'],
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF1A1A2E),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1D9E75).withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${item['transactionCount']}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF1D9E75),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: dailyTotal >= 0
                                            ? const Color(0xFF1D9E75).withOpacity(0.08)
                                            : const Color(0xFFD85A30).withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
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
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final transaction = item;
                            final isIncome = transaction is IncomeModel;
                            final color = isIncome
                                ? const Color(0xFF1D9E75)
                                : const Color(0xFFD85A30);
                            final bgColor = isIncome
                                ? const Color(0xFF1D9E75).withOpacity(0.08)
                                : const Color(0xFFD85A30).withOpacity(0.08);
                            final date = transaction.date;
                            final dateStr = '${date.day}/${date.month}/${date.year}';
                            final category = isIncome
                                ? (transaction as IncomeModel).category
                                : (transaction as ExpenseModel).category;

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 2,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    shape: BoxShape.circle,
                                  ),
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
                                      flex: 2,
                                      child: Text(
                                        transaction.sector,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: const Color(0xFF1A1A2E),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      flex: 1,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.08),
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
                                            const SizedBox(width: 2),
                                            Flexible(
                                              child: Text(
                                                category,
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: color,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (transaction.details.isNotEmpty)
                                      Text(
                                        transaction.details,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: 10,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          dateStr,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                isThreeLine: transaction.details.isNotEmpty,
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: color.withOpacity(0.1),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    '${isIncome ? '+' : '-'}৳ ${fmt.format(transaction.amount)}',
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/expense_model.dart';
import '../models/savings_goal_model.dart';
import '../providers/expense_provider.dart';
import '../providers/savings_goal_provider.dart';
import '../services/refresh_service.dart';

class SavingsGoalsScreen extends ConsumerStatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  ConsumerState<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends ConsumerState<SavingsGoalsScreen> {
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _addCtrl = TextEditingController();
  DateTime? _deadline;
  String _color = '#1D9E75';

  // Tab controller
  int _selectedTabIndex = 0; // 0 = Active, 1 = Completed

  static const _colorOptions = [
    '#1D9E75',
    '#378ADD',
    '#D85A30',
    '#7F77DD',
    '#EF9F27',
    '#D4537E',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    _addCtrl.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) =>
      Color(int.parse(hex.replaceFirst('#', '0xFF')));

  void _showAddGoalDialog() {
    _titleCtrl.clear();
    _targetCtrl.clear();
    _deadline = null;
    _color = '#1D9E75';

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'New Savings Goal',
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
                      'Set a target and track your savings progress.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _titleCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Goal title',
                        hintText: 'e.g. New Phone, Vacation',
                        prefixIcon: const Icon(Icons.flag_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _targetCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Target amount (৳)',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Text(
                            '৳',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
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
                              DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setInner(() => _deadline = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Deadline (optional)',
                          prefixIcon: const Icon(Icons.date_range_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        child: Text(
                          _deadline != null
                              ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                              : 'No deadline',
                          style: TextStyle(
                            color: _deadline != null
                                ? null
                                : Theme.of(ctx).colorScheme.outline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Choose a color',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _colorOptions.map((c) {
                        final selected = _color == c;
                        final color = _parseColor(c);
                        return GestureDetector(
                          onTap: () => setInner(() => _color = c),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? Colors.white
                                    : Colors.transparent,
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
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_titleCtrl.text.trim().isEmpty ||
                              _targetCtrl.text.trim().isEmpty) return;
                          final target =
                              double.tryParse(_targetCtrl.text.trim());
                          if (target == null || target <= 0) return;

                          Navigator.pop(ctx);
                          await ref.read(savingsGoalProvider.notifier).add(
                                SavingsGoalModel(
                                  id: '',
                                  title: _titleCtrl.text.trim(),
                                  targetAmount: target,
                                  savedAmount: 0,
                                  deadline: _deadline,
                                  color: _color,
                                ),
                              );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: const Color(0xFF1D9E75),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Create Goal',
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

  void _showAddMoneyDialog(SavingsGoalModel goal) {
    _addCtrl.clear();
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
                          'Add to "${goal.title}"',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.visible,
                          maxLines: 2,
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
                    'Target: ৳ ${NumberFormat('#,##0.00').format(goal.targetAmount)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _addCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Amount to add (৳)',
                      prefixIcon: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Text(
                          '৳',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
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
                        final amount = double.tryParse(_addCtrl.text.trim());
                        if (amount == null || amount <= 0) return;

                        Navigator.pop(ctx);
                        await ref
                            .read(savingsGoalProvider.notifier)
                            .addToSaved(goal.id, amount);

                        // Add expense with category 'Savings'
                        await ref.read(expenseProvider.notifier).add(
                              ExpenseModel(
                                id: '',
                                sector: 'Savings',
                                details: 'Added to goal: ${goal.title}',
                                amount: amount,
                                date: DateTime.now(),
                                currency: 'BDT',
                                category: 'Other', // Added category - using 'Other' for savings
                                sourceType: 'goal',
                                sourceId: goal.id,
                              ),
                            );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: _parseColor(goal.color),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Add Money',
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

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(savingsGoalProvider);
    final fmt = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => refreshAll(ref),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTabIndex == 0
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            size: 18,
                            color: _selectedTabIndex == 0
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _selectedTabIndex == 0
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTabIndex == 1
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: _selectedTabIndex == 1
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _selectedTabIndex == 1
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _selectedTabIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddGoalDialog,
              child: const Icon(Icons.add),
            )
          : null,
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (goals) {
          // Filter goals based on selected tab
          final filteredGoals = _selectedTabIndex == 0
              ? goals.where((g) => !g.isCompleted).toList()
              : goals.where((g) => g.isCompleted).toList();

          if (filteredGoals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _selectedTabIndex == 0
                        ? Icons.track_changes_outlined
                        : Icons.check_circle_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedTabIndex == 0
                        ? 'No active savings goals yet.'
                        : 'No completed savings goals yet.',
                  ),
                  if (_selectedTabIndex == 0) ...[
                    const SizedBox(height: 8),
                    const Text('Tap + to create one.',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredGoals.length,
            itemBuilder: (context, index) {
              final goal = filteredGoals[index];
              final color = _parseColor(goal.color);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: color.withOpacity(0.15),
                                  child: Icon(
                                    goal.isCompleted
                                        ? Icons.check_circle
                                        : Icons.track_changes_outlined,
                                    color: color,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    goal.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              if (goal.isCompleted)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1D9E75)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Completed!',
                                    style: TextStyle(
                                      color: Color(0xFF1D9E75),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red, size: 20),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Delete Goal'),
                                      content: Text(
                                        'Delete "${goal.title}"?\n\nAll money added to this goal (৳ ${fmt.format(goal.savedAmount)}) will be returned to your balance.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await ref
                                        .read(savingsGoalProvider.notifier)
                                        .delete(goal.id, goal.title);
                                    ref.invalidate(expenseProvider);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (!goal.isCompleted) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '৳ ${fmt.format(goal.savedAmount)} saved',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'of ৳ ${fmt.format(goal.targetAmount)}',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: goal.percentage,
                            backgroundColor: color.withOpacity(0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(goal.percentage * 100).toStringAsFixed(1)}%  ·  ৳ ${fmt.format(goal.remaining)} left',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                            if (goal.daysLeft != null)
                              Text(
                                goal.daysLeft! > 0
                                    ? '${goal.daysLeft} days left'
                                    : 'Deadline passed',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: goal.daysLeft! <= 7
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showAddMoneyDialog(goal),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Money'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: color),
                            ),
                          ),
                        ),
                      ] else ...[
                        // For completed goals - show summary
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Saved',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '৳ ${fmt.format(goal.savedAmount)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Target',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '৳ ${fmt.format(goal.targetAmount)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (goal.deadline != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(
                                'Completed before ${DateFormat('dd MMM yyyy').format(goal.deadline!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
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
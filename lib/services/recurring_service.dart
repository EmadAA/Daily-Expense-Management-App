import '../models/recurring_model.dart';
import '../supabase_config.dart';

class RecurringService {
  final String _table = 'recurring_transactions';

  Future<List<RecurringModel>> fetchAll() async {
    final res = await supabase
        .from(_table)
        .select()
        .order('created_at', ascending: false);
    return (res as List).map((r) => RecurringModel.fromMap(r)).toList();
  }

  Future<void> add(RecurringModel r) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from(_table).insert(r.toMap(userId));
  }

  Future<void> delete(String id) async {
    await supabase.from(_table).delete().eq('id', id);
  }

  // Auto-add due recurring transactions
  Future<void> processDue() async {
    final userId = supabase.auth.currentUser!.id;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final res = await supabase.from(_table).select().eq('user_id', userId);

    for (final row in res as List) {
      final r = RecurringModel.fromMap(row);
      final dueThisMonth = DateTime(now.year, now.month, r.dayOfMonth);

      // Skip if not due yet this month
      if (today.isBefore(dueThisMonth)) continue;

      // Skip if already added this month
      if (r.lastAdded != null &&
          r.lastAdded!.year == now.year &&
          r.lastAdded!.month == now.month) continue;

      // Add to incomes or expenses table
      final table = r.type == 'income' ? 'incomes' : 'expenses';
      await supabase.from(table).insert({
        'user_id': userId,
        'sector': r.sector,
        'details': '${r.details} (auto)',
        'amount': r.amount,
        'date': dueThisMonth.toIso8601String().substring(0, 10),
      });

      // Update last_added
      await supabase
          .from(_table)
          .update({'last_added': today.toIso8601String().substring(0, 10)}).eq(
              'id', r.id);
    }
  }
}

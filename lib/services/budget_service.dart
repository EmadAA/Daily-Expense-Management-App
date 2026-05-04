import '../supabase_config.dart';

class BudgetService {
  final String _table = 'budgets';

  Future<Map<String, double>> fetchAll() async {
    final userId = supabase.auth.currentUser!.id;
    final res = await supabase.from(_table).select().eq('user_id', userId);

    final Map<String, double> result = {};
    for (final row in res as List) {
      result[row['sector']] = (row['amount'] as num).toDouble();
    }
    return result;
  }

  Future<void> upsert(String sector, double amount) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from(_table).upsert({
      'user_id': userId,
      'sector': sector,
      'amount': amount,
    });
  }

  Future<void> delete(String sector) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase
        .from(_table)
        .delete()
        .eq('user_id', userId)
        .eq('sector', sector);
  }
}

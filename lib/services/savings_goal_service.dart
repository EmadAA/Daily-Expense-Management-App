import '../models/savings_goal_model.dart';
import '../supabase_config.dart';

class SavingsGoalService {
  final String _table = 'savings_goals';

  Future<List<SavingsGoalModel>> fetchAll() async {
    final userId = supabase.auth.currentUser!.id;
    final res = await supabase
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (res as List).map((r) => SavingsGoalModel.fromMap(r)).toList();
  }

  Future<void> add(SavingsGoalModel goal) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from(_table).insert(goal.toMap(userId));
  }

  Future<void> addToSaved(String id, double amount) async {
    final res = await supabase
        .from(_table)
        .select('saved_amount')
        .eq('id', id)
        .single();
    final current = (res['saved_amount'] as num).toDouble();
    await supabase
        .from(_table)
        .update({'saved_amount': current + amount}).eq('id', id);
  }

  Future<void> delete(String id) async {
    await supabase.from(_table).delete().eq('id', id);
  }
}

import '../models/expense_model.dart';
import '../supabase_config.dart';

class ExpenseService {
  final String _table = 'expenses';

  Future<List<ExpenseModel>> fetchAll() async {
    final res = await supabase
        .from(_table)
        .select()
        .order('created_at', ascending: false);
    return (res as List).map((row) => ExpenseModel.fromMap(row)).toList();
  }

  Future<void> add(ExpenseModel expense) async {
    final userId = supabase.auth.currentUser!.id;
    final data = expense.toMap(userId);
    data.remove('id');
    await supabase.from(_table).insert(data);
  }

  Future<void> update(ExpenseModel expense) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase
        .from(_table)
        .update(expense.toMap(userId))
        .eq('id', expense.id);
  }

  Future<void> delete(String id) async {
    final res = await supabase
        .from(_table)
        .select('amount, source_type, source_id')
        .eq('id', id)
        .single();

    final amount = (res['amount'] as num).toDouble();
    final sourceType = res['source_type'] as String?;
    final sourceId = res['source_id'] as String?;

    await supabase.from(_table).delete().eq('id', id);

    // If this was a goal savings expense, reduce saved_amount on goal
    if (sourceType == 'goal' && sourceId != null) {
      final goalRes = await supabase
          .from('savings_goals')
          .select('saved_amount')
          .eq('id', sourceId)
          .maybeSingle();

      if (goalRes != null) {
        final current = (goalRes['saved_amount'] as num).toDouble();
        await supabase.from('savings_goals').update({
          'saved_amount': (current - amount).clamp(0, double.infinity)
        }).eq('id', sourceId);
      }
    }

    // If this was a loan given expense, reduce paid tracking on loan
    if (sourceType == 'loan_repayment' && sourceId != null) {
      final loanRes = await supabase
          .from('loans')
          .select('paid_amount')
          .eq('id', sourceId)
          .maybeSingle();

      if (loanRes != null) {
        final current = (loanRes['paid_amount'] as num).toDouble();
        await supabase.from('loans').update({
          'paid_amount': (current - amount).clamp(0, double.infinity)
        }).eq('id', sourceId);
      }
    }
  }
}

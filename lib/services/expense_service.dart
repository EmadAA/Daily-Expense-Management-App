import '../models/expense_model.dart';
import '../supabase_config.dart';

class ExpenseService {
  final String _table = 'expenses';

  Future<List<ExpenseModel>> fetchAll() async {
    final userId = supabase.auth.currentUser!.id;
    final res = await supabase
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);
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
    final data = expense.toMap(userId);
    data.remove('id'); // ID is used in the where clause
    await supabase.from(_table).update(data).eq('id', expense.id);
  }

  Future<void> delete(String id) async {
    // 1. Fetch details before deleting
    final res = await supabase
        .from(_table)
        .select('amount, source_type, source_id')
        .eq('id', id)
        .single();

    final amount = (res['amount'] as num).toDouble();
    final sourceType = res['source_type'] as String?;
    final sourceId = res['source_id'] as String?;

    // 2. Delete the expense
    await supabase.from(_table).delete().eq('id', id);

    // 3. Handle Cascade Logic
    if (sourceType != null && sourceId != null) {
      // If this was a goal savings expense, reduce saved_amount on goal
      if (sourceType == 'goal') {
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

      // If this was a loan repayment, reduce paid_amount on loan
      if (sourceType == 'loan_repayment') {
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

      // If this was an account deposit, decrease the account balance
      if (sourceType == 'account') {
        final accRes = await supabase
            .from('accounts')
            .select('balance')
            .eq('id', sourceId)
            .maybeSingle();
        if (accRes != null) {
          final current = (accRes['balance'] as num).toDouble();
          // Deposit adds to account, so deleting it subtracts
          final newBalance = (current - amount).clamp(0, double.infinity);
          await supabase
              .from('accounts')
              .update({'balance': newBalance}).eq('id', sourceId);
        }
      }
    }
  }
}

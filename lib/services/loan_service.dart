import '../models/loan_model.dart';
import '../supabase_config.dart';

class LoanService {
  final String _table = 'loans';

  Future<List<LoanModel>> fetchAll() async {
    final userId = supabase.auth.currentUser!.id;
    final res = await supabase
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (res as List).map((r) => LoanModel.fromMap(r)).toList();
  }

  Future<String> add(LoanModel loan) async {
    final userId = supabase.auth.currentUser!.id;
    final res = await supabase
        .from(_table)
        .insert(loan.toMap(userId))
        .select('id')
        .single();
    return res['id'] as String;
  }

  Future<void> markPaid(String id, double amount) async {
    final res =
        await supabase.from(_table).select('paid_amount').eq('id', id).single();
    final current = (res['paid_amount'] as num).toDouble();
    await supabase
        .from(_table)
        .update({'paid_amount': current + amount}).eq('id', id);
  }

  Future<void> delete(String id) async {
    // Delete all income/expense entries linked to this loan
    await supabase.from('expenses').delete().eq('source_id', id);

    await supabase.from('incomes').delete().eq('source_id', id);

    // Delete the loan itself
    await supabase.from(_table).delete().eq('id', id);
  }
}

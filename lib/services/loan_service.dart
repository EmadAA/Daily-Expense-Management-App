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

  Future<void> add(LoanModel loan) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from(_table).insert(loan.toMap(userId));
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
    await supabase.from(_table).delete().eq('id', id);
  }
}

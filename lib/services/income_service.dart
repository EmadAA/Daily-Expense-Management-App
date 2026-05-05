import '../models/income_model.dart';
import '../supabase_config.dart';

class IncomeService {
  final String _table = 'incomes';

  Future<List<IncomeModel>> fetchAll() async {
    final res = await supabase
        .from(_table)
        .select()
        .order('created_at', ascending: false);
    return (res as List).map((row) => IncomeModel.fromMap(row)).toList();
  }

  Future<void> add(IncomeModel income) async {
    final userId = supabase.auth.currentUser!.id;
    final data = income.toMap(userId);
    data.remove('id');
    await supabase.from(_table).insert(data);
  }

  Future<void> update(IncomeModel income) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase
        .from(_table)
        .update(income.toMap(userId))
        .eq('id', income.id);
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

    // If this was a loan repayment income, reduce paid_amount on loan
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

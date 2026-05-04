import '../models/income_model.dart';
import '../supabase_config.dart';

class IncomeService {
  final String _table = 'incomes';

  Future<List<IncomeModel>> fetchAll() async {
    final res =
        await supabase.from(_table).select().order('date', ascending: false);
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
    await supabase.from(_table).delete().eq('id', id);
  }
}

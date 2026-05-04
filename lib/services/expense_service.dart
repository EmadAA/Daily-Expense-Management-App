import '../models/expense_model.dart';
import '../supabase_config.dart';

class ExpenseService {
  final String _table = 'expenses';

  Future<List<ExpenseModel>> fetchAll() async {
    final res =
        await supabase.from(_table).select().order('date', ascending: false);
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
    await supabase.from(_table).delete().eq('id', id);
  }
}

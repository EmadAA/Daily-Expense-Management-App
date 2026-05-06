import '../models/account_model.dart';
import '../supabase_config.dart';

class AccountService {
  final String _table = 'accounts';

  Future<List<AccountModel>> fetchAll() async {
    final userId = supabase.auth.currentUser!.id;
    final res = await supabase
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (res as List).map((r) => AccountModel.fromMap(r)).toList();
  }

  Future<void> add(AccountModel account) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from(_table).insert(account.toMap(userId));
  }

  Future<void> update(String id, String name, String color) async {
    await supabase
        .from(_table)
        .update({'name': name, 'color': color}).eq('id', id);
  }

  Future<void> adjustBalance(String id, double amount) async {
    final res =
        await supabase.from(_table).select('balance').eq('id', id).single();
    final current = (res['balance'] as num).toDouble();
    final newBalance = (current + amount).clamp(0.0, double.infinity);
    await supabase.from(_table).update({'balance': newBalance}).eq('id', id);
  }

  Future<void> delete(String id) async {
    // Cascade delete linked transactions
    await supabase
        .from('expenses')
        .delete()
        .eq('source_id', id)
        .eq('source_type', 'account');
    await supabase
        .from('incomes')
        .delete()
        .eq('source_id', id)
        .eq('source_type', 'account');
    await supabase.from(_table).delete().eq('id', id);
  }
}

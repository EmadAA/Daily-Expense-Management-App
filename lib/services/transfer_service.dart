import '../models/transfer_model.dart';
import '../supabase_config.dart';

class TransferService {
  Future<List<TransferModel>> fetchAll() async {
    final userId = supabase.auth.currentUser!.id;
    final res = await supabase
        .from('transfers')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);
    return (res as List).map((r) => TransferModel.fromMap(r)).toList();
  }

  Future<void> transfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required String note,
    required DateTime date,
  }) async {
    final userId = supabase.auth.currentUser!.id;

    // Get current balances
    final fromRes = await supabase
        .from('accounts')
        .select('balance')
        .eq('id', fromAccountId)
        .single();
    final toRes = await supabase
        .from('accounts')
        .select('balance')
        .eq('id', toAccountId)
        .single();

    final fromBalance = (fromRes['balance'] as num).toDouble();
    final toBalance = (toRes['balance'] as num).toDouble();

    if (fromBalance < amount) {
      throw Exception('Insufficient balance in source account');
    }

    // Update both balances
    await supabase
        .from('accounts')
        .update({'balance': fromBalance - amount}).eq('id', fromAccountId);

    await supabase
        .from('accounts')
        .update({'balance': toBalance + amount}).eq('id', toAccountId);

    // Record the transfer
    await supabase.from('transfers').insert({
      'user_id': userId,
      'from_account': fromAccountId,
      'to_account': toAccountId,
      'amount': amount,
      'note': note,
      'date': date.toIso8601String().substring(0, 10),
    });
  }

  Future<void> delete(String id,
      {required String fromAccountId,
      required String toAccountId,
      required double amount}) async {
    // Reverse the balance changes
    final fromRes = await supabase
        .from('accounts')
        .select('balance')
        .eq('id', fromAccountId)
        .single();
    final toRes = await supabase
        .from('accounts')
        .select('balance')
        .eq('id', toAccountId)
        .single();

    await supabase.from('accounts').update({
      'balance': (fromRes['balance'] as num).toDouble() + amount
    }).eq('id', fromAccountId);

    await supabase
        .from('accounts')
        .update({'balance': (toRes['balance'] as num).toDouble() - amount}).eq(
            'id', toAccountId);

    await supabase.from('transfers').delete().eq('id', id);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/account_model.dart';
import '../services/account_service.dart';

final accountServiceProvider = Provider((ref) => AccountService());

class AccountNotifier extends StateNotifier<AsyncValue<List<AccountModel>>> {
  final AccountService _service;
  AccountNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchAll();
  }

  Future<void> fetchAll() async {
    state = const AsyncValue.loading();
    try {
      final data = await _service.fetchAll();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(AccountModel account) async {
    await _service.add(account);
    await fetchAll();
  }

  Future<void> adjustBalance(String id, double amount) async {
    await _service.adjustBalance(id, amount);
    await fetchAll();
  }

  Future<void> delete(String id) async {
    await _service.delete(id);
    await fetchAll();
  }
}

final accountProvider =
    StateNotifierProvider<AccountNotifier, AsyncValue<List<AccountModel>>>(
  (ref) => AccountNotifier(ref.read(accountServiceProvider)),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense_model.dart';
import '../services/expense_service.dart';

final expenseServiceProvider = Provider((ref) => ExpenseService());

class ExpenseNotifier extends StateNotifier<AsyncValue<List<ExpenseModel>>> {
  final ExpenseService _service;

  ExpenseNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchAll();
  }

  Future<void> fetchAll() async {
    // Guard: don't update if already disposed
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final data = await _service.fetchAll();
      if (!mounted) return; // check again after await
      state = AsyncValue.data(data);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(ExpenseModel expense) async {
    await _service.add(expense);
    if (!mounted) return;
    await fetchAll();
  }

  Future<void> update(ExpenseModel expense) async {
    await _service.update(expense);
    if (!mounted) return;
    await fetchAll();
  }

  Future<void> delete(String id) async {
    await _service.delete(id);
    if (!mounted) return;
    await fetchAll();
  }
}

final expenseProvider =
    StateNotifierProvider<ExpenseNotifier, AsyncValue<List<ExpenseModel>>>(
  (ref) => ExpenseNotifier(ref.read(expenseServiceProvider)),
);

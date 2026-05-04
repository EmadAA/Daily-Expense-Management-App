import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/budget_service.dart';

final budgetServiceProvider = Provider((ref) => BudgetService());

class BudgetNotifier extends StateNotifier<AsyncValue<Map<String, double>>> {
  final BudgetService _service;

  BudgetNotifier(this._service) : super(const AsyncValue.loading()) {
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

  Future<void> upsert(String sector, double amount) async {
    await _service.upsert(sector, amount);
    await fetchAll();
  }

  Future<void> delete(String sector) async {
    await _service.delete(sector);
    await fetchAll();
  }
}

final budgetProvider =
    StateNotifierProvider<BudgetNotifier, AsyncValue<Map<String, double>>>(
  (ref) => BudgetNotifier(ref.read(budgetServiceProvider)),
);

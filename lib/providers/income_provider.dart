import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/income_model.dart';
import '../services/income_service.dart';

final incomeServiceProvider = Provider((ref) => IncomeService());

class IncomeNotifier extends StateNotifier<AsyncValue<List<IncomeModel>>> {
  final IncomeService _service;

  IncomeNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchAll();
  }

  Future<void> fetchAll() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final data = await _service.fetchAll();
      if (!mounted) return;
      state = AsyncValue.data(data);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(IncomeModel income) async {
    await _service.add(income);
    if (!mounted) return;
    await fetchAll();
  }

  Future<void> update(IncomeModel income) async {
    await _service.update(income);
    if (!mounted) return;
    await fetchAll();
  }

  Future<void> delete(String id) async {
    await _service.delete(id);
    if (!mounted) return;
    await fetchAll();
  }
}

final incomeProvider =
    StateNotifierProvider<IncomeNotifier, AsyncValue<List<IncomeModel>>>(
  (ref) => IncomeNotifier(ref.read(incomeServiceProvider)),
);

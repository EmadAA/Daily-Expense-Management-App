import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/savings_goal_model.dart';
import '../services/savings_goal_service.dart';

final savingsGoalServiceProvider = Provider((ref) => SavingsGoalService());

class SavingsGoalNotifier
    extends StateNotifier<AsyncValue<List<SavingsGoalModel>>> {
  final SavingsGoalService _service;

  SavingsGoalNotifier(this._service) : super(const AsyncValue.loading()) {
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

  Future<void> add(SavingsGoalModel goal) async {
    await _service.add(goal);
    await fetchAll();
  }

  Future<void> addToSaved(String id, double amount) async {
    await _service.addToSaved(id, amount);
    await fetchAll();
  }

  Future<void> delete(String id, String title) async {
    await _service.delete(id, title);
    await fetchAll();
  }
}

final savingsGoalProvider = StateNotifierProvider<SavingsGoalNotifier,
    AsyncValue<List<SavingsGoalModel>>>(
  (ref) => SavingsGoalNotifier(ref.read(savingsGoalServiceProvider)),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recurring_model.dart';
import '../services/recurring_service.dart';

final recurringServiceProvider = Provider((ref) => RecurringService());

class RecurringNotifier
    extends StateNotifier<AsyncValue<List<RecurringModel>>> {
  final RecurringService _service;

  RecurringNotifier(this._service) : super(const AsyncValue.loading()) {
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

  Future<void> add(RecurringModel r) async {
    await _service.add(r);
    await fetchAll();
  }

  Future<void> delete(String id) async {
    await _service.delete(id);
    await fetchAll();
  }

  Future<void> processDue() async {
    await _service.processDue();
  }
}

final recurringProvider =
    StateNotifierProvider<RecurringNotifier, AsyncValue<List<RecurringModel>>>(
  (ref) => RecurringNotifier(ref.read(recurringServiceProvider)),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/loan_model.dart';
import '../services/loan_service.dart';

final loanServiceProvider = Provider((ref) => LoanService());

class LoanNotifier extends StateNotifier<AsyncValue<List<LoanModel>>> {
  final LoanService _service;

  LoanNotifier(this._service) : super(const AsyncValue.loading()) {
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

  Future<void> add(LoanModel loan) async {
    await _service.add(loan);
    await fetchAll();
  }

  Future<void> markPaid(String id, double amount) async {
    await _service.markPaid(id, amount);
    await fetchAll();
  }

  Future<void> delete(String id) async {
    await _service.delete(id);
    await fetchAll();
  }
}

final loanProvider =
    StateNotifierProvider<LoanNotifier, AsyncValue<List<LoanModel>>>(
  (ref) => LoanNotifier(ref.read(loanServiceProvider)),
);

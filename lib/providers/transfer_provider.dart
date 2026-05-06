import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transfer_model.dart';
import '../services/transfer_service.dart';

final transferServiceProvider = Provider((ref) => TransferService());

class TransferNotifier extends StateNotifier<AsyncValue<List<TransferModel>>> {
  final TransferService _service;
  TransferNotifier(this._service) : super(const AsyncValue.loading()) {
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

  Future<void> transfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required String note,
    required DateTime date,
  }) async {
    await _service.transfer(
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      amount: amount,
      note: note,
      date: date,
    );
    await fetchAll();
  }

  Future<void> delete(
    String id, {
    required String fromAccountId,
    required String toAccountId,
    required double amount,
  }) async {
    await _service.delete(id,
        fromAccountId: fromAccountId, toAccountId: toAccountId, amount: amount);
    await fetchAll();
  }
}

final transferProvider =
    StateNotifierProvider<TransferNotifier, AsyncValue<List<TransferModel>>>(
  (ref) => TransferNotifier(ref.read(transferServiceProvider)),
);

class TransferModel {
  final String id;
  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final String note;
  final DateTime date;

  TransferModel({
    required this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.note,
    required this.date,
  });

  factory TransferModel.fromMap(Map<String, dynamic> map) {
    return TransferModel(
      id: map['id'],
      fromAccountId: map['from_account'],
      toAccountId: map['to_account'],
      amount: (map['amount'] as num).toDouble(),
      note: map['note'] ?? '',
      date: DateTime.parse(map['date']),
    );
  }

  Map<String, dynamic> toMap(String userId) {
    return {
      'user_id': userId,
      'from_account': fromAccountId,
      'to_account': toAccountId,
      'amount': amount,
      'note': note,
      'date': date.toIso8601String().substring(0, 10),
    };
  }
}

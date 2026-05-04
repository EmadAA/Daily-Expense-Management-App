class LoanModel {
  final String id;
  final String type; // 'lent' or 'borrowed'
  final String personName;
  final double amount;
  final double paidAmount;
  final DateTime? dueDate;
  final String note;
  final DateTime createdAt;

  LoanModel({
    required this.id,
    required this.type,
    required this.personName,
    required this.amount,
    required this.paidAmount,
    this.dueDate,
    required this.note,
    required this.createdAt,
  });

  double get remaining => (amount - paidAmount).clamp(0, double.infinity);
  bool get isSettled => paidAmount >= amount;
  bool get isLent => type == 'lent';

  int? get daysUntilDue =>
      dueDate != null ? dueDate!.difference(DateTime.now()).inDays : null;

  factory LoanModel.fromMap(Map<String, dynamic> map) {
    return LoanModel(
      id: map['id'],
      type: map['type'],
      personName: map['person_name'],
      amount: (map['amount'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num).toDouble(),
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      note: map['note'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap(String userId) {
    return {
      'user_id': userId,
      'type': type,
      'person_name': personName,
      'amount': amount,
      'paid_amount': paidAmount,
      'due_date': dueDate?.toIso8601String().substring(0, 10),
      'note': note,
    };
  }
}

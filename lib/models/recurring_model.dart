class RecurringModel {
  final String id;
  final String type; // 'income' or 'expense'
  final String sector;
  final String details;
  final double amount;
  final int dayOfMonth;
  final DateTime? lastAdded;

  RecurringModel({
    required this.id,
    required this.type,
    required this.sector,
    required this.details,
    required this.amount,
    required this.dayOfMonth,
    this.lastAdded,
  });

  factory RecurringModel.fromMap(Map<String, dynamic> map) {
    return RecurringModel(
      id: map['id'],
      type: map['type'],
      sector: map['sector'],
      details: map['details'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      dayOfMonth: map['day_of_month'],
      lastAdded:
          map['last_added'] != null ? DateTime.parse(map['last_added']) : null,
    );
  }

  Map<String, dynamic> toMap(String userId) {
    return {
      'user_id': userId,
      'type': type,
      'sector': sector,
      'details': details,
      'amount': amount,
      'day_of_month': dayOfMonth,
    };
  }
}

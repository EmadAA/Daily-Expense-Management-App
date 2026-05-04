class IncomeModel {
  final String id;
  final String sector;
  final String details;
  final double amount;
  final DateTime date;
  final String currency;
  final String? receiptUrl;

  IncomeModel({
    required this.id,
    required this.sector,
    required this.details,
    required this.amount,
    required this.date,
    this.currency = 'BDT',
    this.receiptUrl,
  });

  factory IncomeModel.fromMap(Map<String, dynamic> map) {
    return IncomeModel(
      id: map['id'],
      sector: map['sector'],
      details: map['details'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date']),
      currency: map['currency'] ?? 'BDT',
      receiptUrl: map['receipt_url'],
    );
  }

  Map<String, dynamic> toMap(String userId) {
    return {
      'user_id': userId,
      'sector': sector,
      'details': details,
      'amount': amount,
      'date': date.toIso8601String().substring(0, 10),
      'currency': currency,
      'receipt_url': receiptUrl,
    };
  }
}

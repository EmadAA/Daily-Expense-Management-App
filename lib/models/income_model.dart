class IncomeModel {
  final String id;
  final String sector;
  final String details;
  final double amount;
  final DateTime date;
  final String currency;
  final String category; // Added category field
  final String? receiptUrl;
  final String? sourceType;
  final String? sourceId;

  IncomeModel({
    required this.id,
    required this.sector,
    required this.details,
    required this.amount,
    required this.date,
    this.currency = 'BDT',
    required this.category, // Required parameter
    this.receiptUrl,
    this.sourceType,
    this.sourceId,
  });

  factory IncomeModel.fromMap(Map<String, dynamic> map) {
    return IncomeModel(
      id: map['id'],
      sector: map['sector'],
      details: map['details'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date']),
      currency: map['currency'] ?? 'BDT',
      category: map['category'] ?? 'Other', // Default to Other
      receiptUrl: map['receipt_url'],
      sourceType: map['source_type'],
      sourceId: map['source_id'],
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
      'category': category, // Added category to map
      'receipt_url': receiptUrl,
      'source_type': sourceType,
      'source_id': sourceId,
    };
  }
}
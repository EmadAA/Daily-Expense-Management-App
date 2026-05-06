class AccountModel {
  final String id;
  final String name;
  final double balance;
  final String color;
  final DateTime createdAt;

  AccountModel({
    required this.id,
    required this.name,
    required this.balance,
    this.color = '#378ADD',
    required this.createdAt,
  });

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'],
      name: map['name'],
      balance: (map['balance'] as num).toDouble(),
      color: map['color'] ?? '#378ADD',
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap(String userId) {
    return {
      'user_id': userId,
      'name': name,
      'balance': balance,
      'color': color,
    };
  }
}

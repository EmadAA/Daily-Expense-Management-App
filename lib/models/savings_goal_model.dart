class SavingsGoalModel {
  final String id;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final DateTime? deadline;
  final String color;

  SavingsGoalModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    this.deadline,
    required this.color,
  });

  double get percentage =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  double get remaining =>
      (targetAmount - savedAmount).clamp(0, double.infinity);

  bool get isCompleted => savedAmount >= targetAmount;

  int? get daysLeft =>
      deadline != null ? deadline!.difference(DateTime.now()).inDays : null;

  factory SavingsGoalModel.fromMap(Map<String, dynamic> map) {
    return SavingsGoalModel(
      id: map['id'],
      title: map['title'],
      targetAmount: (map['target_amount'] as num).toDouble(),
      savedAmount: (map['saved_amount'] as num).toDouble(),
      deadline:
          map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
      color: map['color'] ?? '#1D9E75',
    );
  }

  Map<String, dynamic> toMap(String userId) {
    return {
      'user_id': userId,
      'title': title,
      'target_amount': targetAmount,
      'saved_amount': savedAmount,
      'deadline': deadline?.toIso8601String().substring(0, 10),
      'color': color,
    };
  }
}

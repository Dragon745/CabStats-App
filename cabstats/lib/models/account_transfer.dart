class AccountTransfer {
  final String id;
  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final String? note;
  final DateTime timestamp;

  AccountTransfer({
    required this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    this.note,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromAccountId': fromAccountId,
      'toAccountId': toAccountId,
      'amount': amount,
      'note': note,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory AccountTransfer.fromJson(Map<String, dynamic> json) {
    return AccountTransfer(
      id: json['id'],
      fromAccountId: json['fromAccountId'],
      toAccountId: json['toAccountId'],
      amount: (json['amount'] as num).toDouble(),
      note: json['note'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }
}

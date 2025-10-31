import 'package:hive/hive.dart';

part 'account_transfer.g.dart';

@HiveType(typeId: 6)
class AccountTransfer {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String fromAccountId;
  @HiveField(2)
  final String toAccountId;
  @HiveField(3)
  final double amount;
  @HiveField(4)
  final String? note;
  @HiveField(5)
  final DateTime timestamp;
  @HiveField(6)
  final DateTime lastModified;

  AccountTransfer({
    required this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    this.note,
    required this.timestamp,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromAccountId': fromAccountId,
      'toAccountId': toAccountId,
      'amount': amount,
      'note': note,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'lastModified': lastModified.millisecondsSinceEpoch,
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
      lastModified: json['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastModified'])
          : DateTime.now(),
    );
  }
}

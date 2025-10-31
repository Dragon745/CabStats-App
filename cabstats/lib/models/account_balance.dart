import 'package:hive/hive.dart';

part 'account_balance.g.dart';

@HiveType(typeId: 10)
class AccountBalance {
  @HiveField(0)
  final String accountId;
  @HiveField(1)
  final String accountName;
  @HiveField(2)
  final String accountType;
  @HiveField(3)
  final double balance;
  @HiveField(4)
  final DateTime lastUpdated;
  @HiveField(5)
  final DateTime lastModified;

  AccountBalance({
    required this.accountId,
    required this.accountName,
    required this.accountType,
    required this.balance,
    required this.lastUpdated,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'accountName': accountName,
      'accountType': accountType,
      'balance': balance,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'lastModified': lastModified.millisecondsSinceEpoch,
    };
  }

  factory AccountBalance.fromJson(Map<String, dynamic> json) {
    return AccountBalance(
      accountId: json['accountId'],
      accountName: json['accountName'],
      accountType: json['accountType'],
      balance: (json['balance'] as num).toDouble(),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['lastUpdated']),
      lastModified: json['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastModified'])
          : DateTime.now(),
    );
  }

  AccountBalance copyWith({
    String? accountId,
    String? accountName,
    String? accountType,
    double? balance,
    DateTime? lastUpdated,
    DateTime? lastModified,
  }) {
    return AccountBalance(
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      accountType: accountType ?? this.accountType,
      balance: balance ?? this.balance,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastModified: lastModified ?? DateTime.now(),
    );
  }
}


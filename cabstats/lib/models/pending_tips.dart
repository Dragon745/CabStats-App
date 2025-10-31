import 'package:hive/hive.dart';

part 'pending_tips.g.dart';

@HiveType(typeId: 9)
class PendingTips {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final double amount;
  @HiveField(2)
  final List<String> rideIds; // Track which rides contributed
  @HiveField(3)
  final DateTime lastUpdated;
  @HiveField(4)
  final DateTime lastModified;

  PendingTips({
    required this.id,
    required this.amount,
    required this.rideIds,
    required this.lastUpdated,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'rideIds': rideIds,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'lastModified': lastModified.millisecondsSinceEpoch,
    };
  }

  factory PendingTips.fromJson(Map<String, dynamic> json) {
    return PendingTips(
      id: json['id'],
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      rideIds: List<String>.from(json['rideIds'] ?? []),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'])
          : DateTime.now(),
      lastModified: json['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastModified'])
          : DateTime.now(),
    );
  }
}


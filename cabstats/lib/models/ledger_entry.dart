import 'package:hive/hive.dart';

part 'ledger_entry.g.dart';

@HiveType(typeId: 2)
enum TransactionType {
  @HiveField(0)
  debit,  // Money going out (fees, expenses)
  @HiveField(1)
  credit, // Money coming in (payments received)
}

@HiveType(typeId: 3)
enum TransactionCategory {
  @HiveField(0)
  tollFee,
  @HiveField(1)
  platformFee,
  @HiveField(2)
  airportFee,
  @HiveField(3)
  parkingFee,
  @HiveField(4)
  fuel,
  @HiveField(5)
  cigarettes,
  @HiveField(6)
  tea,
  @HiveField(7)
  water,
  @HiveField(8)
  food,
  @HiveField(9)
  goodies,
  @HiveField(10)
  cleaning,
  @HiveField(11)
  withdrawal,
  @HiveField(12)
  saving,
  @HiveField(13)
  rent,
  @HiveField(14)
  tireMaintenance,
  @HiveField(15)
  otherFee,
  @HiveField(16)
  paymentReceived,
  @HiveField(17)
  rideStart,
  @HiveField(18)
  rideEnd,
  @HiveField(19)
  rideCancel,
  @HiveField(20)
  adjustment,
}

@HiveType(typeId: 4)
enum TransactionNature {
  @HiveField(0)
  earning,    // Money earned (ride payments, tips)
  @HiveField(1)
  expense,    // Money spent (fuel, maintenance, etc.)
  @HiveField(2)
  transfer,   // Internal transfer between accounts
  @HiveField(3)
  adjustment, // Manual balance adjustment
}

@HiveType(typeId: 5)
class LedgerEntry {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String accountId;
  @HiveField(2)
  final String rideId;
  @HiveField(3)
  final TransactionType type;
  @HiveField(4)
  final TransactionCategory category;
  @HiveField(5)
  final TransactionNature nature;
  @HiveField(6)
  final double amount;
  @HiveField(7)
  final String description;
  @HiveField(8)
  final DateTime timestamp;
  @HiveField(9)
  final String? reference; // Optional reference (like ride ID)
  @HiveField(10)
  final DateTime lastModified;

  LedgerEntry({
    required this.id,
    required this.accountId,
    required this.rideId,
    required this.type,
    required this.category,
    required this.nature,
    required this.amount,
    required this.description,
    required this.timestamp,
    this.reference,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  // Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'rideId': rideId,
      'type': type.name,
      'category': category.name,
      'nature': nature.name,
      'amount': amount,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'reference': reference,
      'lastModified': lastModified.millisecondsSinceEpoch,
    };
  }

  // Create from JSON
  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      id: json['id'],
      accountId: json['accountId'],
      rideId: json['rideId'],
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.debit,
      ),
      category: TransactionCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => TransactionCategory.adjustment,
      ),
      nature: TransactionNature.values.firstWhere(
        (e) => e.name == json['nature'],
        orElse: () => TransactionNature.adjustment,
      ),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      reference: json['reference'],
      lastModified: json['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastModified'])
          : DateTime.now(),
    );
  }

  // Get formatted amount with sign
  String get formattedAmount {
    final sign = type == TransactionType.debit ? '-' : '+';
    return '$sign₹${amount.toStringAsFixed(2)}';
  }

  // Get formatted timestamp
  String get formattedTimestamp {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  // Get category display name
  String get categoryDisplayName {
    switch (category) {
      case TransactionCategory.tollFee:
        return 'Toll Fee';
      case TransactionCategory.platformFee:
        return 'Platform Fee';
      case TransactionCategory.airportFee:
        return 'Airport Fee';
      case TransactionCategory.parkingFee:
        return 'Parking Fee';
      case TransactionCategory.fuel:
        return 'Fuel';
      case TransactionCategory.cigarettes:
        return 'Cigarettes';
      case TransactionCategory.tea:
        return 'Tea';
      case TransactionCategory.water:
        return 'Water';
      case TransactionCategory.food:
        return 'Food';
      case TransactionCategory.goodies:
        return 'Goodies';
      case TransactionCategory.cleaning:
        return 'Cleaning';
      case TransactionCategory.withdrawal:
        return 'Withdrawal';
      case TransactionCategory.saving:
        return 'Saving';
      case TransactionCategory.rent:
        return 'Rent';
      case TransactionCategory.tireMaintenance:
        return 'Tire Maintenance';
      case TransactionCategory.otherFee:
        return 'Miscellaneous';
      case TransactionCategory.paymentReceived:
        return 'Payment Received';
      case TransactionCategory.rideStart:
        return 'Ride Started';
      case TransactionCategory.rideEnd:
        return 'Ride Completed';
      case TransactionCategory.rideCancel:
        return 'Ride Cancelled';
      case TransactionCategory.adjustment:
        return 'Adjustment';
    }
  }

  // Get nature display name
  String get natureDisplayName {
    switch (nature) {
      case TransactionNature.earning:
        return 'Earning';
      case TransactionNature.expense:
        return 'Expense';
      case TransactionNature.transfer:
        return 'Transfer';
      case TransactionNature.adjustment:
        return 'Adjustment';
    }
  }
}

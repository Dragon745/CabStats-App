import 'package:flutter/material.dart';

enum TransactionType {
  debit,  // Money going out (fees, expenses)
  credit, // Money coming in (payments received)
}

enum TransactionCategory {
  tollFee,
  platformFee,
  airportFee,
  parkingFee,
  fuel,
  cigarettes,
  tea,
  water,
  food,
  goodies,
  cleaning,
  withdrawal,
  saving,
  rent,
  otherFee,
  paymentReceived,
  rideStart,
  rideEnd,
  rideCancel,
  adjustment,
}

enum TransactionNature {
  earning,    // Money earned (ride payments, tips)
  expense,    // Money spent (fuel, maintenance, etc.)
  transfer,   // Internal transfer between accounts
  adjustment, // Manual balance adjustment
}

class LedgerEntry {
  final String id;
  final String accountId;
  final String rideId;
  final TransactionType type;
  final TransactionCategory category;
  final TransactionNature nature;
  final double amount;
  final String description;
  final DateTime timestamp;
  final String? reference; // Optional reference (like ride ID)

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
  });

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
      case TransactionCategory.otherFee:
        return 'Other Fee';
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

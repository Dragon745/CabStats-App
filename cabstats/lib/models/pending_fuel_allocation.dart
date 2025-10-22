class PendingFuelAllocation {
  final String id;
  final double amount;
  final DateTime lastUpdated;
  final List<String> rideIds; // Track which rides contributed
  
  PendingFuelAllocation({
    required this.id,
    required this.amount,
    required this.lastUpdated,
    required this.rideIds,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'rideIds': rideIds,
    };
  }
  
  factory PendingFuelAllocation.fromJson(Map<String, dynamic> json) {
    return PendingFuelAllocation(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['lastUpdated']),
      rideIds: List<String>.from(json['rideIds'] ?? []),
    );
  }
}

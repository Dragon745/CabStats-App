import 'package:cloud_firestore/cloud_firestore.dart';

enum RideStatus { active, completed, cancelled }

class Ride {
  final String id;
  final String userId;
  final String startLocality;
  final String? endLocality;
  final DateTime startTime;
  final DateTime? endTime;
  final double km;
  final double fare;
  final double tollFee;
  final double platformFee;
  final double otherFee;
  final double airportFee;
  final Map<String, double> paymentSplits; // accountId -> amount
  final String tollFeeAccount;
  final String platformFeeAccount;
  final String otherFeeAccount;
  final String airportFeeAccount;
  final RideStatus status;
  
  // Calculated fields (mutable for calculations)
  double? tip;
  double? profit;
  double? fuelAllocation;
  double? profitPerKm;
  double? profitPerMin;

  Ride({
    required this.id,
    required this.userId,
    required this.startLocality,
    this.endLocality,
    required this.startTime,
    this.endTime,
    required this.km,
    required this.fare,
    required this.tollFee,
    required this.platformFee,
    required this.otherFee,
    required this.airportFee,
    required this.paymentSplits,
    required this.tollFeeAccount,
    required this.platformFeeAccount,
    required this.otherFeeAccount,
    required this.airportFeeAccount,
    required this.status,
    this.tip,
    this.profit,
    this.fuelAllocation,
    this.profitPerKm,
    this.profitPerMin,
  });

  // Calculate total amount received from all payment splits
  double getTotalAmountReceived() {
    return paymentSplits.values.fold(0.0, (sum, amount) => sum + amount);
  }

  // Calculate tip
  double calculateTip() {
    return getTotalAmountReceived() - fare - platformFee - otherFee - airportFee - tollFee;
  }

  // Calculate profit
  double calculateProfit() {
    return getTotalAmountReceived() - platformFee - otherFee - airportFee - tollFee;
  }

  // Calculate fuel allocation (half of profit)
  double calculateFuelAllocation() {
    return calculateProfit() / 2;
  }

  // Calculate profit per KM
  double calculateProfitPerKm() {
    if (km <= 0) return 0.0;
    return calculateProfit() / km;
  }

  // Calculate profit per minute
  double calculateProfitPerMin() {
    final durationMinutes = getDurationMinutes();
    if (durationMinutes <= 0) return 0.0;
    return calculateProfit() / durationMinutes;
  }

  // Get duration in minutes
  double getDurationMinutes() {
    if (endTime == null) return 0.0;
    return endTime!.difference(startTime).inMinutes.toDouble();
  }

  // Get duration as formatted string (HH:MM:SS)
  String getDurationString() {
    if (endTime == null) {
      final now = DateTime.now();
      final duration = now.difference(startTime);
      return _formatDuration(duration);
    }
    return _formatDuration(endTime!.difference(startTime));
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'startLocality': startLocality,
      'endLocality': endLocality,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'km': km,
      'fare': fare,
      'tollFee': tollFee,
      'platformFee': platformFee,
      'otherFee': otherFee,
      'airportFee': airportFee,
      'paymentSplits': paymentSplits,
      'tollFeeAccount': tollFeeAccount,
      'platformFeeAccount': platformFeeAccount,
      'otherFeeAccount': otherFeeAccount,
      'airportFeeAccount': airportFeeAccount,
      'status': status.name,
      'tip': tip,
      'profit': profit,
      'fuelAllocation': fuelAllocation,
      'profitPerKm': profitPerKm,
      'profitPerMin': profitPerMin,
    };
  }

  // Create from JSON
  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      startLocality: json['startLocality'] ?? '',
      endLocality: json['endLocality'],
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime'] ?? 0),
      endTime: json['endTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['endTime'])
          : null,
      km: (json['km'] ?? 0.0).toDouble(),
      fare: (json['fare'] ?? 0.0).toDouble(),
      tollFee: (json['tollFee'] ?? 0.0).toDouble(),
      platformFee: (json['platformFee'] ?? 0.0).toDouble(),
      otherFee: (json['otherFee'] ?? 0.0).toDouble(),
      airportFee: (json['airportFee'] ?? 0.0).toDouble(),
      paymentSplits: Map<String, double>.from(json['paymentSplits'] ?? {}),
      tollFeeAccount: json['tollFeeAccount'] ?? '',
      platformFeeAccount: json['platformFeeAccount'] ?? '',
      otherFeeAccount: json['otherFeeAccount'] ?? '',
      airportFeeAccount: json['airportFeeAccount'] ?? '',
      status: RideStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RideStatus.active,
      ),
      tip: (json['tip'] as num?)?.toDouble(),
      profit: (json['profit'] as num?)?.toDouble(),
      fuelAllocation: (json['fuelAllocation'] as num?)?.toDouble(),
      profitPerKm: (json['profitPerKm'] as num?)?.toDouble(),
      profitPerMin: (json['profitPerMin'] as num?)?.toDouble(),
    );
  }

  // Create from Firestore DocumentSnapshot
  factory Ride.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return Ride.fromJson(data);
  }

  // Create a copy with updated fields
  Ride copyWith({
    String? id,
    String? userId,
    String? startLocality,
    String? endLocality,
    DateTime? startTime,
    DateTime? endTime,
    double? km,
    double? fare,
    double? tollFee,
    double? platformFee,
    double? otherFee,
    double? airportFee,
    Map<String, double>? paymentSplits,
    String? tollFeeAccount,
    String? platformFeeAccount,
    String? otherFeeAccount,
    String? airportFeeAccount,
    RideStatus? status,
    double? tip,
    double? profit,
    double? fuelAllocation,
    double? profitPerKm,
    double? profitPerMin,
  }) {
    return Ride(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startLocality: startLocality ?? this.startLocality,
      endLocality: endLocality ?? this.endLocality,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      km: km ?? this.km,
      fare: fare ?? this.fare,
      tollFee: tollFee ?? this.tollFee,
      platformFee: platformFee ?? this.platformFee,
      otherFee: otherFee ?? this.otherFee,
      airportFee: airportFee ?? this.airportFee,
      paymentSplits: paymentSplits ?? this.paymentSplits,
      tollFeeAccount: tollFeeAccount ?? this.tollFeeAccount,
      platformFeeAccount: platformFeeAccount ?? this.platformFeeAccount,
      otherFeeAccount: otherFeeAccount ?? this.otherFeeAccount,
      airportFeeAccount: airportFeeAccount ?? this.airportFeeAccount,
      status: status ?? this.status,
      tip: tip ?? this.tip,
      profit: profit ?? this.profit,
      fuelAllocation: fuelAllocation ?? this.fuelAllocation,
      profitPerKm: profitPerKm ?? this.profitPerKm,
      profitPerMin: profitPerMin ?? this.profitPerMin,
    );
  }

  // Calculate all derived metrics
  void calculateMetrics() {
    final totalAmountReceived = getTotalAmountReceived();
    final totalFees = tollFee + platformFee + otherFee + airportFee;

    // Tip = Amount Received – Fare – Platform Fee – Other Fee – Airport Fee – Toll Fee
    tip = totalAmountReceived - fare - totalFees;

    // Profit = Amount Received – Platform Fee – Other Fee – Airport Fee – Toll Fee
    profit = totalAmountReceived - totalFees;

    // Fuel Allocation = Profit / 2
    fuelAllocation = profit! / 2;

    // Profit Per KM = Profit / KM
    profitPerKm = (km > 0) ? profit! / km : 0;

    // Profit Per Min = Profit / Min
    final durationMinutes = getDurationMinutes();
    profitPerMin = (durationMinutes > 0) ? profit! / durationMinutes : 0;
  }

  // Get formatted duration string (HH:MM:SS)
  String getFormattedDuration() {
    final durationMinutes = getDurationMinutes();
    if (durationMinutes <= 0) return '00:00:00';
    
    final hours = (durationMinutes / 60).floor();
    final minutes = (durationMinutes % 60).floor();
    final seconds = ((durationMinutes % 1) * 60).floor();
    
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

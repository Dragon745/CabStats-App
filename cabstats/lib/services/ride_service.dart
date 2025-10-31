import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/ride.dart';
import 'account_balance_service.dart';
import 'local_storage_service.dart';
import '../utils/debug_logger.dart';

class RideService {
  static final RideService _instance = RideService._internal();
  factory RideService() => _instance;
  RideService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _localStorage = LocalStorageService();
  final Random _random = Random();

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Generate a unique ride ID
  String _generateRideId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(10000);
    return 'ride_${timestamp}_$random';
  }

  // Start a new ride
  Future<Ride?> startRide(String startLocality) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check for existing active ride
      final existingActiveRide = await getActiveRide();
      if (existingActiveRide != null) {
        DebugLogger.logError('Cannot start new ride while another ride is active: ${existingActiveRide.id}');
        throw Exception('An active ride already exists. Please end or cancel it first.');
      }

      final rideId = _generateRideId();
      final now = DateTime.now();

      final ride = Ride(
        id: rideId,
        userId: _currentUserId!,
        startLocality: startLocality,
        startTime: now,
        km: 0.0,
        fare: 0.0,
        tollFee: 0.0,
        platformFee: 0.0,
        otherFee: 0.0,
        airportFee: 0.0,
        paymentSplits: {},
        tollFeeAccount: 'federal_bank', // Default to Main Account
        platformFeeAccount: 'federal_bank',
        otherFeeAccount: 'federal_bank',
        airportFeeAccount: 'federal_bank',
        status: RideStatus.active,
      );
      
      // Save to local storage
      await _localStorage.saveRide(ride);
      DebugLogger.log('Ride started: $rideId');
      
      return ride;
    } catch (e) {
      DebugLogger.logError('Error starting ride: $e');
      return null;
    }
  }

  // End a ride
  Future<bool> endRide(String rideId, Ride updatedRide) async {
    try {
      // If rideId is empty, get the active ride
      String targetRideId = rideId;
      if (targetRideId.trim().isEmpty) {
        final activeRide = await getActiveRide();
        if (activeRide == null) {
          throw Exception('No active ride found to end');
        }
        targetRideId = activeRide.id;
      }

      // Get existing ride to preserve data
      final existingRide = await _localStorage.getRide(targetRideId);
      if (existingRide == null) {
        throw Exception('Ride not found: $targetRideId');
      }

      final rideWithEndTime = updatedRide.copyWith(
        id: targetRideId,
        endTime: DateTime.now(),
        status: RideStatus.completed,
      );

      await _localStorage.saveRide(rideWithEndTime);
      DebugLogger.log('Ride ended: $targetRideId');
      return true;
    } catch (e) {
      DebugLogger.logError('Error ending ride: $e');
      return false;
    }
  }

  // Cancel a ride (marks as cancelled but keeps in database)
  Future<bool> cancelRide(String rideId) async {
    try {
      final existingRide = await _localStorage.getRide(rideId);
      if (existingRide == null) {
        return false;
      }

      final cancelledRide = existingRide.copyWith(
        status: RideStatus.cancelled,
        endTime: DateTime.now(),
      );
      
      await _localStorage.saveRide(cancelledRide);
      DebugLogger.log('Ride cancelled: $rideId');
      return true;
    } catch (e) {
      DebugLogger.logError('Error cancelling ride: $e');
      return false;
    }
  }

  // Get active ride
  Future<Ride?> getActiveRide() async {
    try {
      return await _localStorage.getActiveRide();
    } catch (e) {
      DebugLogger.logError('Error getting active ride: $e');
      return null;
    }
  }

  // Stream for active ride updates
  Stream<Ride?> getActiveRideStream() {
    try {
      return _localStorage.getActiveRideStream();
    } catch (e) {
      DebugLogger.logError('Error getting active ride stream: $e');
      return Stream.value(null);
    }
  }

  // Get ride history
  Future<List<Ride>> getRideHistory({int limit = 50}) async {
    try {
      DebugLogger.log('Getting ride history with limit: $limit');
      
      final allRides = await _localStorage.getAllRides();
      
      // Filter and sort: completed and cancelled, ordered by startTime descending
      final rides = allRides
          .where((ride) => ride.status != RideStatus.active)
          .toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));
      
      final limitedRides = rides.take(limit).toList();
      DebugLogger.log('Successfully retrieved ${limitedRides.length} rides from history');
      return limitedRides;
    } catch (e) {
      DebugLogger.logError('Error getting ride history: $e');
      return [];
    }
  }

  // Stream for ride history
  Stream<List<Ride>> getRideHistoryStream({int limit = 50}) {
    try {
      return _localStorage.getRidesStream().map((rides) {
        final filteredRides = rides
            .where((ride) => ride.status != RideStatus.active)
            .toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));
        return filteredRides.take(limit).toList();
      });
    } catch (e) {
      DebugLogger.logError('Error getting ride history stream: $e');
      return Stream.value([]);
    }
  }

  // Update ride (for mid-ride updates)
  Future<bool> updateRide(String rideId, Map<String, dynamic> updates) async {
    try {
      final existingRide = await _localStorage.getRide(rideId);
      if (existingRide == null) {
        return false;
      }

      // Create updated ride from existing + updates
      final updatedRide = Ride(
        id: existingRide.id,
        userId: existingRide.userId,
        startLocality: updates['startLocality'] as String? ?? existingRide.startLocality,
        endLocality: updates['endLocality'] as String? ?? existingRide.endLocality,
        startTime: updates['startTime'] != null
            ? DateTime.fromMillisecondsSinceEpoch(updates['startTime'])
            : existingRide.startTime,
        endTime: updates['endTime'] != null
            ? DateTime.fromMillisecondsSinceEpoch(updates['endTime'])
            : existingRide.endTime,
        km: (updates['km'] as num?)?.toDouble() ?? existingRide.km,
        fare: (updates['fare'] as num?)?.toDouble() ?? existingRide.fare,
        tollFee: (updates['tollFee'] as num?)?.toDouble() ?? existingRide.tollFee,
        platformFee: (updates['platformFee'] as num?)?.toDouble() ?? existingRide.platformFee,
        otherFee: (updates['otherFee'] as num?)?.toDouble() ?? existingRide.otherFee,
        airportFee: (updates['airportFee'] as num?)?.toDouble() ?? existingRide.airportFee,
        paymentSplits: updates['paymentSplits'] != null
            ? Map<String, double>.from(updates['paymentSplits'])
            : existingRide.paymentSplits,
        tollFeeAccount: updates['tollFeeAccount'] as String? ?? existingRide.tollFeeAccount,
        platformFeeAccount: updates['platformFeeAccount'] as String? ?? existingRide.platformFeeAccount,
        otherFeeAccount: updates['otherFeeAccount'] as String? ?? existingRide.otherFeeAccount,
        airportFeeAccount: updates['airportFeeAccount'] as String? ?? existingRide.airportFeeAccount,
        status: updates['status'] != null
            ? RideStatus.values.firstWhere(
                (s) => s.name == updates['status'],
                orElse: () => existingRide.status,
              )
            : existingRide.status,
      );

      await _localStorage.saveRide(updatedRide);
      DebugLogger.log('Ride updated: $rideId');
      return true;
    } catch (e) {
      DebugLogger.logError('Error updating ride: $e');
      return false;
    }
  }

  // Get a specific ride by ID
  Future<Ride?> getRideById(String rideId) async {
    try {
      return await _localStorage.getRide(rideId);
    } catch (e) {
      DebugLogger.logError('Error getting ride by ID: $e');
      return null;
    }
  }

  // Delete a ride
  Future<bool> deleteRide(String rideId) async {
    try {
      await _localStorage.deleteRide(rideId);
      DebugLogger.log('Ride deleted: $rideId');
      return true;
    } catch (e) {
      DebugLogger.logError('Error deleting ride: $e');
      return false;
    }
  }

  // Delete a ride with transaction reversal
  Future<bool> deleteRideWithTransactionReversal(String rideId) async {
    try {
      DebugLogger.log('Deleting ride with transaction reversal: $rideId');
      
      // Import AccountBalanceService
      final accountService = AccountBalanceService();
      
      // First, reverse all transactions related to this ride
      final reversalSuccess = await accountService.reverseRideTransactions(rideId);
      
      if (!reversalSuccess) {
        DebugLogger.logError('Failed to reverse transactions for ride: $rideId');
        return false;
      }
      
      // Then delete the ride
      await _localStorage.deleteRide(rideId);
      
      DebugLogger.logSuccess('Successfully deleted ride with transaction reversal: $rideId');
      return true;
    } catch (e) {
      DebugLogger.logError('Error deleting ride with transaction reversal: $e');
      return false;
    }
  }

  // Get ride statistics
  Future<Map<String, dynamic>> getRideStatistics() async {
    try {
      final rides = await getRideHistory(limit: 1000);
      final completedRides = rides.where((r) => r.status == RideStatus.completed).toList();

      if (completedRides.isEmpty) {
        return {
          'totalRides': 0,
          'totalKm': 0.0,
          'totalFare': 0.0,
          'totalProfit': 0.0,
          'averageProfitPerKm': 0.0,
          'averageProfitPerMin': 0.0,
        };
      }

      double totalKm = completedRides.fold(0.0, (sum, ride) => sum + ride.km);
      double totalFare = completedRides.fold(0.0, (sum, ride) => sum + ride.fare);
      double totalProfit = completedRides.fold(0.0, (sum, ride) => sum + ride.calculateProfit());
      double totalMinutes = completedRides.fold(0.0, (sum, ride) => sum + ride.getDurationMinutes());

      return {
        'totalRides': completedRides.length,
        'totalKm': totalKm,
        'totalFare': totalFare,
        'totalProfit': totalProfit,
        'averageProfitPerKm': totalKm > 0 ? totalProfit / totalKm : 0.0,
        'averageProfitPerMin': totalMinutes > 0 ? totalProfit / totalMinutes : 0.0,
      };
    } catch (e) {
      DebugLogger.logError('Error getting ride statistics: $e');
      return {
        'totalRides': 0,
        'totalKm': 0.0,
        'totalFare': 0.0,
        'totalProfit': 0.0,
        'averageProfitPerKm': 0.0,
        'averageProfitPerMin': 0.0,
      };
    }
  }

  // Delete all rides for the current user (both local and Firestore)
  Future<bool> deleteAllRides() async {
    try {
      if (_currentUserId == null) {
        DebugLogger.logError('RideService: User not authenticated');
        return false;
      }

      DebugLogger.log('Deleting all rides for user: $_currentUserId (local and Firestore)');

      // Get all rides from local storage first
      final allRides = await _localStorage.getAllRides();
      
      // Delete from local storage
      for (final ride in allRides) {
        await _localStorage.deleteRide(ride.id);
        DebugLogger.log('Deleted ride from local: ${ride.id}');
      }

      // Delete from Firestore (batch delete for efficiency)
      try {
        final ridesRef = _firestore
            .collection('users')
            .doc(_currentUserId!)
            .collection('rides');
        
        final snapshot = await ridesRef.get();
        
        // Batch delete (Firestore batch can handle up to 500 operations)
        final batches = <WriteBatch>[];
        WriteBatch? currentBatch;
        int operationCount = 0;
        
        for (final doc in snapshot.docs) {
          if (currentBatch == null || operationCount >= 450) {
            currentBatch = _firestore.batch();
            batches.add(currentBatch);
            operationCount = 0;
          }
          
          currentBatch.delete(doc.reference);
          operationCount++;
        }
        
        // Execute all batches
        for (final batch in batches) {
          await batch.commit();
        }
        
        DebugLogger.logSuccess('Deleted ${snapshot.docs.length} rides from Firestore');
      } catch (firestoreError) {
        DebugLogger.logError('Error deleting rides from Firestore (local deletion succeeded): $firestoreError');
        // Continue - local deletion succeeded
      }

      DebugLogger.logSuccess('All rides deleted successfully (local and Firestore)');
      return true;
    } catch (e) {
      DebugLogger.logError('Error deleting rides: $e');
      return false;
    }
  }

  // Get all rides with pagination support (simplified for local storage)
  Future<List<Ride>> getAllRides({int limit = 50}) async {
    try {
      final allRides = await _localStorage.getAllRides();
      allRides.sort((a, b) => b.startTime.compareTo(a.startTime));
      return allRides.take(limit).toList();
    } catch (e) {
      DebugLogger.logError('Error getting all rides: $e');
      return [];
    }
  }

  // Get only completed rides
  Future<List<Ride>> getCompletedRides({int limit = 50}) async {
    try {
      DebugLogger.log('Getting completed rides with limit: $limit');
      
      final allRides = await _localStorage.getAllRides();
      final completedRides = allRides
          .where((ride) => ride.status == RideStatus.completed)
          .toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));

      final limitedRides = completedRides.take(limit).toList();
      DebugLogger.log('Successfully retrieved ${limitedRides.length} completed rides');
      return limitedRides;
    } catch (e) {
      DebugLogger.logError('Error getting completed rides: $e');
      return [];
    }
  }

  // Get rides by date range
  Future<List<Ride>> getRidesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 100,
  }) async {
    try {
      return await _localStorage.getRidesByDateRange(startDate, endDate);
    } catch (e) {
      DebugLogger.logError('Error getting rides by date range: $e');
      return [];
    }
  }

  // Get comprehensive ride statistics
  Future<Map<String, dynamic>> getComprehensiveStatistics() async {
    try {
      DebugLogger.log('Getting comprehensive statistics...');
      
      final allRides = await _localStorage.getAllRides();
      DebugLogger.log('All rides: ${allRides.length}');
      
      final completedRides = allRides.where((r) => r.status == RideStatus.completed).toList();
      DebugLogger.log('Completed rides: ${completedRides.length}');
      
      final cancelledRides = allRides.where((r) => r.status == RideStatus.cancelled).toList();
      DebugLogger.log('Cancelled rides: ${cancelledRides.length}');

      if (completedRides.isEmpty) {
        DebugLogger.log('No completed rides found, returning empty stats');
        return {
          'totalRides': 0,
          'completedRides': 0,
          'cancelledRides': 0,
          'totalKm': 0.0,
          'totalFare': 0.0,
          'totalProfit': 0.0,
          'totalTip': 0.0,
          'totalFuelAllocation': 0.0,
          'averageProfitPerKm': 0.0,
          'averageProfitPerMin': 0.0,
          'averageRideDuration': 0.0,
          'bestRideProfit': 0.0,
          'thisMonthRides': 0,
          'thisMonthProfit': 0.0,
        };
      }

      // Calculate totals
      final totalKm = completedRides.fold(0.0, (sum, ride) => sum + ride.km);
      final totalFare = completedRides.fold(0.0, (sum, ride) => sum + ride.fare);
      final totalProfit = completedRides.fold(0.0, (sum, ride) => sum + ride.calculateProfit());
      final totalTip = completedRides.fold(0.0, (sum, ride) => sum + ride.calculateTip());
      final totalFuelAllocation = completedRides.fold(0.0, (sum, ride) => sum + ride.calculateFuelAllocation());
      
      // Calculate averages
      final averageProfitPerKm = totalKm > 0 ? totalProfit / totalKm : 0.0;
      final totalDurationMinutes = completedRides.fold(0.0, (sum, ride) => sum + ride.getDurationMinutes());
      final averageProfitPerMin = totalDurationMinutes > 0 ? totalProfit / totalDurationMinutes : 0.0;
      final averageRideDuration = completedRides.isNotEmpty ? totalDurationMinutes / completedRides.length : 0.0;
      
      // Find best ride
      final bestRideProfit = completedRides.isNotEmpty 
          ? completedRides.map((r) => r.calculateProfit()).reduce((a, b) => a > b ? a : b)
          : 0.0;

      // This month stats
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final thisMonthRides = completedRides.where((r) => r.startTime.isAfter(thisMonthStart)).toList();
      final thisMonthProfit = thisMonthRides.fold(0.0, (sum, ride) => sum + ride.calculateProfit());

      return {
        'totalRides': allRides.length,
        'completedRides': completedRides.length,
        'cancelledRides': cancelledRides.length,
        'totalKm': totalKm,
        'totalFare': totalFare,
        'totalProfit': totalProfit,
        'totalTip': totalTip,
        'totalFuelAllocation': totalFuelAllocation,
        'averageProfitPerKm': averageProfitPerKm,
        'averageProfitPerMin': averageProfitPerMin,
        'averageRideDuration': averageRideDuration,
        'bestRideProfit': bestRideProfit,
        'thisMonthRides': thisMonthRides.length,
        'thisMonthProfit': thisMonthProfit,
      };
    } catch (e) {
      DebugLogger.logError('Error getting comprehensive statistics: $e');
      return {};
    }
  }

  // Debug method to get all rides without any filtering
  Future<List<Map<String, dynamic>>> getAllRidesRaw() async {
    try {
      DebugLogger.log('Getting all rides raw data...');
      
      final allRides = await _localStorage.getAllRides();
      DebugLogger.log('Retrieved ${allRides.length} rides');

      return allRides.map((ride) => ride.toJson()).toList();
    } catch (e) {
      DebugLogger.logError('Error getting all rides raw: $e');
      return [];
    }
  }
}

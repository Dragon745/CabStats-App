import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ride.dart';
import 'account_balance_service.dart';

class RideService {
  static final RideService _instance = RideService._internal();
  factory RideService() => _instance;
  RideService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Get rides collection for current user
  CollectionReference get _ridesRef {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(_currentUserId!).collection('rides');
  }

  // Start a new ride
  Future<Ride?> startRide(String startLocality) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final ride = Ride(
        id: '', // Will be set after document creation
        userId: _currentUserId!,
        startLocality: startLocality,
        startTime: DateTime.now(),
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
      
      // Add timeout to prevent infinite loading
      final docRef = await _ridesRef.add(ride.toJson()).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Firestore operation timed out');
        },
      );
      
      // Update the ride with the document ID
      final rideWithId = ride.copyWith(id: docRef.id);
      await docRef.update({'id': docRef.id});
      
      return rideWithId;
    } catch (e) {
      return null;
    }
  }

  // End a ride
  Future<bool> endRide(String rideId, Ride updatedRide) async {
    try {
      final rideWithEndTime = updatedRide.copyWith(
        endTime: DateTime.now(),
        status: RideStatus.completed,
      );

      await _ridesRef.doc(rideId).update(rideWithEndTime.toJson());
      return true;
    } catch (e) {
      print('Error ending ride: $e');
      return false;
    }
  }

  // Cancel a ride (marks as cancelled but keeps in database)
  Future<bool> cancelRide(String rideId) async {
    try {
      await _ridesRef.doc(rideId).update({
        'status': RideStatus.cancelled.name,
        'endTime': DateTime.now().millisecondsSinceEpoch,
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get active ride
  Future<Ride?> getActiveRide() async {
    try {
      final snapshot = await _ridesRef
          .where('status', isEqualTo: RideStatus.active.name)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        return Ride.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting active ride: $e');
      return null;
    }
  }

  // Stream for active ride updates
  Stream<Ride?> getActiveRideStream() {
    return _ridesRef
        .where('status', isEqualTo: RideStatus.active.name)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        return Ride.fromJson(data);
      }
      return null;
    });
  }

  // Get ride history
  Future<List<Ride>> getRideHistory({int limit = 50}) async {
    try {
      print('🔍 Getting ride history with limit: $limit');
      
      final snapshot = await _ridesRef
          .orderBy('startTime', descending: true)
          .limit(limit)
          .get();

      print('🔍 Firestore returned ${snapshot.docs.length} documents for ride history');
      
      List<Ride> rides = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('🔍 Document ${doc.id}: status = ${data['status']}');
        rides.add(Ride.fromJson(data));
      }

      print('🔍 Successfully parsed ${rides.length} rides from history');
      return rides;
    } catch (e) {
      print('❌ Error getting ride history: $e');
      return [];
    }
  }

  // Stream for ride history
  Stream<List<Ride>> getRideHistoryStream({int limit = 50}) {
    return _ridesRef
        .orderBy('startTime', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      List<Ride> rides = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        rides.add(Ride.fromJson(data));
      }
      return rides;
    });
  }

  // Update ride (for mid-ride updates)
  Future<bool> updateRide(String rideId, Map<String, dynamic> updates) async {
    try {
      await _ridesRef.doc(rideId).update(updates);
      return true;
    } catch (e) {
      print('Error updating ride: $e');
      return false;
    }
  }

  // Get a specific ride by ID
  Future<Ride?> getRideById(String rideId) async {
    try {
      final doc = await _ridesRef.doc(rideId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return Ride.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting ride by ID: $e');
      return null;
    }
  }

  // Delete a ride
  Future<bool> deleteRide(String rideId) async {
    try {
      await _ridesRef.doc(rideId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete a ride with transaction reversal
  Future<bool> deleteRideWithTransactionReversal(String rideId) async {
    try {
      print('🗑️ Deleting ride with transaction reversal: $rideId');
      
      // Import AccountBalanceService
      final accountService = AccountBalanceService();
      
      // First, reverse all transactions related to this ride
      final reversalSuccess = await accountService.reverseRideTransactions(rideId);
      
      if (!reversalSuccess) {
        print('❌ Failed to reverse transactions for ride: $rideId');
        return false;
      }
      
      // Then delete the ride document
      await _ridesRef.doc(rideId).delete();
      
      print('✅ Successfully deleted ride with transaction reversal: $rideId');
      return true;
    } catch (e) {
      print('❌ Error deleting ride with transaction reversal: $e');
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
      print('Error getting ride statistics: $e');
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

  // Delete all rides for the current user
  Future<bool> deleteAllRides() async {
    try {
      if (_currentUserId == null) {
        print('❌ RideService: User not authenticated');
        return false;
      }

      print('🗑️ Deleting all rides for user: $_currentUserId');

      final ridesSnapshot = await _ridesRef.get();
      for (final doc in ridesSnapshot.docs) {
        await doc.reference.delete();
        print('✅ Deleted ride: ${doc.id}');
      }

      print('✅ All rides deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting rides: $e');
      return false;
    }
  }

  // Get all rides with pagination support
  Future<List<Ride>> getAllRides({int limit = 50, DocumentSnapshot? lastDocument}) async {
    try {
      Query query = _ridesRef.orderBy('startTime', descending: true);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      final snapshot = await query.limit(limit).get();
      
      List<Ride> rides = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        rides.add(Ride.fromJson(data));
      }
      
      return rides;
    } catch (e) {
      print('Error getting all rides: $e');
      return [];
    }
  }

  // Get only completed rides
  Future<List<Ride>> getCompletedRides({int limit = 50}) async {
    try {
      print('🔍 Getting completed rides with limit: $limit');
      print('🔍 Query: status == ${RideStatus.completed.name}');
      
      final snapshot = await _ridesRef
          .where('status', isEqualTo: RideStatus.completed.name)
          .orderBy('startTime', descending: true)
          .limit(limit)
          .get();

      print('🔍 Firestore returned ${snapshot.docs.length} documents');
      
      List<Ride> rides = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('🔍 Document ${doc.id}: status = ${data['status']}');
        rides.add(Ride.fromJson(data));
      }

      print('🔍 Successfully parsed ${rides.length} completed rides');
      return rides;
    } catch (e) {
      print('❌ Error getting completed rides: $e');
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
      final startTimestamp = startDate.millisecondsSinceEpoch;
      final endTimestamp = endDate.millisecondsSinceEpoch;
      
      final snapshot = await _ridesRef
          .where('startTime', isGreaterThanOrEqualTo: startTimestamp)
          .where('startTime', isLessThanOrEqualTo: endTimestamp)
          .orderBy('startTime', descending: true)
          .limit(limit)
          .get();

      List<Ride> rides = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        rides.add(Ride.fromJson(data));
      }

      return rides;
    } catch (e) {
      print('Error getting rides by date range: $e');
      return [];
    }
  }

  // Get comprehensive ride statistics
  Future<Map<String, dynamic>> getComprehensiveStatistics() async {
    try {
      print('🔍 Getting comprehensive statistics...');
      
      final allRides = await getRideHistory(limit: 1000);
      print('🔍 All rides from history: ${allRides.length}');
      
      final completedRides = allRides.where((r) => r.status == RideStatus.completed).toList();
      print('🔍 Completed rides filtered from all rides: ${completedRides.length}');
      
      final cancelledRides = allRides.where((r) => r.status == RideStatus.cancelled).toList();
      print('🔍 Cancelled rides filtered from all rides: ${cancelledRides.length}');

      if (completedRides.isEmpty) {
        print('🔍 No completed rides found, returning empty stats');
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
      final totalProfit = completedRides.fold(0.0, (sum, ride) => sum + (ride.calculateProfit()));
      final totalTip = completedRides.fold(0.0, (sum, ride) => sum + (ride.calculateTip()));
      final totalFuelAllocation = completedRides.fold(0.0, (sum, ride) => sum + (ride.calculateFuelAllocation()));
      
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
      print('Error getting comprehensive statistics: $e');
      return {};
    }
  }

  // Debug method to get all rides without any filtering
  Future<List<Map<String, dynamic>>> getAllRidesRaw() async {
    try {
      print('🔍 Getting all rides raw data...');
      
      final snapshot = await _ridesRef.get();
      print('🔍 Firestore returned ${snapshot.docs.length} documents');

      List<Map<String, dynamic>> rides = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('🔍 Document ${doc.id}: ${data.toString()}');
        rides.add(data);
      }

      return rides;
    } catch (e) {
      print('❌ Error getting all rides raw: $e');
      return [];
    }
  }
}

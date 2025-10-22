import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ride.dart';

class RideServiceFirestore {
  static final RideServiceFirestore _instance = RideServiceFirestore._internal();
  factory RideServiceFirestore() => _instance;
  RideServiceFirestore._internal();

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
      print('Starting ride with locality: $startLocality');
      
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

      print('Saving ride to Firestore: ${ride.toJson()}');
      
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
      
      print('Ride saved successfully with ID: ${docRef.id}');
      return rideWithId;
    } catch (e) {
      print('Error starting ride: $e');
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

  // Cancel a ride
  Future<bool> cancelRide(String rideId) async {
    try {
      await _ridesRef.doc(rideId).update({
        'status': RideStatus.cancelled.name,
        'endTime': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      print('Error cancelling ride: $e');
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
      final snapshot = await _ridesRef
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
      print('Error getting ride history: $e');
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
      print('Error deleting ride: $e');
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
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../services/local_storage_service.dart';
import '../services/network_service.dart';
import '../models/ride.dart';
import '../models/ledger_entry.dart';
import '../models/account_transfer.dart';
import '../models/pending_fuel_allocation.dart';
import '../models/refuel.dart';
import '../models/pending_tips.dart';
import '../models/account_balance.dart';
import '../utils/debug_logger.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalStorageService _localStorage = LocalStorageService();
  final NetworkService _networkService = NetworkService();

  String? get _currentUserId => _auth.currentUser?.uid;

  SyncStatus _status = SyncStatus.idle;
  String? _lastError;
  DateTime? _lastSyncTime;
  int _conflictsResolved = 0;
  
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncInProgress = false;

  SyncStatus get status => _status;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get conflictsResolved => _conflictsResolved;

  // Sync all data types with retry logic for unreliable networks
  Future<bool> syncAllData({int maxRetries = 3}) async {
    if (_currentUserId == null) {
      _lastError = 'User not authenticated';
      return false;
    }

    // Check for actual internet connectivity (not just carrier)
    final isConnected = await _networkService.isConnected();
    if (!isConnected) {
      _lastError = 'No internet connection - carrier detected but no actual connectivity';
      DebugLogger.logError(_lastError ?? 'Unknown error');
      return false;
    }

    _status = SyncStatus.syncing;
    _conflictsResolved = 0;

    // Retry logic for unreliable networks (like Jio)
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        if (attempt > 1) {
          DebugLogger.log('Retry attempt $attempt/$maxRetries for sync...');
          // Exponential backoff: 2s, 4s, 8s
          await Future.delayed(Duration(seconds: 2 * attempt));
          
          // Re-check connectivity before retry
          if (!(await _networkService.isConnected())) {
            _lastError = 'Lost internet connection during retry';
            return false;
          }
        }

        DebugLogger.log('Starting full sync... (attempt $attempt/$maxRetries)');

        // Sync all collections
        await syncRides();
        await syncAccountBalances();
        await syncLedger();
        await syncTransfers();
        await syncFuelAllocation();
        await syncRefuels();
        await syncPendingTips();

        _status = SyncStatus.success;
        _lastSyncTime = DateTime.now();
        DebugLogger.logSuccess('Sync completed successfully. Conflicts resolved: $_conflictsResolved');

        return true;
      } catch (e) {
        _status = SyncStatus.error;
        _lastError = e.toString();
        DebugLogger.logError('Sync failed on attempt $attempt/$maxRetries: $e');
        
        // If this was the last attempt, return false
        if (attempt == maxRetries) {
          return false;
        }
        // Otherwise, continue to next retry
      }
    }
    return false; // Should never reach here, but just in case
  }

  // Sync rides - two-way with conflict resolution
  Future<void> syncRides() async {
    try {
      DebugLogger.log('Syncing rides...');

      // Pull from Firebase with timeout for unreliable networks (like Jio)
      // Try server first, fallback to cache if server fails
      QuerySnapshot firestoreSnapshot;
      try {
        firestoreSnapshot = await _firestore
            .collection('users')
            .doc(_currentUserId!)
            .collection('rides')
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 30), onTimeout: () {
          DebugLogger.log('Firestore timeout - trying cache');
          throw TimeoutException('Firestore server timeout - will retry with cache');
        });
      } on TimeoutException catch (_) {
        // If server times out (common on Jio), try cache-only
        DebugLogger.log('Server timeout detected - using cache');
        firestoreSnapshot = await _firestore
            .collection('users')
            .doc(_currentUserId!)
            .collection('rides')
            .get(const GetOptions(source: Source.cache));
      }

      final localRides = await _localStorage.getAllRides();
      final localRidesMap = {for (var ride in localRides) ride.id: ride};

      int conflicts = 0;

      // Process Firebase rides
      for (final doc in firestoreSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        // Ensure lastModified exists
        if (data['lastModified'] == null) {
          data['lastModified'] = DateTime.now().millisecondsSinceEpoch;
        }

        final firestoreRide = Ride.fromJson(data);
        final localRide = localRidesMap[firestoreRide.id];

        if (localRide == null) {
          // New ride from Firebase - save locally
          await _localStorage.saveRide(firestoreRide);
          DebugLogger.log('Added new ride from Firebase: ${firestoreRide.id}');
        } else {
          // Compare timestamps - newest wins
          if (firestoreRide.lastModified.isAfter(localRide.lastModified)) {
            await _localStorage.saveRide(firestoreRide);
            conflicts++;
            DebugLogger.log('Conflict resolved: Firebase version newer for ride ${firestoreRide.id}');
          } else if (localRide.lastModified.isAfter(firestoreRide.lastModified)) {
            // Local is newer - push to Firebase
            await _pushRideToFirebase(localRide);
            conflicts++;
            DebugLogger.log('Conflict resolved: Local version newer for ride ${localRide.id}');
          }
          // If equal, no conflict - skip
        }
      }

      // Push local-only rides to Firebase
      for (final localRide in localRides) {
        final existsInFirestore = firestoreSnapshot.docs
            .any((doc) => doc.id == localRide.id);
        
        if (!existsInFirestore) {
          await _pushRideToFirebase(localRide);
          DebugLogger.log('Pushed new local ride to Firebase: ${localRide.id}');
        }
      }

      _conflictsResolved += conflicts;
      DebugLogger.log('Rides sync completed. Conflicts: $conflicts');
    } catch (e) {
      DebugLogger.logError('Error syncing rides: $e');
      rethrow;
    }
  }

  // Push ride to Firebase with timeout handling for unreliable networks (like Jio)
  Future<void> _pushRideToFirebase(Ride ride) async {
    final rideJson = ride.toJson();
    rideJson['lastModified'] = DateTime.now().millisecondsSinceEpoch;
    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('rides')
          .doc(ride.id)
          .set(rideJson, SetOptions(merge: true))
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      DebugLogger.logError('Failed to push ride ${ride.id} to Firebase: $e');
      rethrow;
    }
  }

  // Sync account balances
  Future<void> syncAccountBalances() async {
    try {
      DebugLogger.log('Syncing account balances...');

      final firestoreSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('accountBalances')
          .get();

      final localBalances = await _localStorage.getAllAccountBalanceObjects();
      int conflicts = 0;

      // Process Firebase balances
      for (final doc in firestoreSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        if (data['lastModified'] == null) {
          data['lastModified'] = DateTime.now().millisecondsSinceEpoch;
        }

        final firestoreBalance = AccountBalance.fromJson(data);
        final localBalance = localBalances[firestoreBalance.accountId];

        if (localBalance == null) {
          await _localStorage.saveAccountBalance(firestoreBalance);
          DebugLogger.log('Added new account balance from Firebase: ${firestoreBalance.accountId}');
        } else {
          if (firestoreBalance.lastModified.isAfter(localBalance.lastModified)) {
            await _localStorage.saveAccountBalance(firestoreBalance);
            conflicts++;
          } else if (localBalance.lastModified.isAfter(firestoreBalance.lastModified)) {
            await _pushAccountBalanceToFirebase(localBalance);
            conflicts++;
          }
        }
      }

      // Push local-only balances
      for (final localBalance in localBalances.values) {
        final existsInFirestore = firestoreSnapshot.docs
            .any((doc) => doc.id == localBalance.accountId);
        
        if (!existsInFirestore) {
          await _pushAccountBalanceToFirebase(localBalance);
        }
      }

      _conflictsResolved += conflicts;
      DebugLogger.log('Account balances sync completed. Conflicts: $conflicts');
    } catch (e) {
      DebugLogger.logError('Error syncing account balances: $e');
      rethrow;
    }
  }

  Future<void> _pushAccountBalanceToFirebase(AccountBalance balance) async {
    final balanceJson = balance.toJson();
    balanceJson['lastModified'] = DateTime.now().millisecondsSinceEpoch;
    
    await _firestore
        .collection('users')
        .doc(_currentUserId!)
        .collection('accountBalances')
        .doc(balance.accountId)
        .set(balanceJson, SetOptions(merge: true));
  }

  // Sync ledger entries
  Future<void> syncLedger() async {
    try {
      DebugLogger.log('Syncing ledger entries...');

      final firestoreSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('ledger')
          .get();

      final localEntries = await _localStorage.getAllLedgerEntries();
      final localEntriesMap = {for (var entry in localEntries) entry.id: entry};

      int conflicts = 0;

      for (final doc in firestoreSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        if (data['lastModified'] == null) {
          data['lastModified'] = DateTime.now().millisecondsSinceEpoch;
        }

        final firestoreEntry = LedgerEntry.fromJson(data);
        final localEntry = localEntriesMap[firestoreEntry.id];

        if (localEntry == null) {
          await _localStorage.saveLedgerEntry(firestoreEntry);
        } else {
          if (firestoreEntry.lastModified.isAfter(localEntry.lastModified)) {
            await _localStorage.saveLedgerEntry(firestoreEntry);
            conflicts++;
          } else if (localEntry.lastModified.isAfter(firestoreEntry.lastModified)) {
            await _pushLedgerEntryToFirebase(localEntry);
            conflicts++;
          }
        }
      }

      // Push local-only entries
      for (final localEntry in localEntries) {
        final existsInFirestore = firestoreSnapshot.docs
            .any((doc) => doc.id == localEntry.id);
        
        if (!existsInFirestore) {
          await _pushLedgerEntryToFirebase(localEntry);
        }
      }

      _conflictsResolved += conflicts;
      DebugLogger.log('Ledger sync completed. Conflicts: $conflicts');
    } catch (e) {
      DebugLogger.logError('Error syncing ledger: $e');
      rethrow;
    }
  }

  Future<void> _pushLedgerEntryToFirebase(LedgerEntry entry) async {
    final entryJson = entry.toJson();
    entryJson['lastModified'] = DateTime.now().millisecondsSinceEpoch;
    
    await _firestore
        .collection('users')
        .doc(_currentUserId!)
        .collection('ledger')
        .doc(entry.id)
        .set(entryJson, SetOptions(merge: true));
  }

  // Sync account transfers
  Future<void> syncTransfers() async {
    try {
      DebugLogger.log('Syncing account transfers...');

      final firestoreSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('accountTransfers')
          .get();

      final localTransfers = await _localStorage.getAllTransfers();
      final localTransfersMap = {for (var transfer in localTransfers) transfer.id: transfer};

      int conflicts = 0;

      for (final doc in firestoreSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        if (data['lastModified'] == null) {
          data['lastModified'] = DateTime.now().millisecondsSinceEpoch;
        }

        final firestoreTransfer = AccountTransfer.fromJson(data);
        final localTransfer = localTransfersMap[firestoreTransfer.id];

        if (localTransfer == null) {
          await _localStorage.saveTransfer(firestoreTransfer);
        } else {
          if (firestoreTransfer.lastModified.isAfter(localTransfer.lastModified)) {
            await _localStorage.saveTransfer(firestoreTransfer);
            conflicts++;
          } else if (localTransfer.lastModified.isAfter(firestoreTransfer.lastModified)) {
            await _pushTransferToFirebase(localTransfer);
            conflicts++;
          }
        }
      }

      // Push local-only transfers
      for (final localTransfer in localTransfers) {
        final existsInFirestore = firestoreSnapshot.docs
            .any((doc) => doc.id == localTransfer.id);
        
        if (!existsInFirestore) {
          await _pushTransferToFirebase(localTransfer);
        }
      }

      _conflictsResolved += conflicts;
      DebugLogger.log('Transfers sync completed. Conflicts: $conflicts');
    } catch (e) {
      DebugLogger.logError('Error syncing transfers: $e');
      rethrow;
    }
  }

  Future<void> _pushTransferToFirebase(AccountTransfer transfer) async {
    final transferJson = transfer.toJson();
    transferJson['lastModified'] = DateTime.now().millisecondsSinceEpoch;
    
    await _firestore
        .collection('users')
        .doc(_currentUserId!)
        .collection('accountTransfers')
        .doc(transfer.id)
        .set(transferJson, SetOptions(merge: true));
  }

  // Sync fuel allocation
  Future<void> syncFuelAllocation() async {
    try {
      DebugLogger.log('Syncing fuel allocation...');

      final firestoreSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('pendingFuelAllocation')
          .get();

      final localAllocation = await _localStorage.getPendingFuelAllocation();
      int conflicts = 0;

      if (firestoreSnapshot.docs.isNotEmpty) {
        final doc = firestoreSnapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        if (data['lastModified'] == null) {
          data['lastModified'] = DateTime.now().millisecondsSinceEpoch;
        }

        final firestoreAllocation = PendingFuelAllocation.fromJson(data);

        if (localAllocation == null) {
          await _localStorage.saveFuelAllocation(firestoreAllocation);
        } else {
          if (firestoreAllocation.lastModified.isAfter(localAllocation.lastModified)) {
            await _localStorage.saveFuelAllocation(firestoreAllocation);
            conflicts++;
          } else if (localAllocation.lastModified.isAfter(firestoreAllocation.lastModified)) {
            await _pushFuelAllocationToFirebase(localAllocation);
            conflicts++;
          }
        }
      } else if (localAllocation != null) {
        // Only local exists - push to Firebase
        await _pushFuelAllocationToFirebase(localAllocation);
      }

      _conflictsResolved += conflicts;
      DebugLogger.log('Fuel allocation sync completed. Conflicts: $conflicts');
    } catch (e) {
      DebugLogger.logError('Error syncing fuel allocation: $e');
      rethrow;
    }
  }

  Future<void> _pushFuelAllocationToFirebase(PendingFuelAllocation allocation) async {
    final allocationJson = allocation.toJson();
    allocationJson['lastModified'] = DateTime.now().millisecondsSinceEpoch;
    
    await _firestore
        .collection('users')
        .doc(_currentUserId!)
        .collection('pendingFuelAllocation')
        .doc(allocation.id)
        .set(allocationJson, SetOptions(merge: true));
  }

  // Sync refuels
  Future<void> syncRefuels() async {
    try {
      DebugLogger.log('Syncing refuels...');

      final firestoreSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('refuels')
          .get();

      final localRefuels = await _localStorage.getAllRefuels();
      final localRefuelsMap = <String, Refuel>{};
      
      for (var refuel in localRefuels) {
        if (refuel.id != null) {
          localRefuelsMap[refuel.id!] = refuel;
        }
      }

      int conflicts = 0;

      for (final doc in firestoreSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        if (data['lastModified'] == null) {
          data['lastModified'] = DateTime.now().millisecondsSinceEpoch;
        }

        final firestoreRefuel = Refuel.fromJson(data);
        final localRefuel = firestoreRefuel.id != null 
            ? localRefuelsMap[firestoreRefuel.id!] 
            : null;

        if (localRefuel == null) {
          await _localStorage.saveRefuel(firestoreRefuel);
        } else if (firestoreRefuel.id != null) {
          if (firestoreRefuel.lastModified.isAfter(localRefuel.lastModified)) {
            await _localStorage.saveRefuel(firestoreRefuel);
            conflicts++;
          } else if (localRefuel.lastModified.isAfter(firestoreRefuel.lastModified)) {
            await _pushRefuelToFirebase(localRefuel);
            conflicts++;
          }
        }
      }

      // Push local-only refuels
      for (final localRefuel in localRefuels) {
        if (localRefuel.id != null) {
          final existsInFirestore = firestoreSnapshot.docs
              .any((doc) => doc.id == localRefuel.id);
          
          if (!existsInFirestore) {
            await _pushRefuelToFirebase(localRefuel);
          }
        }
      }

      _conflictsResolved += conflicts;
      DebugLogger.log('Refuels sync completed. Conflicts: $conflicts');
    } catch (e) {
      DebugLogger.logError('Error syncing refuels: $e');
      rethrow;
    }
  }

  Future<void> _pushRefuelToFirebase(Refuel refuel) async {
    if (refuel.id == null) return;
    
    final refuelJson = refuel.toJson();
    refuelJson['lastModified'] = DateTime.now().millisecondsSinceEpoch;
    
    await _firestore
        .collection('users')
        .doc(_currentUserId!)
        .collection('refuels')
        .doc(refuel.id!)
        .set(refuelJson, SetOptions(merge: true));
  }

  // Sync pending tips
  Future<void> syncPendingTips() async {
    try {
      DebugLogger.log('Syncing pending tips...');

      final firestoreDoc = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('pendingTips')
          .doc('current')
          .get();

      final localTips = await _localStorage.getCurrentPendingTips();
      int conflicts = 0;

      if (firestoreDoc.exists) {
        final data = firestoreDoc.data() as Map<String, dynamic>;
        data['id'] = 'current';
        
        if (data['lastModified'] == null) {
          data['lastModified'] = DateTime.now().millisecondsSinceEpoch;
        }
        
        if (data['lastUpdated'] == null) {
          data['lastUpdated'] = DateTime.now().millisecondsSinceEpoch;
        }

        final firestoreTips = PendingTips.fromJson(data);

        if (localTips == null) {
          await _localStorage.savePendingTips(firestoreTips);
        } else {
          if (firestoreTips.lastModified.isAfter(localTips.lastModified)) {
            await _localStorage.savePendingTips(firestoreTips);
            conflicts++;
          } else if (localTips.lastModified.isAfter(firestoreTips.lastModified)) {
            await _pushPendingTipsToFirebase(localTips);
            conflicts++;
          }
        }
      } else if (localTips != null) {
        // Only local exists - push to Firebase
        await _pushPendingTipsToFirebase(localTips);
      }

      _conflictsResolved += conflicts;
      DebugLogger.log('Pending tips sync completed. Conflicts: $conflicts');
    } catch (e) {
      DebugLogger.logError('Error syncing pending tips: $e');
      rethrow;
    }
  }

  Future<void> _pushPendingTipsToFirebase(PendingTips tips) async {
    final tipsJson = tips.toJson();
    tipsJson['lastModified'] = DateTime.now().millisecondsSinceEpoch;
    
    await _firestore
        .collection('users')
        .doc(_currentUserId!)
        .collection('pendingTips')
        .doc('current')
        .set(tipsJson, SetOptions(merge: true));
  }

  // Background sync is disabled - sync must be triggered manually
  // This method is kept for API compatibility but does nothing
  @Deprecated('Background sync is disabled. Use syncAllData() manually.')
  void startBackgroundSync() {
    DebugLogger.log('Background sync is disabled - use manual sync from drawer');
  }

  // Stop background sync
  @Deprecated('Background sync is disabled.')
  void stopBackgroundSync() {
    // No-op - background sync is disabled
  }

  // Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
}


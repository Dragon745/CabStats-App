import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/local_storage_service.dart';
import '../models/ride.dart';
import '../models/ledger_entry.dart';
import '../models/account_transfer.dart';
import '../models/pending_fuel_allocation.dart';
import '../models/refuel.dart';
import '../models/pending_tips.dart';
import '../models/account_balance.dart';
import '../utils/debug_logger.dart';

class MigrationService {
  static final MigrationService _instance = MigrationService._internal();
  factory MigrationService() => _instance;
  MigrationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalStorageService _localStorage = LocalStorageService();

  String? get _currentUserId => _auth.currentUser?.uid;

  // Migrate all data from Firebase to local storage
  Future<void> migrateFromFirebase() async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      DebugLogger.log('Starting migration from Firebase...');

      // Check if local data already exists
      final hasLocalData = await _localStorage.hasLocalData();
      if (hasLocalData) {
        DebugLogger.log('Local data already exists, skipping migration');
        return;
      }

      final now = DateTime.now();

      // Migrate rides
      await _migrateRides(now);

      // Migrate account balances
      await _migrateAccountBalances(now);

      // Migrate ledger entries
      await _migrateLedgerEntries(now);

      // Migrate account transfers
      await _migrateAccountTransfers(now);

      // Migrate pending fuel allocation
      await _migratePendingFuelAllocation(now);

      // Migrate refuels
      await _migrateRefuels(now);

      // Migrate pending tips
      await _migratePendingTips(now);

      DebugLogger.log('Migration completed successfully');
    } catch (e) {
      DebugLogger.logError('Migration failed: $e');
      rethrow;
    }
  }

  Future<void> _migrateRides(DateTime migrationTime) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('rides')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        
        // Add lastModified if not present
        if (data['lastModified'] == null) {
          data['lastModified'] = migrationTime.millisecondsSinceEpoch;
        }

        final ride = Ride.fromJson(data);
        await _localStorage.saveRide(ride);
      }

      DebugLogger.log('Migrated ${snapshot.docs.length} rides');
    } catch (e) {
      DebugLogger.logError('Error migrating rides: $e');
    }
  }

  Future<void> _migrateAccountBalances(DateTime migrationTime) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('accountBalances')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        // Add lastModified if not present
        if (data['lastModified'] == null) {
          data['lastModified'] = migrationTime.millisecondsSinceEpoch;
        }

        final balance = AccountBalance.fromJson(data);
        await _localStorage.saveAccountBalance(balance);
      }

      DebugLogger.log('Migrated ${snapshot.docs.length} account balances');
    } catch (e) {
      DebugLogger.logError('Error migrating account balances: $e');
    }
  }

  Future<void> _migrateLedgerEntries(DateTime migrationTime) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('ledger')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        
        // Add lastModified if not present
        if (data['lastModified'] == null) {
          data['lastModified'] = migrationTime.millisecondsSinceEpoch;
        }

        final entry = LedgerEntry.fromJson(data);
        await _localStorage.saveLedgerEntry(entry);
      }

      DebugLogger.log('Migrated ${snapshot.docs.length} ledger entries');
    } catch (e) {
      DebugLogger.logError('Error migrating ledger entries: $e');
    }
  }

  Future<void> _migrateAccountTransfers(DateTime migrationTime) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('accountTransfers')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        
        // Add lastModified if not present
        if (data['lastModified'] == null) {
          data['lastModified'] = migrationTime.millisecondsSinceEpoch;
        }

        final transfer = AccountTransfer.fromJson(data);
        await _localStorage.saveTransfer(transfer);
      }

      DebugLogger.log('Migrated ${snapshot.docs.length} account transfers');
    } catch (e) {
      DebugLogger.logError('Error migrating account transfers: $e');
    }
  }

  Future<void> _migratePendingFuelAllocation(DateTime migrationTime) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('pendingFuelAllocation')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        
        // Add lastModified if not present
        if (data['lastModified'] == null) {
          data['lastModified'] = migrationTime.millisecondsSinceEpoch;
        }

        final allocation = PendingFuelAllocation.fromJson(data);
        await _localStorage.saveFuelAllocation(allocation);
      }

      DebugLogger.log('Migrated ${snapshot.docs.length} fuel allocations');
    } catch (e) {
      DebugLogger.logError('Error migrating fuel allocations: $e');
    }
  }

  Future<void> _migrateRefuels(DateTime migrationTime) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('refuels')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        
        // Add lastModified if not present
        if (data['lastModified'] == null) {
          data['lastModified'] = migrationTime.millisecondsSinceEpoch;
        }

        final refuel = Refuel.fromJson(data);
        await _localStorage.saveRefuel(refuel);
      }

      DebugLogger.log('Migrated ${snapshot.docs.length} refuels');
    } catch (e) {
      DebugLogger.logError('Error migrating refuels: $e');
    }
  }

  Future<void> _migratePendingTips(DateTime migrationTime) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('pendingTips')
          .doc('current')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = 'current';
        
        // Add lastModified if not present
        if (data['lastModified'] == null) {
          data['lastModified'] = migrationTime.millisecondsSinceEpoch;
        }
        
        // Ensure lastUpdated exists
        if (data['lastUpdated'] == null) {
          data['lastUpdated'] = migrationTime.millisecondsSinceEpoch;
        }

        final tips = PendingTips.fromJson(data);
        await _localStorage.savePendingTips(tips);
        DebugLogger.log('Migrated pending tips');
      }
    } catch (e) {
      DebugLogger.logError('Error migrating pending tips: $e');
    }
  }
}


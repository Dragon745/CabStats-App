import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/account.dart';
import '../models/ledger_entry.dart';
import '../models/account_transfer.dart';
import '../models/pending_fuel_allocation.dart';
import '../models/refuel.dart';

class AccountBalanceService {
  static final AccountBalanceService _instance = AccountBalanceService._internal();
  factory AccountBalanceService() => _instance;
  AccountBalanceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Get account balances collection for current user
  CollectionReference get _balancesRef {
    if (_currentUserId == null) {
      print('❌ AccountBalanceService: User not authenticated');
      throw Exception('User not authenticated');
    }
    final path = 'users/$_currentUserId/accountBalances';
    print('📊 AccountBalanceService: Using balances collection: $path');
    return _firestore.collection('users').doc(_currentUserId!).collection('accountBalances');
  }

  // Get ledger collection for current user
  CollectionReference get _ledgerRef {
    if (_currentUserId == null) {
      print('❌ AccountBalanceService: User not authenticated');
      throw Exception('User not authenticated');
    }
    final path = 'users/$_currentUserId/ledger';
    print('📝 AccountBalanceService: Using ledger collection: $path');
    return _firestore.collection('users').doc(_currentUserId!).collection('ledger');
  }

  // Get account transfers collection for current user
  CollectionReference get _transfersRef {
    if (_currentUserId == null) {
      print('❌ AccountBalanceService: User not authenticated');
      throw Exception('User not authenticated');
    }
    final path = 'users/$_currentUserId/accountTransfers';
    print('💸 AccountBalanceService: Using transfers collection: $path');
    return _firestore.collection('users').doc(_currentUserId!).collection('accountTransfers');
  }

  // Get refuels collection for current user
  CollectionReference get _refuelsRef {
    if (_currentUserId == null) {
      print('❌ AccountBalanceService: User not authenticated');
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(_currentUserId!).collection('refuels');
  }

  // Get pending fuel allocation collection for current user
  CollectionReference get _pendingFuelAllocationRef {
    if (_currentUserId == null) {
      print('❌ AccountBalanceService: User not authenticated');
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(_currentUserId!).collection('pendingFuelAllocation');
  }

  // Create account balance document if it doesn't exist
  Future<bool> ensureAccountBalanceExists(String accountId) async {
    try {
      final doc = await _balancesRef.doc(accountId).get();
      
      if (!doc.exists) {
        print('Creating account balance document for $accountId');
        final accounts = Account.getSampleAccounts();
        final account = accounts.firstWhere(
          (a) => a.id == accountId,
          orElse: () => accounts.first,
        );
        
        await _balancesRef.doc(accountId).set({
          'accountId': accountId,
          'accountName': account.name,
          'accountType': account.type,
          'balance': 0.0, // Start with zero balance
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        });
        
        print('Created account balance document for $accountId');
        return true;
      }
      
      return true; // Already exists
    } catch (e) {
      print('Error ensuring account balance exists for $accountId: $e');
      return false;
    }
  }

  // Check if account balances are already initialized
  Future<bool> areAccountBalancesInitialized() async {
    try {
      final snapshot = await _balancesRef.limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if account balances are initialized: $e');
      return false;
    }
  }

  // Initialize account balances (call this once when user first signs up)
  Future<void> initializeAccountBalances() async {
    try {
      print('Starting account balance initialization...');
      print('Current user ID: $_currentUserId');
      
      if (_currentUserId == null) {
        print('ERROR: User not authenticated');
        throw Exception('User not authenticated');
      }
      
      // Check if already initialized
      final alreadyInitialized = await areAccountBalancesInitialized();
      if (alreadyInitialized) {
        print('Account balances already initialized, skipping...');
        return;
      }
      
      final accounts = Account.getSampleAccounts();
      print('Sample accounts: ${accounts.length}');
      
      for (final account in accounts) {
        print('Creating account balance for: ${account.id}');
        await _balancesRef.doc(account.id).set({
          'accountId': account.id,
          'accountName': account.name,
          'accountType': account.type,
          'balance': account.balance,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        });
        print('Created account balance for: ${account.id}');
      }
      
      print('Account balances initialized successfully');
    } catch (e) {
      print('Error initializing account balances: $e');
      rethrow; // Re-throw to show error in UI
    }
  }

  // Get current balance for an account (returns 0 if document doesn't exist)
  Future<double> getAccountBalance(String accountId) async {
    try {
      print('🔍 Fetching balance for account: $accountId');
      print('📁 Collection path: users/$_currentUserId/accountBalances/$accountId');
      
      final doc = await _balancesRef.doc(accountId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final balance = (data['balance'] as num).toDouble();
        print('✅ Found balance document: ₹${balance.toStringAsFixed(2)}');
        return balance;
      } else {
        print('⚠️ Account balance document for $accountId does not exist, returning 0');
        print('💡 This is normal for first-time users - documents will be created during transactions');
        return 0.0;
      }
    } catch (e) {
      print('❌ Error getting account balance for $accountId: $e');
      print('🔗 If this is a Firestore error, check your Firebase Console for the collection structure');
      return 0.0;
    }
  }

  // Get all account balances
  Future<List<Map<String, dynamic>>> getAllAccountBalances() async {
    try {
      final snapshot = await _balancesRef.get();
      List<Map<String, dynamic>> balances = [];
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        balances.add(data);
      }
      
      return balances;
    } catch (e) {
      print('Error getting all account balances: $e');
      return [];
    }
  }

  // Update account balance (creates document if it doesn't exist)
  Future<bool> updateAccountBalance(String accountId, double newBalance) async {
    try {
      print('Updating account balance for $accountId to $newBalance');
      
      // Check if document exists
      final doc = await _balancesRef.doc(accountId).get();
      
      if (doc.exists) {
        // Update existing document
        await _balancesRef.doc(accountId).update({
          'balance': newBalance,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        });
        print('Updated existing account balance for $accountId');
      } else {
        // Create new document with default values
        final accounts = Account.getSampleAccounts();
        final account = accounts.firstWhere(
          (a) => a.id == accountId,
          orElse: () => accounts.first,
        );
        
        await _balancesRef.doc(accountId).set({
          'accountId': accountId,
          'accountName': account.name,
          'accountType': account.type,
          'balance': newBalance,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        });
        print('Created new account balance document for $accountId');
      }
      
      return true;
    } catch (e) {
      print('Error updating account balance for $accountId: $e');
      return false;
    }
  }

  // Add ledger entry and update balance
  Future<bool> addTransaction({
    required String accountId,
    required String rideId,
    required TransactionType type,
    required TransactionCategory category,
    required TransactionNature nature,
    required double amount,
    required String description,
    String? reference,
  }) async {
    try {
      print('Adding transaction: $type $amount to account $accountId');
      
      // Create ledger entry
      final ledgerId = _ledgerRef.doc().id;
      final ledgerEntry = LedgerEntry(
        id: ledgerId,
        accountId: accountId,
        rideId: rideId,
        type: type,
        category: category,
        nature: nature,
        amount: amount,
        description: description,
        timestamp: DateTime.now(),
        reference: reference,
      );

      // Add to ledger
      await _ledgerRef.doc(ledgerId).set(ledgerEntry.toJson());
      print('Added ledger entry: ${ledgerEntry.formattedAmount}');

      // Update account balance (this will create document if it doesn't exist)
      final currentBalance = await getAccountBalance(accountId);
      final newBalance = type == TransactionType.credit 
          ? currentBalance + amount 
          : currentBalance - amount;
      
      await updateAccountBalance(accountId, newBalance);

      print('Transaction completed: ${ledgerEntry.formattedAmount} to account $accountId');
      return true;
    } catch (e) {
      print('Error adding transaction: $e');
      return false;
    }
  }

  // Transfer money between accounts
  Future<bool> transferBetweenAccounts({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String? note,
  }) async {
    try {
      if (_currentUserId == null) {
        print('❌ AccountBalanceService: User not authenticated');
        return false;
      }

      // Validate inputs
      if (amount <= 0) {
        print('❌ Transfer amount must be greater than 0');
        return false;
      }

      if (fromAccountId == toAccountId) {
        print('❌ Cannot transfer to the same account');
        return false;
      }

      // Check if source account has sufficient balance
      final fromBalance = await getAccountBalance(fromAccountId);
      if (fromBalance < amount) {
        print('❌ Insufficient balance in source account. Available: ₹$fromBalance, Required: ₹$amount');
        return false;
      }

      // Ensure both account balance documents exist
      await ensureAccountBalanceExists(fromAccountId);
      await ensureAccountBalanceExists(toAccountId);

      print('💸 Transferring ₹${amount.toStringAsFixed(2)} from $fromAccountId to $toAccountId');

      // Use Firestore transaction for atomicity
      try {
        return await _firestore.runTransaction<bool>((transaction) async {
          // First, validate balances exist within transaction
          final fromDoc = await transaction.get(_balancesRef.doc(fromAccountId));
          final toDoc = await transaction.get(_balancesRef.doc(toAccountId));

          if (!fromDoc.exists) {
            throw Exception('Source account balance document not found');
          }

          if (!toDoc.exists) {
            throw Exception('Destination account balance document not found');
          }

          // Check balance within transaction
          final fromBalanceData = fromDoc.data() as Map<String, dynamic>;
          final currentFromBalance = (fromBalanceData['balance'] as num).toDouble();
          
          if (currentFromBalance < amount) {
            throw Exception('Insufficient balance in source account');
          }

          // Update balances within transaction
          transaction.update(_balancesRef.doc(fromAccountId), {
            'balance': FieldValue.increment(-amount),
            'lastUpdated': DateTime.now().millisecondsSinceEpoch,
          });

          transaction.update(_balancesRef.doc(toAccountId), {
            'balance': FieldValue.increment(amount),
            'lastUpdated': DateTime.now().millisecondsSinceEpoch,
          });

          // Create transfer record with transaction timestamp
          final transferId = _transfersRef.doc().id;
          final transfer = AccountTransfer(
            id: transferId,
            fromAccountId: fromAccountId,
            toAccountId: toAccountId,
            amount: amount,
            note: note,
            timestamp: DateTime.now(),
          );

          // Save transfer record within transaction
          transaction.set(_transfersRef.doc(transferId), transfer.toJson());

          print('✅ Transfer completed successfully');
          return true;
        });
      } catch (e) {
        // Re-throw the exception so UI can handle it
        throw Exception('Transfer failed: ${e.toString()}');
      }
    } catch (e) {
      print('❌ Error transferring between accounts: $e');
      // Re-throw so UI can show specific error message
      rethrow;
    }
  }

  // Get ledger entries for an account
  Future<List<LedgerEntry>> getAccountLedger(String accountId, {int limit = 50}) async {
    try {
      final snapshot = await _ledgerRef
          .where('accountId', isEqualTo: accountId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      List<LedgerEntry> entries = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        entries.add(LedgerEntry.fromJson(data));
      }

      return entries;
    } catch (e) {
      print('Error getting account ledger: $e');
      return [];
    }
  }

  // Get all ledger entries
  Future<List<LedgerEntry>> getAllLedgerEntries({int limit = 100}) async {
    try {
      final snapshot = await _ledgerRef
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      List<LedgerEntry> entries = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        entries.add(LedgerEntry.fromJson(data));
      }

      return entries;
    } catch (e) {
      print('Error getting all ledger entries: $e');
      return [];
    }
  }

  // Process ride transactions (fees and payments)
  Future<bool> processRideTransactions({
    required String rideId,
    required Map<String, double> feeDeductions, // accountId -> amount
    required Map<String, double> paymentCredits, // accountId -> amount
    Map<String, TransactionCategory>? feeCategories, // accountId -> category
  }) async {
    try {
      // Process fee deductions
      for (final entry in feeDeductions.entries) {
        // Determine category - use provided mapping or default based on account type
        final category = feeCategories?[entry.key] ?? TransactionCategory.tollFee;
        final description = _getFeeDescription(category);
        
        await addTransaction(
          accountId: entry.key,
          rideId: rideId,
          type: TransactionType.debit,
          category: category,
          nature: TransactionNature.expense,
          amount: entry.value,
          description: description,
          reference: rideId,
        );
      }

      // Process payment credits
      for (final entry in paymentCredits.entries) {
        await addTransaction(
          accountId: entry.key,
          rideId: rideId,
          type: TransactionType.credit,
          category: TransactionCategory.paymentReceived,
          nature: TransactionNature.earning,
          amount: entry.value,
          description: 'Payment received',
          reference: rideId,
        );
      }

      return true;
    } catch (e) {
      print('Error processing ride transactions: $e');
      return false;
    }
  }

  // Helper method to get description for fee category
  String _getFeeDescription(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.tollFee:
        return 'Toll fee';
      case TransactionCategory.platformFee:
        return 'Platform fee';
      case TransactionCategory.airportFee:
        return 'Airport fee';
      case TransactionCategory.otherFee:
        return 'Other fee';
      default:
        return 'Ride fee';
    }
  }

  // Stream for account balance updates
  Stream<Map<String, double>> getAccountBalancesStream() {
    return _balancesRef.snapshots().map((snapshot) {
      Map<String, double> balances = {};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        balances[data['accountId']] = (data['balance'] as num).toDouble();
      }
      return balances;
    });
  }

  // Get recent transactions
  Future<List<LedgerEntry>> getRecentTransactions({int limit = 20}) async {
    try {
      if (_currentUserId == null) {
        print('❌ AccountBalanceService: User not authenticated');
        return [];
      }

      print('📝 Fetching recent transactions (limit: $limit)');
      
      final querySnapshot = await _ledgerRef
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final transactions = <LedgerEntry>[];
      
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Add document ID
          
          final transaction = LedgerEntry.fromJson(data);
          transactions.add(transaction);
        } catch (e) {
          print('⚠️ Error parsing transaction ${doc.id}: $e');
          // Continue with other transactions
        }
      }

      print('✅ Retrieved ${transactions.length} recent transactions');
      return transactions;
    } catch (e) {
      print('❌ Error fetching recent transactions: $e');
      return [];
    }
  }

  // Get recent account transfers
  Future<List<AccountTransfer>> getRecentTransfers({int limit = 20}) async {
    try {
      if (_currentUserId == null) {
        print('❌ AccountBalanceService: User not authenticated');
        return [];
      }

      print('💸 Fetching recent transfers (limit: $limit)');
      
      final querySnapshot = await _transfersRef
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final transfers = <AccountTransfer>[];
      
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Add document ID
          
          final transfer = AccountTransfer.fromJson(data);
          transfers.add(transfer);
        } catch (e) {
          print('⚠️ Error parsing transfer ${doc.id}: $e');
          // Continue with other transfers
        }
      }

      print('✅ Retrieved ${transfers.length} recent transfers');
      return transfers;
    } catch (e) {
      print('❌ Error fetching recent transfers: $e');
      return [];
    }
  }

  // Delete all account-related data for the current user
  Future<bool> deleteAllAccountData() async {
    try {
      if (_currentUserId == null) {
        print('❌ AccountBalanceService: User not authenticated');
        return false;
      }

      print('🗑️ Deleting all account data for user: $_currentUserId');

      // Delete all account balances
      final balancesSnapshot = await _balancesRef.get();
      for (final doc in balancesSnapshot.docs) {
        await doc.reference.delete();
        print('✅ Deleted account balance: ${doc.id}');
      }

      // Delete all ledger entries
      final ledgerSnapshot = await _ledgerRef.get();
      for (final doc in ledgerSnapshot.docs) {
        await doc.reference.delete();
        print('✅ Deleted ledger entry: ${doc.id}');
      }

      // Delete all account transfers
      final transfersSnapshot = await _transfersRef.get();
      for (final doc in transfersSnapshot.docs) {
        await doc.reference.delete();
        print('✅ Deleted account transfer: ${doc.id}');
      }

      // Delete pending fuel allocation
      final fuelAllocationSnapshot = await _pendingFuelAllocationRef.get();
      for (final doc in fuelAllocationSnapshot.docs) {
        await doc.reference.delete();
        print('✅ Deleted fuel allocation: ${doc.id}');
      }

      print('✅ All account data deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting account data: $e');
      return false;
    }
  }

  // Add fuel allocation from a completed ride
  Future<bool> addPendingFuelAllocation(double amount, String rideId) async {
    try {
      if (_currentUserId == null) return false;
      
      final doc = _pendingFuelAllocationRef.doc('current');
      final snapshot = await doc.get();
      
      if (snapshot.exists) {
        // Update existing allocation
        final data = snapshot.data() as Map<String, dynamic>;
        final currentAmount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final rideIds = List<String>.from(data['rideIds'] ?? []);
        
        await doc.update({
          'amount': currentAmount + amount,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
          'rideIds': [...rideIds, rideId],
        });
      } else {
        // Create new allocation
        await doc.set({
          'id': 'current',
          'amount': amount,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
          'rideIds': [rideId],
        });
      }
      
      print('✅ Added fuel allocation: ₹$amount from ride $rideId');
      return true;
    } catch (e) {
      print('❌ Error adding fuel allocation: $e');
      return false;
    }
  }

  // Get current pending fuel allocation
  Future<PendingFuelAllocation?> getPendingFuelAllocation() async {
    try {
      if (_currentUserId == null) return null;
      
      final doc = await _pendingFuelAllocationRef.doc('current').get();
      if (!doc.exists) return null;
      
      return PendingFuelAllocation.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('❌ Error getting fuel allocation: $e');
      return null;
    }
  }

  // Get pending fuel allocation stream for real-time updates
  Stream<PendingFuelAllocation?> getPendingFuelAllocationStream() {
    return _pendingFuelAllocationRef.doc('current').snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return PendingFuelAllocation.fromJson(snapshot.data() as Map<String, dynamic>);
    });
  }

  // Transfer fuel allocation to Fuel Reserve account
  Future<bool> transferFuelAllocation({
    required String fromAccountId,
    required double amount,
    String? note,
  }) async {
    try {
      if (_currentUserId == null) return false;
      
      // Transfer to axis_bank (Fuel Reserve)
      final success = await transferBetweenAccounts(
        fromAccountId: fromAccountId,
        toAccountId: 'axis_bank',
        amount: amount,
        note: note ?? 'Fuel allocation transfer',
      );
      
      if (!success) return false;
      
      // Update pending allocation (subtract transferred amount)
      final doc = _pendingFuelAllocationRef.doc('current');
      final snapshot = await doc.get();
      
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final currentAmount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final newAmount = currentAmount - amount;
        
        if (newAmount <= 0.01) {
          // Clear if amount is negligible
          await doc.delete();
        } else {
          await doc.update({
            'amount': newAmount,
            'lastUpdated': DateTime.now().millisecondsSinceEpoch,
          });
        }
      }
      
      print('✅ Transferred fuel allocation: ₹$amount');
      return true;
    } catch (e) {
      print('❌ Error transferring fuel allocation: $e');
      return false;
    }
  }

  // Adjust pending fuel allocation (increase or decrease)
  Future<bool> adjustPendingFuelAllocation(double adjustmentAmount) async {
    try {
      if (_currentUserId == null) return false;
      
      final doc = _pendingFuelAllocationRef.doc('current');
      final snapshot = await doc.get();
      
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final currentAmount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final newAmount = currentAmount + adjustmentAmount;
        
        if (newAmount <= 0) {
          // Delete if zero or negative
          await doc.delete();
        } else {
          await doc.update({
            'amount': newAmount,
            'lastUpdated': DateTime.now().millisecondsSinceEpoch,
          });
        }
      } else if (adjustmentAmount > 0) {
        // Create new if doesn't exist and adjustment is positive
        await doc.set({
          'id': 'current',
          'amount': adjustmentAmount,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
          'rideIds': [],
        });
      }
      
      print('✅ Adjusted fuel allocation by: ₹$adjustmentAmount');
      return true;
    } catch (e) {
      print('❌ Error adjusting fuel allocation: $e');
      return false;
    }
  }

  // Clear pending fuel allocation completely
  Future<bool> clearPendingFuelAllocation() async {
    try {
      if (_currentUserId == null) return false;
      
      await _pendingFuelAllocationRef.doc('current').delete();
      print('✅ Cleared pending fuel allocation');
      return true;
    } catch (e) {
      print('❌ Error clearing fuel allocation: $e');
      return false;
    }
  }

  // Debug method to create test fuel allocation (remove in production)
  Future<bool> createTestFuelAllocation() async {
    try {
      if (_currentUserId == null) return false;
      
      await _pendingFuelAllocationRef.doc('current').set({
        'id': 'current',
        'amount': 250.0,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'rideIds': ['test_ride_1', 'test_ride_2'],
      });
      
      print('✅ Created test fuel allocation: ₹250.00');
      return true;
    } catch (e) {
      print('❌ Error creating test fuel allocation: $e');
      return false;
    }
  }

  // Add refuel record to both refuels collection and ledger
  Future<bool> addRefuel({
    required double cost,
    required double kilometers,
    String? location,
    String? notes,
  }) async {
    try {
      if (_currentUserId == null) return false;
      
      final timestamp = DateTime.now();
      
      // 1. Add to refuels collection
      final refuelDoc = await _refuelsRef.add({
        'cost': cost,
        'kilometers': kilometers,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'location': location,
        'notes': notes,
      });
      
      // 2. Add to ledger as expense
      final ledgerSuccess = await addTransaction(
        accountId: 'axis_bank', // Fuel Reserve account
        rideId: 'refuel_${timestamp.millisecondsSinceEpoch}', // Unique refuel ID
        amount: cost, // Positive value - debit type will subtract it
        type: TransactionType.debit,
        category: TransactionCategory.fuel,
        nature: TransactionNature.expense,
        description: 'Refuel - ${kilometers.toStringAsFixed(0)} km${location != null ? ' at $location' : ''}',
      );
      
      if (!ledgerSuccess) {
        // If ledger fails, delete the refuel record
        await refuelDoc.delete();
        return false;
      }
      
      print('✅ Added refuel record: ₹$cost for ${kilometers.toStringAsFixed(0)} km');
      return true;
    } catch (e) {
      print('❌ Error adding refuel record: $e');
      return false;
    }
  }

  // Get refuel records stream
  Stream<List<Refuel>> getRefuelsStream() {
    return _refuelsRef
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Refuel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    });
  }

  // Get refuel records (one-time fetch)
  Future<List<Refuel>> getRefuels() async {
    try {
      if (_currentUserId == null) return [];
      
      final snapshot = await _refuelsRef
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Refuel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      print('❌ Error getting refuel records: $e');
      return [];
    }
  }

  // Delete refuel record (and corresponding ledger entry)
  Future<bool> deleteRefuel(String refuelId) async {
    try {
      if (_currentUserId == null) return false;
      
      // Get refuel data first
      final refuelDoc = await _refuelsRef.doc(refuelId).get();
      if (!refuelDoc.exists) return false;
      
      final refuelData = refuelDoc.data() as Map<String, dynamic>;
      final cost = (refuelData['cost'] as num).toDouble();
      final kilometers = (refuelData['kilometers'] as num).toDouble();
      
      // Delete refuel record
      await _refuelsRef.doc(refuelId).delete();
      
      // Note: We don't automatically delete ledger entries as they might be referenced elsewhere
      // User can manually adjust if needed
      
      print('✅ Deleted refuel record: ₹$cost for ${kilometers.toStringAsFixed(0)} km');
      return true;
    } catch (e) {
      print('❌ Error deleting refuel record: $e');
      return false;
    }
  }

  // Record expense transaction
  Future<bool> recordExpense({
    required String accountId,
    required TransactionCategory category,
    required double amount,
    required String description,
    DateTime? timestamp,
  }) async {
    try {
      if (_currentUserId == null) {
        print('❌ AccountBalanceService: User not authenticated');
        return false;
      }

      final expenseTimestamp = timestamp ?? DateTime.now();
      final expenseId = DateTime.now().millisecondsSinceEpoch.toString();

      // Ensure account balance exists
      await ensureAccountBalanceExists(accountId);

      // Create ledger entry
      final ledgerEntry = LedgerEntry(
        id: expenseId,
        accountId: accountId,
        rideId: '', // Empty for non-ride expenses
        type: TransactionType.debit,
        category: category,
        nature: TransactionNature.expense,
        amount: amount,
        description: description,
        timestamp: expenseTimestamp,
      );

      // Save ledger entry
      await _ledgerRef.doc(expenseId).set(ledgerEntry.toJson());

      // Update account balance (deduct amount)
      await _balancesRef.doc(accountId).update({
        'balance': FieldValue.increment(-amount),
        'lastUpdated': expenseTimestamp.millisecondsSinceEpoch,
      });

      print('✅ Recorded expense: ${category.name} - ₹${amount.toStringAsFixed(2)} from account $accountId');
      return true;
    } catch (e) {
      print('❌ Error recording expense: $e');
      return false;
    }
  }

  // Reverse all transactions related to a specific ride
  Future<bool> reverseRideTransactions(String rideId) async {
    try {
      if (_currentUserId == null) {
        print('❌ AccountBalanceService: User not authenticated');
        return false;
      }

      print('🔄 Reversing transactions for ride: $rideId');

      // Get all ledger entries for this ride
      final ledgerEntries = await _ledgerRef
          .where('rideId', isEqualTo: rideId)
          .get();

      print('📊 Found ${ledgerEntries.docs.length} ledger entries to reverse');

      // Process each ledger entry
      for (final doc in ledgerEntries.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final ledgerEntry = LedgerEntry.fromJson(data);
        
        print('🔄 Reversing entry: ${ledgerEntry.category.name} - ${ledgerEntry.type.name} - ₹${ledgerEntry.amount}');

        // Reverse the transaction
        double adjustmentAmount;
        if (ledgerEntry.type == TransactionType.debit) {
          // If it was a debit (fee), add the amount back (credit)
          adjustmentAmount = ledgerEntry.amount;
        } else {
          // If it was a credit (payment), subtract the amount (debit)
          adjustmentAmount = -ledgerEntry.amount;
        }

        // Update account balance
        await _balancesRef.doc(ledgerEntry.accountId).update({
          'balance': FieldValue.increment(adjustmentAmount),
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        });

        print('✅ Reversed ${ledgerEntry.category.name}: ₹${adjustmentAmount} for account ${ledgerEntry.accountId}');
      }

      // Delete all ledger entries for this ride
      for (final doc in ledgerEntries.docs) {
        await doc.reference.delete();
      }

      print('✅ Successfully reversed all transactions for ride: $rideId');
      return true;
    } catch (e) {
      print('❌ Error reversing ride transactions: $e');
      return false;
    }
  }

  // Initialize all account balances for the current user
  Future<bool> initializeAllAccountBalances() async {
    try {
      if (_currentUserId == null) {
        print('❌ AccountBalanceService: User not authenticated');
        return false;
      }

      print('🔄 Initializing all account balances for user $_currentUserId');

      final accounts = Account.getSampleAccounts();
      final batch = _firestore.batch();

      for (final account in accounts) {
        final docRef = _balancesRef.doc(account.id);
        
        // Check if document already exists
        final doc = await docRef.get();
        
        if (!doc.exists) {
          batch.set(docRef, {
            'accountId': account.id,
            'accountName': account.name,
            'accountType': account.type,
            'balance': 0.0,
            'lastUpdated': DateTime.now().millisecondsSinceEpoch,
          });
          print('📝 Creating account balance for ${account.name}');
        }
      }

      await batch.commit();
      print('✅ Initialized all account balances');
      return true;
    } catch (e) {
      print('❌ Error initializing account balances: $e');
      return false;
    }
  }

  // Get multiple account balances at once
  Future<Map<String, double>> getMultipleAccountBalances(List<String> accountIds) async {
    try {
      if (_currentUserId == null) {
        print('❌ AccountBalanceService: User not authenticated');
        return {};
      }

      print('📊 Fetching multiple account balances: ${accountIds.length} accounts');

      final balances = <String, double>{};
      
      // Fetch all accounts in parallel
      final futures = accountIds.map((accountId) async {
        final balance = await getAccountBalance(accountId);
        return {accountId: balance};
      });

      final results = await Future.wait(futures);
      
      for (final result in results) {
        balances.addAll(result);
      }

      print('✅ Retrieved ${balances.length} account balances');
      return balances;
    } catch (e) {
      print('❌ Error fetching multiple account balances: $e');
      return {};
    }
  }

  // Process ride transactions atomically (for ride updates)
  Future<bool> processRideTransactionsAtomically({
    required String rideId,
    required Map<String, double> feeDeductions,
    required Map<String, double> paymentCredits,
    required Map<String, dynamic> rideData,
    double? fuelAllocation,
    Map<String, TransactionCategory>? feeCategories,
  }) async {
    try {
      if (_currentUserId == null) {
        print('❌ AccountBalanceService: User not authenticated');
        return false;
      }

      print('🔄 Processing ride transactions atomically for ride: $rideId');

      // First, reverse old transactions OUTSIDE the transaction
      await reverseRideTransactions(rideId);

      return await _firestore.runTransaction<bool>((transaction) async {
        // Create new transactions
        final timestamp = DateTime.now();

        // 1. Process payment credits (credits)
        for (final entry in paymentCredits.entries) {
          final accountId = entry.key;
          final amount = entry.value;
          
          // Ensure account balance exists
          await ensureAccountBalanceExists(accountId);
          
          transaction.set(_ledgerRef.doc('${timestamp.millisecondsSinceEpoch}_${accountId}_credit'), {
            'id': '${timestamp.millisecondsSinceEpoch}_${accountId}_credit',
            'accountId': accountId,
            'rideId': rideId,
            'type': 'credit',
            'category': 'paymentReceived',
            'nature': 'earning',
            'amount': amount,
            'description': 'Payment received from ride',
            'timestamp': timestamp.millisecondsSinceEpoch,
            'reference': rideId,
          });

          transaction.update(_balancesRef.doc(accountId), {
            'balance': FieldValue.increment(amount),
            'lastUpdated': timestamp.millisecondsSinceEpoch,
          });
        }

        // 2. Process fee deductions (debits)
        for (final entry in feeDeductions.entries) {
          final accountId = entry.key;
          final amount = entry.value;
          
          // Ensure account balance exists
          await ensureAccountBalanceExists(accountId);
          
          // Determine category from provided mapping or default to otherFee
          final category = feeCategories?[accountId] ?? TransactionCategory.otherFee;
          final categoryString = category.name;

          transaction.set(_ledgerRef.doc('${timestamp.millisecondsSinceEpoch}_${accountId}_${categoryString}'), {
            'id': '${timestamp.millisecondsSinceEpoch}_${accountId}_${categoryString}',
            'accountId': accountId,
            'rideId': rideId,
            'type': 'debit',
            'category': categoryString,
            'nature': 'expense',
            'amount': amount.abs(),
            'description': _getFeeDescription(category),
            'timestamp': timestamp.millisecondsSinceEpoch,
            'reference': rideId,
          });

          // Handle negative amounts (adjustments) by incrementing instead of decrementing
          final updateAmount = amount < 0 ? amount.abs() : -amount;
          transaction.update(_balancesRef.doc(accountId), {
            'balance': FieldValue.increment(updateAmount),
            'lastUpdated': timestamp.millisecondsSinceEpoch,
          });
        }

        // 3. Update ride document
        transaction.update(
          _firestore.collection('users').doc(_currentUserId).collection('rides').doc(rideId),
          rideData,
        );

        // 4. Process fuel allocation if provided
        if (fuelAllocation != null && fuelAllocation > 0) {
          final fuelDocRef = _pendingFuelAllocationRef.doc('current');
          transaction.set(fuelDocRef, {
            'id': 'current',
            'amount': FieldValue.increment(fuelAllocation),
            'lastUpdated': timestamp.millisecondsSinceEpoch,
            'rideIds': FieldValue.arrayUnion([rideId]),
          }, SetOptions(merge: true));
        }

        print('✅ Ride transaction processed atomically for ride: $rideId');
        return true;
      });
    } catch (e) {
      print('❌ Error processing ride transactions atomically: $e');
      return false;
    }
  }

  // Adjust account balance manually
  Future<bool> adjustAccountBalance({
    required String accountId,
    required double adjustmentAmount,
    required String reason,
  }) async {
    try {
      if (_currentUserId == null) {
        print('❌ AccountBalanceService: User not authenticated');
        return false;
      }

      print('📊 Adjusting balance for account $accountId by ₹${adjustmentAmount.toStringAsFixed(2)}');

      // Update balance
      await _balancesRef.doc(accountId).update({
        'balance': FieldValue.increment(adjustmentAmount),
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });

      // Create ledger entry for audit
      final ledgerId = _ledgerRef.doc().id;
      final ledgerEntry = LedgerEntry(
        id: ledgerId,
        accountId: accountId,
        rideId: '', // Empty for manual adjustments
        type: adjustmentAmount > 0 ? TransactionType.credit : TransactionType.debit,
        category: TransactionCategory.adjustment,
        nature: TransactionNature.adjustment,
        amount: adjustmentAmount.abs(),
        description: reason,
        timestamp: DateTime.now(),
      );

      await _ledgerRef.doc(ledgerId).set(ledgerEntry.toJson());

      print('✅ Balance adjusted successfully');
      return true;
    } catch (e) {
      print('❌ Error adjusting account balance: $e');
      return false;
    }
  }

  // Get all account transactions (ledger + transfers) with unified format
  Future<List<Map<String, dynamic>>> getAllAccountTransactions() async {
    try {
      if (_currentUserId == null) {
        print('❌ AccountBalanceService: User not authenticated');
        return [];
      }

      print('📝 Fetching all account transactions');

      // Fetch all ledger entries
      final ledgerSnapshot = await _ledgerRef.get();
      List<Map<String, dynamic>> transactions = [];

      for (final doc in ledgerSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['transactionType'] = 'ledger';
        transactions.add(data);
      }

      // Fetch all transfers
      final transfersSnapshot = await _transfersRef.get();
      for (final doc in transfersSnapshot.docs) {
        final transferData = doc.data() as Map<String, dynamic>;
        final fromAccount = transferData['fromAccountId'];
        final toAccount = transferData['toAccountId'];
        final amount = transferData['amount'] as num;
        final timestamp = transferData['timestamp'] as int;
        final note = transferData['note'];
        
        // Add as two separate transactions (debit from source, credit to destination)
        transactions.add({
          'id': '${doc.id}_from',
          'type': 'debit',
          'accountId': fromAccount,
          'amount': amount.toDouble(),
          'description': 'Transfer to ${Account.getSampleAccounts().firstWhere((a) => a.id == toAccount).name}',
          'timestamp': timestamp,
          'transactionType': 'transfer',
          'nature': 'transfer',
          'reference': doc.id,
          'note': note,
        });

        transactions.add({
          'id': '${doc.id}_to',
          'type': 'credit',
          'accountId': toAccount,
          'amount': amount.toDouble(),
          'description': 'Transfer from ${Account.getSampleAccounts().firstWhere((a) => a.id == fromAccount).name}',
          'timestamp': timestamp,
          'transactionType': 'transfer',
          'nature': 'transfer',
          'reference': doc.id,
          'note': note,
        });
      }

      // Sort by timestamp descending
      transactions.sort((a, b) {
        final timestampA = a['timestamp'] as int;
        final timestampB = b['timestamp'] as int;
        return timestampB.compareTo(timestampA);
      });

      print('✅ Retrieved ${transactions.length} transactions');
      return transactions;
    } catch (e) {
      print('❌ Error fetching all account transactions: $e');
      return [];
    }
  }

  // Delete a transaction and reverse balance changes
  Future<bool> deleteTransaction({
    required String transactionId,
    required String transactionType,
  }) async {
    try {
      if (_currentUserId == null) {
        print('❌ AccountBalanceService: User not authenticated');
        return false;
      }

      print('🗑️ Deleting transaction: $transactionId (type: $transactionType)');

      if (transactionType == 'ledger') {
        // Load ledger entry
        final doc = await _ledgerRef.doc(transactionId).get();
        if (!doc.exists) {
          print('Transaction not found');
          return false;
        }

        final data = doc.data() as Map<String, dynamic>;
        final accountId = data['accountId'] as String;
        final amount = (data['amount'] as num).toDouble();
        final type = data['type'] as String;

        // Reverse the balance change
        final reverseAmount = type == 'credit' ? -amount : amount;
        await _balancesRef.doc(accountId).update({
          'balance': FieldValue.increment(reverseAmount),
        });

        // Delete ledger entry
        await _ledgerRef.doc(transactionId).delete();
        print('✅ Deleted ledger entry and reversed balance');
        return true;

      } else if (transactionType == 'transfer') {
        // For transfers, we need to handle both sides
        // Extract the base ID from transactionId (remove _from or _to suffix)
        final baseId = transactionId.replaceAll(RegExp(r'_(from|to)$'), '');
        
        // Load the full transfer document
        final transferDoc = await _transfersRef.doc(baseId).get();
        if (!transferDoc.exists) {
          print('Transfer not found');
          return false;
        }

        final transferData = transferDoc.data() as Map<String, dynamic>;
        final fromAccount = transferData['fromAccountId'] as String;
        final toAccount = transferData['toAccountId'] as String;
        final amount = (transferData['amount'] as num).toDouble();

        // Reverse both accounts
        await _balancesRef.doc(fromAccount).update({
          'balance': FieldValue.increment(amount),
        });
        
        await _balancesRef.doc(toAccount).update({
          'balance': FieldValue.increment(-amount),
        });

        // Delete transfer document
        await _transfersRef.doc(baseId).delete();
        print('✅ Deleted transfer and reversed balances');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Error deleting transaction: $e');
      return false;
    }
  }
}

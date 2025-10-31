import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../models/account.dart';
import '../models/ledger_entry.dart';
import '../models/account_transfer.dart';
import '../models/pending_fuel_allocation.dart';
import '../models/refuel.dart';
import '../models/pending_tips.dart';
import '../models/account_balance.dart';
import 'local_storage_service.dart';
import '../utils/debug_logger.dart';

class AccountBalanceService {
  static final AccountBalanceService _instance = AccountBalanceService._internal();
  factory AccountBalanceService() => _instance;
  AccountBalanceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalStorageService _localStorage = LocalStorageService();
  final Random _random = Random();

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Generate unique IDs for new documents
  String _generateId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(10000);
    return '${prefix}_${timestamp}_$random';
  }

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

  // Get pending tips collection for current user
  CollectionReference get _pendingTipsRef {
    if (_currentUserId == null) {
      print('❌ AccountBalanceService: User not authenticated');
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(_currentUserId!).collection('pendingTips');
  }

  // Create account balance document if it doesn't exist
  Future<bool> ensureAccountBalanceExists(String accountId) async {
    try {
      final existing = await _localStorage.getAccountBalance(accountId);
      
      if (existing == null) {
        DebugLogger.log('Creating account balance document for $accountId');
        final accounts = Account.getSampleAccounts();
        final account = accounts.firstWhere(
          (a) => a.id == accountId,
          orElse: () => accounts.first,
        );
        
        final newBalance = AccountBalance(
          accountId: accountId,
          accountName: account.name,
          accountType: account.type,
          balance: 0.0,
          lastUpdated: DateTime.now(),
        );
        
        await _localStorage.saveAccountBalance(newBalance);
        DebugLogger.log('Created account balance document for $accountId');
        return true;
      }
      
      return true; // Already exists
    } catch (e) {
      DebugLogger.logError('Error ensuring account balance exists for $accountId: $e');
      return false;
    }
  }

  // Check if account balances are already initialized
  Future<bool> areAccountBalancesInitialized() async {
    try {
      final balances = await _localStorage.getAllAccountBalances();
      return balances.isNotEmpty;
    } catch (e) {
      DebugLogger.logError('Error checking if account balances are initialized: $e');
      return false;
    }
  }

  // Initialize account balances (call this once when user first signs up)
  Future<void> initializeAccountBalances() async {
    try {
      DebugLogger.log('Starting account balance initialization...');
      DebugLogger.log('Current user ID: $_currentUserId');
      
      if (_currentUserId == null) {
        DebugLogger.logError('User not authenticated');
        throw Exception('User not authenticated');
      }
      
      // Check if already initialized
      final alreadyInitialized = await areAccountBalancesInitialized();
      if (alreadyInitialized) {
        DebugLogger.log('Account balances already initialized, skipping...');
        return;
      }
      
      final accounts = Account.getSampleAccounts();
      DebugLogger.log('Sample accounts: ${accounts.length}');
      
      for (final account in accounts) {
        DebugLogger.log('Creating account balance for: ${account.id}');
        final accountBalance = AccountBalance(
          accountId: account.id,
          accountName: account.name,
          accountType: account.type,
          balance: account.balance,
          lastUpdated: DateTime.now(),
        );
        await _localStorage.saveAccountBalance(accountBalance);
        DebugLogger.log('Created account balance for: ${account.id}');
      }
      
      DebugLogger.logSuccess('Account balances initialized successfully');
    } catch (e) {
      DebugLogger.logError('Error initializing account balances: $e');
      rethrow; // Re-throw to show error in UI
    }
  }

  // Get current balance for an account (returns 0 if document doesn't exist)
  Future<double> getAccountBalance(String accountId) async {
    try {
      DebugLogger.log('Fetching balance for account: $accountId');
      
      final accountBalance = await _localStorage.getAccountBalance(accountId);
      if (accountBalance != null) {
        DebugLogger.log('Found balance document: ₹${accountBalance.balance.toStringAsFixed(2)}');
        return accountBalance.balance;
      } else {
        DebugLogger.log('Account balance document for $accountId does not exist, returning 0');
        return 0.0;
      }
    } catch (e) {
      DebugLogger.logError('Error getting account balance for $accountId: $e');
      return 0.0;
    }
  }

  // Get all account balances
  Future<List<Map<String, dynamic>>> getAllAccountBalances() async {
    try {
      final balanceObjects = await _localStorage.getAllAccountBalanceObjects();
      return balanceObjects.values.map((balance) => balance.toJson()).toList();
    } catch (e) {
      DebugLogger.logError('Error getting all account balances: $e');
      return [];
    }
  }

  // Update account balance (creates document if it doesn't exist)
  Future<bool> updateAccountBalance(String accountId, double newBalance) async {
    try {
      DebugLogger.log('Updating account balance for $accountId to $newBalance');
      
      final existing = await _localStorage.getAccountBalance(accountId);
      final now = DateTime.now();
      
      if (existing != null) {
        // Update existing document
        final updated = existing.copyWith(
          balance: newBalance,
          lastUpdated: now,
        );
        await _localStorage.saveAccountBalance(updated);
        DebugLogger.log('Updated existing account balance for $accountId');
      } else {
        // Create new document with default values
        final accounts = Account.getSampleAccounts();
        final account = accounts.firstWhere(
          (a) => a.id == accountId,
          orElse: () => accounts.first,
        );
        
        final newAccountBalance = AccountBalance(
          accountId: accountId,
          accountName: account.name,
          accountType: account.type,
          balance: newBalance,
          lastUpdated: now,
        );
        await _localStorage.saveAccountBalance(newAccountBalance);
        DebugLogger.log('Created new account balance document for $accountId');
      }
      
      return true;
    } catch (e) {
      DebugLogger.logError('Error updating account balance for $accountId: $e');
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
      DebugLogger.log('Adding transaction: $type $amount to account $accountId');
      
      // Create ledger entry
      final ledgerId = _generateId('ledger');
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
      await _localStorage.saveLedgerEntry(ledgerEntry);
      DebugLogger.log('Added ledger entry: ${ledgerEntry.formattedAmount}');

      // Update account balance (this will create document if it doesn't exist)
      final currentBalance = await getAccountBalance(accountId);
      final newBalance = type == TransactionType.credit 
          ? currentBalance + amount 
          : currentBalance - amount;
      
      await updateAccountBalance(accountId, newBalance);

      DebugLogger.log('Transaction completed: ${ledgerEntry.formattedAmount} to account $accountId');
      return true;
    } catch (e) {
      DebugLogger.logError('Error adding transaction: $e');
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
        DebugLogger.logError('AccountBalanceService: User not authenticated');
        return false;
      }

      // Validate inputs
      if (amount <= 0) {
        DebugLogger.logError('Transfer amount must be greater than 0');
        return false;
      }

      if (fromAccountId == toAccountId) {
        DebugLogger.logError('Cannot transfer to the same account');
        return false;
      }

      // Check if source account has sufficient balance
      final fromBalanceObj = await _localStorage.getAccountBalance(fromAccountId);
      if (fromBalanceObj == null || fromBalanceObj.balance < amount) {
        final available = fromBalanceObj?.balance ?? 0.0;
        DebugLogger.logError('Insufficient balance in source account. Available: ₹$available, Required: ₹$amount');
        throw Exception('Insufficient balance in source account');
      }

      // Ensure both account balance documents exist
      await ensureAccountBalanceExists(fromAccountId);
      await ensureAccountBalanceExists(toAccountId);

      DebugLogger.log('Transferring ₹${amount.toStringAsFixed(2)} from $fromAccountId to $toAccountId');

      // Get current balances
      final fromBalance = await _localStorage.getAccountBalance(fromAccountId);
      final toBalance = await _localStorage.getAccountBalance(toAccountId);

      if (fromBalance == null || toBalance == null) {
        throw Exception('Account balance documents not found');
      }

      final now = DateTime.now();

      // Update balances (local storage operations are atomic)
      await _localStorage.updateAccountBalance(fromAccountId, fromBalance.balance - amount);
      await _localStorage.updateAccountBalance(toAccountId, toBalance.balance + amount);

      // Create transfer record
      final transferId = _generateId('transfer');
      final transfer = AccountTransfer(
        id: transferId,
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        amount: amount,
        note: note,
        timestamp: now,
      );

      // Save transfer record
      await _localStorage.saveTransfer(transfer);

      DebugLogger.logSuccess('Transfer completed successfully');
      return true;
    } catch (e) {
      DebugLogger.logError('Error transferring between accounts: $e');
      // Re-throw so UI can show specific error message
      rethrow;
    }
  }

  // Get ledger entries for an account
  Future<List<LedgerEntry>> getAccountLedger(String accountId, {int limit = 50}) async {
    try {
      final entries = await _localStorage.getLedgerEntriesByAccount(accountId);
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries.take(limit).toList();
    } catch (e) {
      DebugLogger.logError('Error getting account ledger: $e');
      return [];
    }
  }

  // Get all ledger entries
  Future<List<LedgerEntry>> getAllLedgerEntries({int limit = 100}) async {
    try {
      return await _localStorage.getRecentLedgerEntries(limit: limit);
    } catch (e) {
      DebugLogger.logError('Error getting all ledger entries: $e');
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
    try {
      return _localStorage.getAccountBalancesStream();
    } catch (e) {
      DebugLogger.logError('Error getting account balances stream: $e');
      return Stream.value({});
    }
  }

  // Get recent transactions
  Future<List<LedgerEntry>> getRecentTransactions({int limit = 20}) async {
    try {
      if (_currentUserId == null) {
        DebugLogger.logError('AccountBalanceService: User not authenticated');
        return [];
      }

      DebugLogger.log('Fetching recent transactions (limit: $limit)');
      
      final transactions = await _localStorage.getRecentLedgerEntries(limit: limit);
      
      DebugLogger.log('Retrieved ${transactions.length} recent transactions');
      return transactions;
    } catch (e) {
      DebugLogger.logError('Error fetching recent transactions: $e');
      return [];
    }
  }

  // Get recent account transfers
  Future<List<AccountTransfer>> getRecentTransfers({int limit = 20}) async {
    try {
      if (_currentUserId == null) {
        DebugLogger.logError('AccountBalanceService: User not authenticated');
        return [];
      }

      DebugLogger.log('Fetching recent transfers (limit: $limit)');
      
      final transfers = await _localStorage.getRecentTransfers(limit: limit);
      
      DebugLogger.log('Retrieved ${transfers.length} recent transfers');
      return transfers;
    } catch (e) {
      DebugLogger.logError('Error fetching recent transfers: $e');
      return [];
    }
  }

  // Delete all account-related data for the current user (both local and Firestore)
  Future<bool> deleteAllAccountData() async {
    try {
      if (_currentUserId == null) {
        DebugLogger.logError('AccountBalanceService: User not authenticated');
        return false;
      }

      DebugLogger.log('Deleting all account data for user: $_currentUserId (local and Firestore)');

      // Delete from local storage first
      await _localStorage.clearAllData();
      DebugLogger.log('Local data cleared');

      // Delete from Firestore - all collections
      try {
        final userRef = _firestore.collection('users').doc(_currentUserId!);
        
        // Collections to delete
        final collections = [
          'accountBalances',
          'ledger',
          'accountTransfers',
          'refuels',
          'pendingFuelAllocation',
          'pendingTips',
        ];
        
        // Delete each collection
        for (final collectionName in collections) {
          try {
            final collectionRef = userRef.collection(collectionName);
            final snapshot = await collectionRef.get();
            
            // Batch delete
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
            
            // Execute all batches for this collection
            for (final batch in batches) {
              await batch.commit();
            }
            
            DebugLogger.log('Deleted ${snapshot.docs.length} documents from Firestore collection: $collectionName');
          } catch (collectionError) {
            DebugLogger.logError('Error deleting collection $collectionName: $collectionError');
            // Continue with other collections
          }
        }
        
        DebugLogger.logSuccess('All Firestore account data deleted successfully');
      } catch (firestoreError) {
        DebugLogger.logError('Error deleting account data from Firestore (local deletion succeeded): $firestoreError');
        // Continue - local deletion succeeded
      }

      DebugLogger.logSuccess('All account data deleted successfully (local and Firestore)');
      return true;
    } catch (e) {
      DebugLogger.logError('Error deleting account data: $e');
      return false;
    }
  }

  // Add fuel allocation from a completed ride
  Future<bool> addPendingFuelAllocation(double amount, String rideId) async {
    try {
      if (_currentUserId == null) return false;
      
      final existing = await _localStorage.getPendingFuelAllocation();
      final now = DateTime.now();
      
      if (existing != null) {
        // Update existing allocation
        final updated = PendingFuelAllocation(
          id: existing.id,
          amount: existing.amount + amount,
          lastUpdated: now,
          rideIds: [...existing.rideIds, rideId],
        );
        await _localStorage.saveFuelAllocation(updated);
      } else {
        // Create new allocation
        final newAllocation = PendingFuelAllocation(
          id: 'current',
          amount: amount,
          lastUpdated: now,
          rideIds: [rideId],
        );
        await _localStorage.saveFuelAllocation(newAllocation);
      }
      
      DebugLogger.log('Added fuel allocation: ₹$amount from ride $rideId');
      return true;
    } catch (e) {
      DebugLogger.logError('Error adding fuel allocation: $e');
      return false;
    }
  }

  // Get current pending fuel allocation
  Future<PendingFuelAllocation?> getPendingFuelAllocation() async {
    try {
      if (_currentUserId == null) return null;
      return await _localStorage.getPendingFuelAllocation();
    } catch (e) {
      DebugLogger.logError('Error getting fuel allocation: $e');
      return null;
    }
  }

  // Get pending fuel allocation stream for real-time updates
  Stream<PendingFuelAllocation?> getPendingFuelAllocationStream() {
    try {
      return _localStorage.getPendingFuelAllocationStream();
    } catch (e) {
      DebugLogger.logError('Error getting fuel allocation stream: $e');
      return Stream.value(null);
    }
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
      final existing = await _localStorage.getPendingFuelAllocation();
      
      if (existing != null) {
        final newAmount = existing.amount - amount;
        
        if (newAmount <= 0.01) {
          // Clear if amount is negligible
          await _localStorage.clearPendingFuelAllocation();
        } else {
          final updated = PendingFuelAllocation(
            id: existing.id,
            amount: newAmount,
            lastUpdated: DateTime.now(),
            rideIds: existing.rideIds,
          );
          await _localStorage.saveFuelAllocation(updated);
        }
      }
      
      DebugLogger.log('Transferred fuel allocation: ₹$amount');
      return true;
    } catch (e) {
      DebugLogger.logError('Error transferring fuel allocation: $e');
      return false;
    }
  }

  // Adjust pending fuel allocation (increase or decrease)
  Future<bool> adjustPendingFuelAllocation(double adjustmentAmount) async {
    try {
      if (_currentUserId == null) return false;
      
      final existing = await _localStorage.getPendingFuelAllocation();
      
      if (existing != null) {
        final newAmount = existing.amount + adjustmentAmount;
        
        if (newAmount <= 0) {
          // Delete if zero or negative
          await _localStorage.clearPendingFuelAllocation();
        } else {
          final updated = PendingFuelAllocation(
            id: existing.id,
            amount: newAmount,
            lastUpdated: DateTime.now(),
            rideIds: existing.rideIds,
          );
          await _localStorage.saveFuelAllocation(updated);
        }
      } else if (adjustmentAmount > 0) {
        // Create new if doesn't exist and adjustment is positive
        final newAllocation = PendingFuelAllocation(
          id: 'current',
          amount: adjustmentAmount,
          lastUpdated: DateTime.now(),
          rideIds: [],
        );
        await _localStorage.saveFuelAllocation(newAllocation);
      }
      
      DebugLogger.log('Adjusted fuel allocation by: ₹$adjustmentAmount');
      return true;
    } catch (e) {
      DebugLogger.logError('Error adjusting fuel allocation: $e');
      return false;
    }
  }

  // Clear pending fuel allocation completely
  Future<bool> clearPendingFuelAllocation() async {
    try {
      if (_currentUserId == null) return false;
      
      await _localStorage.clearPendingFuelAllocation();
      DebugLogger.log('Cleared pending fuel allocation');
      return true;
    } catch (e) {
      DebugLogger.logError('Error clearing fuel allocation: $e');
      return false;
    }
  }

  // Add pending tip from a completed ride (accumulates positive tips only)
  Future<bool> addPendingTip(double amount, String rideId) async {
    try {
      if (_currentUserId == null) return false;
      if (amount <= 0) return true; // Ignore non-positive tips

      final existing = await _localStorage.getCurrentPendingTips();
      final now = DateTime.now();

      if (existing != null) {
        final updated = PendingTips(
          id: existing.id,
          amount: existing.amount + amount,
          lastUpdated: now,
          rideIds: [...existing.rideIds, rideId],
        );
        await _localStorage.savePendingTips(updated);
      } else {
        final newTips = PendingTips(
          id: 'current',
          amount: amount,
          lastUpdated: now,
          rideIds: [rideId],
        );
        await _localStorage.savePendingTips(newTips);
      }

      DebugLogger.log('Added pending tip: ₹$amount from ride $rideId');
      return true;
    } catch (e) {
      DebugLogger.logError('Error adding pending tip: $e');
      return false;
    }
  }

  // Get current pending tips (amount + ride ids) - converted to Map for compatibility
  Future<Map<String, dynamic>?> getPendingTips() async {
    try {
      if (_currentUserId == null) return null;
      final tips = await _localStorage.getCurrentPendingTips();
      if (tips == null) return null;
      return {
        'id': tips.id,
        'amount': tips.amount,
        'rideIds': tips.rideIds,
        'lastUpdated': tips.lastUpdated.millisecondsSinceEpoch,
      };
    } catch (e) {
      DebugLogger.logError('Error getting pending tips: $e');
      return null;
    }
  }

  // Stream for real-time pending tips - converted to Map for compatibility
  Stream<Map<String, dynamic>?> getPendingTipsStream() {
    try {
      return _localStorage.getPendingTipsStream().map((tips) {
        if (tips == null) return null;
        return {
          'id': tips.id,
          'amount': tips.amount,
          'rideIds': tips.rideIds,
          'lastUpdated': tips.lastUpdated.millisecondsSinceEpoch,
        };
      });
    } catch (e) {
      DebugLogger.logError('Error getting pending tips stream: $e');
      return Stream.value(null);
    }
  }

  // Transfer pending tips to Savings (expense) from a given account (Main Account)
  Future<bool> transferPendingTipsToSavings({
    required double amount,
    required String fromAccountId,
  }) async {
    try {
      if (_currentUserId == null) return false;
      if (amount <= 0) return false;

      // Fetch current pending tips
      final currentTips = await _localStorage.getCurrentPendingTips();
      final currentAmount = currentTips?.amount ?? 0.0;
      if (amount > currentAmount) return false;

      final timestamp = DateTime.now();
      final expenseId = _generateId('tips');

      // Ensure account exists
      await ensureAccountBalanceExists(fromAccountId);

      // 1) Create ledger expense (saving) and debit the fromAccountId
      await addTransaction(
        accountId: fromAccountId,
        rideId: '',
        type: TransactionType.debit,
        category: TransactionCategory.saving,
        nature: TransactionNature.expense,
        amount: amount,
        description: 'Pending tips saved',
        reference: 'pending_tips_transfer',
      );

      // 2) Decrement pending tips amount
      if (currentTips != null) {
        final newAmount = currentTips.amount - amount;
        if (newAmount <= 0.01) {
          await _localStorage.clearPendingTips();
        } else {
          final updated = PendingTips(
            id: currentTips.id,
            amount: newAmount,
            lastUpdated: timestamp,
            rideIds: currentTips.rideIds,
          );
          await _localStorage.savePendingTips(updated);
        }
      }

      DebugLogger.log('Transferred pending tips to savings: ₹$amount');
      return true;
    } catch (e) {
      DebugLogger.logError('Error transferring pending tips to savings: $e');
      return false;
    }
  }

  // Debug method to create test fuel allocation (remove in production)
  Future<bool> createTestFuelAllocation() async {
    try {
      if (_currentUserId == null) return false;
      
      final testAllocation = PendingFuelAllocation(
        id: 'current',
        amount: 250.0,
        lastUpdated: DateTime.now(),
        rideIds: ['test_ride_1', 'test_ride_2'],
      );
      await _localStorage.saveFuelAllocation(testAllocation);
      
      DebugLogger.log('Created test fuel allocation: ₹250.00');
      return true;
    } catch (e) {
      DebugLogger.logError('Error creating test fuel allocation: $e');
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
      final refuelId = _generateId('refuel');
      
      // 1. Add to refuels collection
      final refuel = Refuel(
        id: refuelId,
        cost: cost,
        kilometers: kilometers,
        timestamp: timestamp,
        location: location,
        notes: notes,
      );
      await _localStorage.saveRefuel(refuel);
      
      // 2. Add to ledger as expense
      final ledgerSuccess = await addTransaction(
        accountId: 'axis_bank', // Fuel Reserve account
        rideId: refuelId,
        amount: cost,
        type: TransactionType.debit,
        category: TransactionCategory.fuel,
        nature: TransactionNature.expense,
        description: 'Refuel - ${kilometers.toStringAsFixed(0)} km${location != null ? ' at $location' : ''}',
      );
      
      if (!ledgerSuccess) {
        // If ledger fails, delete the refuel record
        await _localStorage.deleteRefuel(refuelId);
        return false;
      }
      
      DebugLogger.log('Added refuel record: ₹$cost for ${kilometers.toStringAsFixed(0)} km');
      return true;
    } catch (e) {
      DebugLogger.logError('Error adding refuel record: $e');
      return false;
    }
  }

  // Get refuel records stream
  Stream<List<Refuel>> getRefuelsStream() {
    try {
      return _localStorage.getRefuelsStream();
    } catch (e) {
      DebugLogger.logError('Error getting refuels stream: $e');
      return Stream.value([]);
    }
  }

  // Get refuel records (one-time fetch)
  Future<List<Refuel>> getRefuels() async {
    try {
      if (_currentUserId == null) return [];
      return await _localStorage.getAllRefuels();
    } catch (e) {
      DebugLogger.logError('Error getting refuel records: $e');
      return [];
    }
  }

  // Delete refuel record (and corresponding ledger entry)
  Future<bool> deleteRefuel(String refuelId) async {
    try {
      if (_currentUserId == null) return false;
      
      // Get refuel data first
      final refuel = await _localStorage.getRefuel(refuelId);
      if (refuel == null) return false;
      
      // Delete refuel record
      await _localStorage.deleteRefuel(refuelId);
      
      // Note: We don't automatically delete ledger entries as they might be referenced elsewhere
      // User can manually adjust if needed
      
      DebugLogger.log('Deleted refuel record: ₹${refuel.cost} for ${refuel.kilometers.toStringAsFixed(0)} km');
      return true;
    } catch (e) {
      DebugLogger.logError('Error deleting refuel record: $e');
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
        DebugLogger.logError('AccountBalanceService: User not authenticated');
        return false;
      }

      return await addTransaction(
        accountId: accountId,
        rideId: '', // Empty for non-ride expenses
        type: TransactionType.debit,
        category: category,
        nature: TransactionNature.expense,
        amount: amount,
        description: description,
      );
    } catch (e) {
      DebugLogger.logError('Error recording expense: $e');
      return false;
    }
  }

  // Reverse all transactions related to a specific ride
  Future<bool> reverseRideTransactions(String rideId) async {
    try {
      if (_currentUserId == null) {
        DebugLogger.logError('AccountBalanceService: User not authenticated');
        return false;
      }

      DebugLogger.log('Reversing transactions for ride: $rideId');

      // Get all ledger entries for this ride
      final ledgerEntries = await _localStorage.getLedgerEntriesByRide(rideId);

      DebugLogger.log('Found ${ledgerEntries.length} ledger entries to reverse');

      // Process each ledger entry
      for (final ledgerEntry in ledgerEntries) {
        DebugLogger.log('Reversing entry: ${ledgerEntry.category.name} - ${ledgerEntry.type.name} - ₹${ledgerEntry.amount}');

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
        final currentBalance = await getAccountBalance(ledgerEntry.accountId);
        await updateAccountBalance(ledgerEntry.accountId, currentBalance + adjustmentAmount);

        DebugLogger.log('Reversed ${ledgerEntry.category.name}: ₹$adjustmentAmount for account ${ledgerEntry.accountId}');
      }

      // Delete all ledger entries for this ride
      for (final ledgerEntry in ledgerEntries) {
        await _localStorage.deleteLedgerEntry(ledgerEntry.id);
      }

      DebugLogger.logSuccess('Successfully reversed all transactions for ride: $rideId');
      return true;
    } catch (e) {
      DebugLogger.logError('Error reversing ride transactions: $e');
      return false;
    }
  }

  // Initialize all account balances for the current user
  Future<bool> initializeAllAccountBalances() async {
    try {
      if (_currentUserId == null) {
        DebugLogger.logError('AccountBalanceService: User not authenticated');
        return false;
      }

      DebugLogger.log('Initializing all account balances for user $_currentUserId');

      final accounts = Account.getSampleAccounts();

      for (final account in accounts) {
        // Check if account balance already exists
        final existing = await _localStorage.getAccountBalance(account.id);
        
        if (existing == null) {
          final accountBalance = AccountBalance(
            accountId: account.id,
            accountName: account.name,
            accountType: account.type,
            balance: 0.0,
            lastUpdated: DateTime.now(),
          );
          await _localStorage.saveAccountBalance(accountBalance);
          DebugLogger.log('Creating account balance for ${account.name}');
        }
      }

      DebugLogger.logSuccess('Initialized all account balances');
      return true;
    } catch (e) {
      DebugLogger.logError('Error initializing account balances: $e');
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/account.dart';
import '../models/ledger_entry.dart';
import '../services/account_balance_service.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final AccountBalanceService _accountService = AccountBalanceService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedAccountId;
  TransactionCategory? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  
  List<Account> _accounts = [];
  List<LedgerEntry> _expenseHistory = [];
  Map<String, double> _accountBalances = {};
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isRefreshing = false;

  // Expense categories with their icons
  final Map<TransactionCategory, IconData> _categoryIcons = {
    TransactionCategory.tollFee: Icons.toll,
    TransactionCategory.platformFee: Icons.account_balance,
    TransactionCategory.airportFee: Icons.flight,
    TransactionCategory.parkingFee: Icons.local_parking,
    TransactionCategory.fuel: Icons.local_gas_station,
    TransactionCategory.cigarettes: Icons.smoking_rooms,
    TransactionCategory.tea: Icons.local_cafe,
    TransactionCategory.water: Icons.water_drop,
    TransactionCategory.food: Icons.restaurant,
    TransactionCategory.goodies: Icons.card_giftcard,
    TransactionCategory.cleaning: Icons.cleaning_services,
    TransactionCategory.withdrawal: Icons.account_balance_wallet,
    TransactionCategory.saving: Icons.savings,
    TransactionCategory.rent: Icons.home,
    TransactionCategory.otherFee: Icons.more_horiz,
  };

  @override
  void initState() {
    super.initState();
    _accounts = Account.getSampleAccounts();
    _isLoading = true; // Set loading state initially
    // Load data asynchronously without waiting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    try {
      // Load in parallel for better performance
      await Future.wait([
        _loadAccountBalances(),
        _loadExpenseHistory(),
      ]);
      
      // Trigger a rebuild to show the data
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper function to get category display name
  String _getCategoryDisplayName(TransactionCategory category) {
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

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAccountBalances() async {
    try {
      final balances = <String, double>{};
      for (final account in _accounts) {
        final balance = await _accountService.getAccountBalance(account.id);
        balances[account.id] = balance;
      }
      
      _accountBalances = balances;
    } catch (e) {
      print('Error loading account balances: $e');
    }
  }

  Future<void> _loadExpenseHistory() async {
    try {
      final ledgerEntries = await _accountService.getAllLedgerEntries();
      final expenseEntries = ledgerEntries
          .where((entry) => entry.nature == TransactionNature.expense)
          .toList();
      
      // Sort by timestamp (newest first)
      expenseEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      _expenseHistory = expenseEntries;
    } catch (e) {
      print('Error loading expense history: $e');
      // Don't show snackbar here as it's handled by _loadInitialData()
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return; // Prevent multiple simultaneous refreshes
    
    if (mounted) {
      setState(() {
        _isRefreshing = true;
        _isLoading = true;
      });
    }
    
    await _loadInitialData();
    
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an account and category'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isSubmitting || _isRefreshing) return; // Prevent submission during operations

    setState(() {
      _isSubmitting = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text.trim();
      
      final success = await _accountService.recordExpense(
        accountId: _selectedAccountId!,
        category: _selectedCategory!,
        amount: amount,
        description: description.isEmpty ? _getCategoryDisplayName(_selectedCategory!) : description,
        timestamp: _selectedDate,
      );

      if (success) {
        // Clear form
        _amountController.clear();
        _descriptionController.clear();
        _selectedAccountId = null;
        _selectedCategory = null;
        _selectedDate = DateTime.now();
        
        // Reload expense history and account balances
        await _refreshData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense recorded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to record expense'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('expense_screen'),
      appBar: AppBar(
        title: const Text('Expense Management'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Add New Expense',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track your business expenses',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Expense Form
                  _buildExpenseForm(),
                  
                  const SizedBox(height: 32),
                  
                  // Expense History Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Expense History',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade800,
                        ),
                      ),
                      IconButton(
                        onPressed: _refreshData,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Expense History List
                  _buildExpenseHistory(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Selection
            Text(
              'Account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple.shade700,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: const ValueKey('account_dropdown'),
              value: _selectedAccountId,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              hint: const Text('Select Account'),
              items: _accounts.map((account) {
                final balance = _accountBalances[account.id];
                return DropdownMenuItem<String>(
                  key: ValueKey(account.id),
                  value: account.id,
                  child: Text(
                    balance != null 
                        ? '${account.name} - ₹${balance.toStringAsFixed(2)}'
                        : account.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAccountId = value;
                });
              },
              validator: (value) {
                if (value == null) return 'Please select an account';
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Category Selection
            Text(
              'Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple.shade700,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<TransactionCategory>(
              key: const ValueKey('category_dropdown'),
              value: _selectedCategory,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              hint: const Text('Select Category'),
              items: TransactionCategory.values
                  .where((category) => _categoryIcons.containsKey(category))
                  .map((category) {
                return DropdownMenuItem<TransactionCategory>(
                  key: ValueKey(category.name),
                  value: category,
                  child: Text(
                    _getCategoryDisplayName(category),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              validator: (value) {
                if (value == null) return 'Please select a category';
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Amount Input
            Text(
              'Amount',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple.shade700,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                prefixText: '₹ ',
                hintText: '0.00',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Description Input
            Text(
              'Description (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple.shade700,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                hintText: 'Add notes about this expense',
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 20),
            
            // Date Selection
            Text(
              'Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple.shade700,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Colors.deepPurple,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Record Expense',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseHistory() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_expenseHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No expenses recorded yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start recording your expenses to see them here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _expenseHistory.length,
      itemBuilder: (context, index) {
        final expense = _expenseHistory[index];
        final account = _accounts.firstWhere(
          (a) => a.id == expense.accountId,
          orElse: () => _accounts.first,
        );
        
        return Container(
          key: ValueKey(expense.id),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Category Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _categoryIcons[expense.category] ?? Icons.receipt,
                  color: Colors.deepPurple,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Expense Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getCategoryDisplayName(expense.category),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      account.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (expense.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        expense.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      expense.formattedTimestamp,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Amount
              Text(
                expense.formattedAmount,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

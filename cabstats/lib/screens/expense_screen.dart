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
  Map<String, double> _accountBalances = {};
  bool _isLoading = false;
  bool _isSubmitting = false;

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
    TransactionCategory.tireMaintenance: Icons.build_circle,
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
      await _loadAccountBalances();
      
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
      case TransactionCategory.tireMaintenance:
        return 'Tire Maintenance';
      case TransactionCategory.otherFee:
        return 'Miscellaneous';
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
      final accountIds = _accounts.map((account) => account.id).toList();
      _accountBalances = await _accountService.getMultipleAccountBalances(accountIds);
    } catch (e) {
      print('Error loading account balances: $e');
    }
  }

  Future<void> _refreshData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    await _loadInitialData();
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

    if (_isSubmitting) return; // Prevent submission during operations

    setState(() {
      _isSubmitting = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text.trim();
      
      // Check if account has sufficient balance
      final currentBalance = _accountBalances[_selectedAccountId!] ?? 0.0;
      if (currentBalance < amount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Insufficient balance. Available: ₹${currentBalance.toStringAsFixed(2)}, Required: ₹${amount.toStringAsFixed(2)}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      // Warn if balance will go negative
      final newBalance = currentBalance - amount;
      if (newBalance < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: This expense will result in a negative balance of ₹${newBalance.abs().toStringAsFixed(2)}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
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
        
        // Reload account balances
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
        title: const Text(
          'Add Expense',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
            color: Color(0xFF202124),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        elevation: 0,
        surfaceTintColor: const Color(0xFFE8EAED),
      ),
      body: Container(
        color: const Color(0xFFF8F9FA),
        child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Expense Form
                  _buildExpenseForm(),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
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
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: const ValueKey('account_dropdown'),
              value: _selectedAccountId,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFDADCE0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFDADCE0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF4285F4), width: 2),
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<TransactionCategory>(
              key: const ValueKey('category_dropdown'),
              value: _selectedCategory,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFDADCE0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFDADCE0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF4285F4), width: 2),
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFDADCE0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFDADCE0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF4285F4), width: 2),
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFDADCE0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFDADCE0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF4285F4), width: 2),
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                contentPadding: const EdgeInsets.all(16),
                hintText: 'Add notes about this expense',
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 20),
            
            // Date Selection
            Text(
              'Date',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
                letterSpacing: 0,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  border: Border.all(color: const Color(0xFFDADCE0)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF4285F4),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submitExpense,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

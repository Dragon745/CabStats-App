import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/account.dart';
import '../services/account_balance_service.dart';
import 'account_history_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final AccountBalanceService _accountService = AccountBalanceService();
  final List<Account> _accounts = Account.getSampleAccounts();
  Map<String, double> _balances = {};
  bool _isLoading = true;
  String? _error;

  // Form state
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _noteController = TextEditingController();
  
  String? _selectedFromAccount;
  String? _selectedToAccount;
  String? _selectedAdjustmentAccount;
  String _operationType = 'adjust';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedAdjustmentAccount = _accounts.first.id;
    _selectedFromAccount = _accounts.first.id;
    _loadBalances();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadBalances() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final balances = <String, double>{};
      for (final account in _accounts) {
        final balance = await _accountService.getAccountBalance(account.id);
        balances[account.id] = balance;
      }
      
      setState(() {
        _balances = balances;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  double get _totalBalance {
    return _balances.values.fold(0.0, (sum, balance) => sum + balance);
  }

  List<Account> get _availableToAccounts {
    return _accounts.where((account) => account.id != _selectedFromAccount).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: const Color(0xFF4285F4),
        title: const Text(
          'Accounts',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF202124),
            letterSpacing: 0.15,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF5F6368)),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountHistoryScreen()),
              );
            },
            icon: const Icon(Icons.history, color: Color(0xFF4285F4)),
            tooltip: 'Account History',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: const Color(0xFF4285F4),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Unable to load accounts',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loadBalances,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4285F4),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBalances,
      color: const Color(0xFF4285F4),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTotalBalance(),
                const SizedBox(height: 24),
                _buildSectionHeader('Your Accounts'),
                const SizedBox(height: 12),
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final account = _accounts[index];
                final balance = _balances[account.id] ?? 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
                  child: _buildAccountCard(account, balance),
                );
              },
              childCount: _accounts.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF5F6368),
          letterSpacing: 0.25,
        ),
      ),
    );
  }

  Widget _buildTotalBalance() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4285F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Balance',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${_totalBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        letterSpacing: -1,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _showOperationsBottomSheet(),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Adjust'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4285F4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    _operationType = 'transfer';
                    _showOperationsBottomSheet();
                  },
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Transfer'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4285F4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(Account account, double balance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AccountHistoryScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(int.parse(account.color)).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      account.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF202124),
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        account.type,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4285F4),
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOperationsBottomSheet() {
    // Reset form state when opening
    _selectedFromAccount = _accounts.first.id;
    _selectedToAccount = null;
    _selectedAdjustmentAccount = _accounts.first.id;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _operationType == 'adjust' ? 'Adjust Balance' : 'Transfer Funds',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF202124),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _operationType == 'adjust' ? _buildAdjustForm(setModalState) : _buildTransferForm(setModalState),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : () => _submitOperation(),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4285F4),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  _operationType == 'adjust' ? 'Apply Adjustment' : 'Transfer Money',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ).then((_) {
        _amountController.clear();
        _reasonController.clear();
        _noteController.clear();
      });
  }

  Widget _buildAdjustForm(Function setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdown('Account', _selectedAdjustmentAccount, _accounts, (value) => setModalState(() => _selectedAdjustmentAccount = value)),
        if (_selectedAdjustmentAccount != null) _buildBalanceInfo(_balances[_selectedAdjustmentAccount] ?? 0.0),
        const SizedBox(height: 24),
        _buildTextField(_amountController, 'Amount', 'Enter amount', keyboardType: TextInputType.number),
        const SizedBox(height: 24),
        _buildTextField(_reasonController, 'Reason', 'Enter reason for adjustment', maxLines: 2),
      ],
    );
  }

  Widget _buildTransferForm(Function setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdown('From', _selectedFromAccount, _accounts, (value) {
          setModalState(() {
            _selectedFromAccount = value;
            _selectedToAccount = null;
          });
        }),
        if (_selectedFromAccount != null) _buildBalanceInfo(_balances[_selectedFromAccount] ?? 0.0),
        const SizedBox(height: 24),
        _buildDropdown('To', _selectedToAccount, _availableToAccounts, (value) => setModalState(() => _selectedToAccount = value), key: ValueKey('to_dropdown_$_selectedFromAccount')),
        if (_selectedToAccount != null) ...[
          const SizedBox(height: 8),
          _buildBalanceInfo(_balances[_selectedToAccount] ?? 0.0),
        ],
        const SizedBox(height: 24),
        _buildTextField(_amountController, 'Amount', 'Enter amount', keyboardType: TextInputType.number),
        const SizedBox(height: 24),
        _buildTextField(_noteController, 'Note', 'Add a note', required: false),
      ],
    );
  }

  Widget _buildBalanceInfo(double balance) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F0FE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 18, color: Color(0xFF4285F4)),
            const SizedBox(width: 8),
            Text(
              'Balance: ₹${balance.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF4285F4), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<Account> items, ValueChanged<String?> onChanged, {Key? key}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      key: key,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF5F6368)),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: items.map((account) => DropdownMenuItem<String>(value: account.id, child: Text(account.name))).toList(),
          onChanged: onChanged,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select $label';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {int maxLines = 1, bool required = true, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF5F6368)),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
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
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Future<void> _submitOperation() async {
    if (!_formKey.currentState!.validate()) return;

    // Additional validation for transfer
    if (_operationType == 'transfer') {
      if (_selectedFromAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a source account'), backgroundColor: Colors.red),
        );
        return;
      }
      if (_selectedToAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a destination account'), backgroundColor: Colors.red),
        );
        return;
      }
      
      // Parse amount and validate
      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: Colors.red),
        );
        return;
      }
      // Note: Transfers are allowed even if balance goes negative
    }

    setState(() => _isSubmitting = true);

    try {
      bool success = false;
      if (_operationType == 'adjust') {
        success = await _accountService.adjustAccountBalance(
          accountId: _selectedAdjustmentAccount!,
          adjustmentAmount: double.parse(_amountController.text),
          reason: _reasonController.text.trim(),
        );
        if (success && mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Balance adjusted successfully'), backgroundColor: Colors.green),
          );
        }
      } else {
        // Call transferBetweenAccounts and handle exceptions
        try {
          success = await _accountService.transferBetweenAccounts(
            fromAccountId: _selectedFromAccount!,
            toAccountId: _selectedToAccount!,
            amount: double.parse(_amountController.text),
            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          );
          if (success && mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('₹${double.parse(_amountController.text).toStringAsFixed(2)} transferred successfully'),
                backgroundColor: Colors.green,
              ),
            );
            // Reload balances after successful transfer
            await _loadBalances();
          }
        } catch (e) {
          // Handle specific exceptions from transferBetweenAccounts
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceFirst('Exception: ', '')),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      }
      
      // Only reload balances for non-transfer operations here
      // (transfer already reloads in the try-catch above)
      if (_operationType != 'transfer') {
        await _loadBalances();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Operation failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

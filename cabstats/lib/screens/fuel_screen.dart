import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/account.dart';
import '../models/pending_fuel_allocation.dart';
import '../models/refuel.dart';
import '../services/account_balance_service.dart';
import '../services/location_service.dart';
import 'refuel_history_screen.dart';

class FuelScreen extends StatefulWidget {
  const FuelScreen({super.key});

  @override
  State<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends State<FuelScreen> {
  final AccountBalanceService _accountService = AccountBalanceService();
  final List<Account> _accounts = Account.getSampleAccounts();
  Map<String, double> _balances = {};
  bool _isLoading = true;
  String? _error;
  PendingFuelAllocation? _pendingFuelAllocation;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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
      
      // Load pending fuel allocation
      final fuelAllocation = await _accountService.getPendingFuelAllocation();
      
      setState(() {
        _balances = balances;
        _pendingFuelAllocation = fuelAllocation;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Management'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RefuelHistoryScreen(),
                ),
              );
            },
            tooltip: 'View Refuel History',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading)
                    _buildLoadingState()
                  else if (_error != null)
                    _buildErrorState()
                  else
                    _buildContent(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 200,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Error loading fuel data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fuel Reserve Account Card
        _buildFuelReserveCard(),
        
        const SizedBox(height: 24),
        
        // Pending Fuel Allocation Card
        if (_pendingFuelAllocation != null && _pendingFuelAllocation!.amount > 0)
          _buildPendingAllocationCard()
        else
          _buildNoAllocationCard(),
        
        const SizedBox(height: 24),
        
        // Quick Actions
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildFuelReserveCard() {
    final fuelReserveAccount = _accounts.firstWhere((a) => a.id == 'axis_bank');
    final balance = _balances['axis_bank'] ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade200,
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  fuelReserveAccount.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fuelReserveAccount.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      fuelReserveAccount.type,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '₹${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Current Fuel Reserve Balance',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingAllocationCard() {
    final allocation = _pendingFuelAllocation!;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade200,
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_gas_station,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Pending Fuel Allocation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₹${allocation.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'From ${allocation.rideIds.length} ride${allocation.rideIds.length > 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready to transfer to Fuel Reserve',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAllocationCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.local_gas_station_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'No Pending Fuel Allocation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Complete rides to accumulate fuel allocation',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.swap_horiz,
                title: 'Transfer Fuel',
                subtitle: 'Move allocation to Fuel Reserve',
                color: Colors.orange,
                onTap: _pendingFuelAllocation != null && _pendingFuelAllocation!.amount > 0
                    ? _showFuelTransferDialog
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.tune,
                title: 'Adjust',
                subtitle: 'Modify allocation amount',
                color: Colors.blue,
                onTap: _pendingFuelAllocation != null && _pendingFuelAllocation!.amount > 0
                    ? _showAdjustmentDialog
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.clear_all,
                title: 'Clear All',
                subtitle: 'Remove all allocation',
                color: Colors.red,
                onTap: _pendingFuelAllocation != null && _pendingFuelAllocation!.amount > 0
                    ? _showClearDialog
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.local_gas_station,
                title: 'Refuel',
                subtitle: 'Record fuel purchase',
                color: Colors.green,
                onTap: _showRefuelDialog,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEnabled ? color.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled ? color.withOpacity(0.3) : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isEnabled ? color : Colors.grey.shade400,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isEnabled ? color : Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isEnabled ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showFuelTransferDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FuelTransferScreen(
          accounts: _accounts,
          balances: _balances,
          pendingAllocation: _pendingFuelAllocation!,
          onTransferComplete: _loadData,
        ),
      ),
    );
  }

  void _showAdjustmentDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FuelAdjustmentScreen(
          pendingAllocation: _pendingFuelAllocation!,
          onAdjustmentComplete: _loadData,
        ),
      ),
    );
  }

  void _showRefuelDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RefuelScreen(
          onRefuelComplete: _loadData,
        ),
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Fuel Allocation'),
        content: const Text('Are you sure you want to clear the entire fuel allocation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllocation();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllocation() async {
    try {
      final success = await _accountService.clearPendingFuelAllocation();
      
      if (success) {
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fuel allocation cleared'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to clear allocation'),
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
    }
  }

  Future<void> _createTestFuelAllocation() async {
    try {
      final success = await _accountService.createTestFuelAllocation();
      if (success) {
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test fuel allocation created!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create test fuel allocation'),
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
    }
  }
}

// Fuel Transfer Screen (moved from accounts_screen.dart)
class FuelTransferScreen extends StatefulWidget {
  final List<Account> accounts;
  final Map<String, double> balances;
  final PendingFuelAllocation pendingAllocation;
  final VoidCallback onTransferComplete;

  const FuelTransferScreen({
    super.key,
    required this.accounts,
    required this.balances,
    required this.pendingAllocation,
    required this.onTransferComplete,
  });

  @override
  State<FuelTransferScreen> createState() => _FuelTransferScreenState();
}

class _FuelTransferScreenState extends State<FuelTransferScreen> {
  final AccountBalanceService _accountService = AccountBalanceService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String? _selectedFromAccount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedFromAccount = 'federal_bank'; // Default to Main Account
    _amountController.text = widget.pendingAllocation.amount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _fromAccountBalance {
    return widget.balances[_selectedFromAccount ?? ''] ?? 0.0;
  }

  Future<void> _performTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    if (_fromAccountBalance < amount) {
      _showError('Insufficient balance in selected account');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _accountService.transferFuelAllocation(
        fromAccountId: _selectedFromAccount!,
        amount: amount,
      );

      if (success) {
        widget.onTransferComplete();
        Navigator.pop(context);
        _showSuccess('₹${amount.toStringAsFixed(2)} transferred to Fuel Reserve');
      } else {
        _showError('Transfer failed. Please try again.');
      }
    } catch (e) {
      _showError('Transfer failed. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fuelReserveAccount = widget.accounts.firstWhere((a) => a.id == 'axis_bank');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Fuel Allocation'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pending Allocation Display
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade400, Colors.orange.shade600],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pending Fuel Allocation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${widget.pendingAllocation.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'From ${widget.pendingAllocation.rideIds.length} ride${widget.pendingAllocation.rideIds.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // Transfer Section
                  const Text(
                    'Transfer to Fuel Reserve',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Destination Account (Read-only)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Text(fuelReserveAccount.icon, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'To: ${fuelReserveAccount.name}',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                fuelReserveAccount.type,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // From Account
                  const Text('From Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedFromAccount,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: widget.accounts.where((a) => a.id != 'axis_bank').map((account) {
                      return DropdownMenuItem<String>(
                        value: account.id,
                        child: Tooltip(
                          message: '${account.name} (${account.type})',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(account.icon),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  account.name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedFromAccount = value),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Available: ₹${_fromAccountBalance.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 16),

                  // Amount
                  const Text('Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      hintText: 'Enter amount',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter amount';
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) return 'Please enter a valid amount';
                      if (amount > _fromAccountBalance) return 'Amount exceeds available balance';
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Transfer Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _performTransfer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Transfer to Fuel Reserve', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Fuel Adjustment Screen
class FuelAdjustmentScreen extends StatefulWidget {
  final PendingFuelAllocation pendingAllocation;
  final VoidCallback onAdjustmentComplete;

  const FuelAdjustmentScreen({
    super.key,
    required this.pendingAllocation,
    required this.onAdjustmentComplete,
  });

  @override
  State<FuelAdjustmentScreen> createState() => _FuelAdjustmentScreenState();
}

class _FuelAdjustmentScreenState extends State<FuelAdjustmentScreen> {
  final AccountBalanceService _accountService = AccountBalanceService();
  final _adjustmentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _adjustmentController.dispose();
    super.dispose();
  }

  Future<void> _adjustAllocation() async {
    final adjustmentText = _adjustmentController.text.trim();
    if (adjustmentText.isEmpty) {
      _showError('Please enter an adjustment amount');
      return;
    }

    final adjustment = double.tryParse(adjustmentText);
    if (adjustment == null || adjustment == 0) {
      _showError('Please enter a valid adjustment amount');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _accountService.adjustPendingFuelAllocation(adjustment);
      
      if (success) {
        widget.onAdjustmentComplete();
        Navigator.pop(context);
        _showSuccess('Fuel allocation adjusted by ₹${adjustment.toStringAsFixed(2)}');
      } else {
        _showError('Adjustment failed. Please try again.');
      }
    } catch (e) {
      _showError('Adjustment failed. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adjust Fuel Allocation'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Allocation Display
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Fuel Allocation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${widget.pendingAllocation.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'From ${widget.pendingAllocation.rideIds.length} ride${widget.pendingAllocation.rideIds.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                // Adjustment Section
                const Text(
                  'Adjust Allocation',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Increase or decrease the pending allocation amount',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _adjustmentController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    hintText: 'Enter adjustment (+100 or -100)',
                    helperText: 'Use + for increase, - for decrease',
                  ),
                ),

                const SizedBox(height: 24),

                // Adjust Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _adjustAllocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Adjust Allocation', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Refuel Screen
class RefuelScreen extends StatefulWidget {
  final VoidCallback onRefuelComplete;

  const RefuelScreen({
    super.key,
    required this.onRefuelComplete,
  });

  @override
  State<RefuelScreen> createState() => _RefuelScreenState();
}

class _RefuelScreenState extends State<RefuelScreen> {
  final AccountBalanceService _accountService = AccountBalanceService();
  final LocationService _locationService = LocationService();
  final _formKey = GlobalKey<FormState>();
  final _kmController = TextEditingController();
  final _amountController = TextEditingController();
  final _locationController = TextEditingController();
  
  bool _isLoading = false;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _kmController.dispose();
    _amountController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    
    try {
      final location = await _locationService.getCurrentLocality();
      if (location != null) {
        _locationController.text = location;
      }
    } catch (e) {
      // Location will remain empty if failed
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _recordRefuel() async {
    if (!_formKey.currentState!.validate()) return;

    final km = double.tryParse(_kmController.text);
    final amount = double.tryParse(_amountController.text);
    
    if (km == null || km <= 0) {
      _showError('Please enter a valid kilometer reading');
      return;
    }
    
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Add refuel record to both refuels collection and ledger
      final success = await _accountService.addRefuel(
        cost: amount,
        kilometers: km,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      );

      if (success) {
        widget.onRefuelComplete();
        Navigator.pop(context);
        _showSuccess('Refuel recorded: ₹${amount.toStringAsFixed(2)} for ${km.toStringAsFixed(0)} km');
      } else {
        _showError('Failed to record refuel. Please try again.');
      }
    } catch (e) {
      _showError('Failed to record refuel: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Refuel'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.local_gas_station,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Record Fuel Purchase',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Track your fuel expenses and mileage for better statistics',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Kilometer Reading
                  const Text(
                    'Kilometer Reading',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _kmController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      suffixText: 'km',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      hintText: 'Enter current odometer reading',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter kilometer reading';
                      final km = double.tryParse(value);
                      if (km == null || km <= 0) return 'Please enter a valid kilometer reading';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Amount
                  const Text(
                    'Fuel Amount',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      hintText: 'Enter fuel amount',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter amount';
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) return 'Please enter a valid amount';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Location
                  const Text(
                    'Location',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            hintText: 'Enter refuel location',
                            suffixIcon: _isGettingLocation
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.my_location),
                                    onPressed: _getCurrentLocation,
                                    tooltip: 'Get current location',
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Record Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _recordRefuel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Record Refuel', style: TextStyle(fontSize: 16)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade600),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This will be recorded as a fuel expense in your ledger and deducted from your Fuel Reserve balance.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

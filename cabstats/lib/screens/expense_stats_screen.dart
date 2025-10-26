import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/ledger_entry.dart';
import '../services/account_balance_service.dart';
import 'expense_screen.dart';

class ExpenseStatsScreen extends StatefulWidget {
  const ExpenseStatsScreen({super.key});

  @override
  State<ExpenseStatsScreen> createState() => _ExpenseStatsScreenState();
}

class _ExpenseStatsScreenState extends State<ExpenseStatsScreen> {
  final AccountBalanceService _accountService = AccountBalanceService();
  
  List<LedgerEntry> _expenses = [];
  List<Account> _accounts = [];
  Map<String, double> _accountBalances = {};
  bool _isLoading = true;
  String _selectedPeriod = 'Week';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  
  // Filter states
  String? _selectedAccountId;
  
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
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.wait([
        _loadExpenses(),
        _loadAccountBalances(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadExpenses() async {
    try {
      final ledgerEntries = await _accountService.getAllLedgerEntries(limit: 500);
      final expenseEntries = ledgerEntries
          .where((entry) => entry.nature == TransactionNature.expense)
          .where((entry) {
            final entryDate = entry.timestamp;
            return entryDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
                   entryDate.isBefore(_endDate.add(const Duration(days: 1)));
          })
          .toList();
      
      // Apply filters
      var filtered = expenseEntries;
      
      if (_selectedAccountId != null) {
        filtered = filtered.where((e) => e.accountId == _selectedAccountId).toList();
      }
      
      filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      _expenses = filtered;
    } catch (e) {
      print('Error loading expenses: $e');
    }
  }

  Future<void> _loadAccountBalances() async {
    try {
      final accountIds = _accounts.map((account) => account.id).toList();
      _accountBalances = await _accountService.getMultipleAccountBalances(accountIds);
    } catch (e) {
      print('Error loading account balances: $e');
    }
  }

  // Helper to get category display name
  String _getCategoryDisplayName(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.tollFee: return 'Toll Fee';
      case TransactionCategory.platformFee: return 'Platform Fee';
      case TransactionCategory.airportFee: return 'Airport Fee';
      case TransactionCategory.parkingFee: return 'Parking Fee';
      case TransactionCategory.fuel: return 'Fuel';
      case TransactionCategory.cigarettes: return 'Cigarettes';
      case TransactionCategory.tea: return 'Tea';
      case TransactionCategory.water: return 'Water';
      case TransactionCategory.food: return 'Food';
      case TransactionCategory.goodies: return 'Goodies';
      case TransactionCategory.cleaning: return 'Cleaning';
      case TransactionCategory.withdrawal: return 'Withdrawal';
      case TransactionCategory.saving: return 'Saving';
      case TransactionCategory.rent: return 'Rent';
      case TransactionCategory.tireMaintenance: return 'Tire Maintenance';
      case TransactionCategory.otherFee: return 'Miscellaneous';
      default: return 'Unknown';
    }
  }

  // Calculate total expenses
  double _getTotalExpenses() {
    return _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Get expense count
  int _getExpenseCount() {
    return _expenses.length;
  }

  // Get average expense
  double _getAverageExpense() {
    if (_expenses.isEmpty) return 0.0;
    return _getTotalExpenses() / _expenses.length;
  }

  // Get top category
  Map<TransactionCategory, double> _getCategoryBreakdown() {
    final breakdown = <TransactionCategory, double>{};
    for (final expense in _expenses) {
      breakdown[expense.category] = (breakdown[expense.category] ?? 0) + expense.amount;
    }
    return breakdown;
  }

  TransactionCategory? _getTopCategory() {
    final breakdown = _getCategoryBreakdown();
    if (breakdown.isEmpty) return null;
    
    return breakdown.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  void _selectPeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      final now = DateTime.now();
      
      switch (period) {
        case 'Today':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = now;
          break;
        case 'Week':
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
          break;
        case 'Month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
      }
    });
    _loadData();
  }

  Future<void> _selectCustomDateRange() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    
    if (dateRange != null) {
      setState(() {
        _selectedPeriod = 'Custom';
        _startDate = dateRange.start;
        _endDate = dateRange.end;
      });
      _loadData();
    }
  }

  Account? _getAccountById(String accountId) {
    return _accounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () => _accounts.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalExpenses = _getTotalExpenses();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Expense Stats',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF4285F4)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExpenseScreen()),
              );
            },
            tooltip: 'Add Expense',
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF8F9FA),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Period Filter (Top)
                        _buildPeriodFilter(),
                        
                        const SizedBox(height: 16),
                        
                        // Total Expense Card with Pie Chart
                        _buildTotalExpenseCard(totalExpenses),
                        
                        const SizedBox(height: 16),
                        
                        // Expense List
                        _buildExpenseList(),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalExpenseCard(double totalExpenses) {
    final categoryBreakdown = _getCategoryBreakdown();
    final breakdownList = categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4285F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Expenses',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${totalExpenses.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          if (breakdownList.isNotEmpty) ...[
            const SizedBox(height: 20),
            Column(
              children: breakdownList.map((entry) {
                final percentage = (entry.value / totalExpenses * 100);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category name and percentage
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getCategoryDisplayName(entry.key),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '₹${entry.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(0)}%)',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Row(
        children: [
          // Date Display with Arrows
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                  color: const Color(0xFF5F6368),
                  onPressed: _canNavigatePrev() ? () => _navigatePrevious() : null,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectedPeriod == 'Custom' ? _selectCustomDateRange : null,
                    child: Text(
                      _getPeriodDisplay(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF202124),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                  color: const Color(0xFF5F6368),
                  onPressed: _canNavigateNext() ? () => _navigateNext() : null,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Period Dropdown
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFDADCE0)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: _selectedPeriod,
              underline: const SizedBox(),
              isDense: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              items: const [
                DropdownMenuItem(value: 'Today', child: Text('Today')),
                DropdownMenuItem(value: 'Week', child: Text('Week')),
                DropdownMenuItem(value: 'Month', child: Text('Month')),
                DropdownMenuItem(value: 'Custom', child: Text('Custom')),
              ],
              onChanged: (String? value) {
                if (value == 'Custom') {
                  _selectCustomDateRange();
                } else if (value != null) {
                  _selectPeriod(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getPeriodDisplay() {
    switch (_selectedPeriod) {
      case 'Today':
        return '${_startDate.day} ${_getMonthName(_startDate.month)}, ${_startDate.year}';
      case 'Week':
        return '${_startDate.day}-${_endDate.day} ${_getMonthName(_startDate.month)}';
      case 'Month':
        return '${_getMonthName(_startDate.month)} ${_startDate.year}';
      case 'Custom':
        return '${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}';
      default:
        return '';
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  bool _canNavigatePrev() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Today':
        return _startDate.isBefore(now);
      case 'Week':
        return _startDate.isBefore(now);
      case 'Month':
        return _startDate.isBefore(now);
      case 'Custom':
        return true;
      default:
        return false;
    }
  }

  bool _canNavigateNext() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Today':
        return _startDate.add(const Duration(days: 1)).isBefore(now) || _startDate.add(const Duration(days: 1)).isAtSameMomentAs(now);
      case 'Week':
        return _endDate.add(const Duration(days: 1)).isBefore(now) || _endDate.add(const Duration(days: 1)).isAtSameMomentAs(now);
      case 'Month':
        final nextMonth = DateTime(_startDate.year, _startDate.month + 1, 1);
        return nextMonth.isBefore(now) || nextMonth.isAtSameMomentAs(now);
      case 'Custom':
        return false;
      default:
        return false;
    }
  }

  void _navigatePrevious() {
    setState(() {
      switch (_selectedPeriod) {
        case 'Today':
          _startDate = _startDate.subtract(const Duration(days: 1));
          _endDate = _startDate;
          break;
        case 'Week':
          _startDate = _startDate.subtract(const Duration(days: 7));
          _endDate = _startDate.add(const Duration(days: 6));
          break;
        case 'Month':
          _startDate = DateTime(_startDate.year, _startDate.month - 1, 1);
          _endDate = DateTime(_startDate.year, _startDate.month + 1, 0);
          break;
      }
    });
    _loadData();
  }

  void _navigateNext() {
    setState(() {
      switch (_selectedPeriod) {
        case 'Today':
          _startDate = _startDate.add(const Duration(days: 1));
          _endDate = _startDate;
          break;
        case 'Week':
          _startDate = _startDate.add(const Duration(days: 7));
          _endDate = _startDate.add(const Duration(days: 6));
          break;
        case 'Month':
          _startDate = DateTime(_startDate.year, _startDate.month + 1, 1);
          _endDate = DateTime(_startDate.year, _startDate.month + 1, 0);
          break;
      }
    });
    _loadData();
  }

  Widget _buildExpenseList() {
    if (_expenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EAED)),
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
              'No expenses found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Expenses',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          _expenses.length,
          (index) => _buildExpenseCard(_expenses[index], index),
        ),
      ],
    );
  }

  Widget _buildExpenseCard(LedgerEntry expense, int index) {
    final account = _getAccountById(expense.accountId);
    final categoryIcon = _categoryIcons[expense.category] ?? Icons.receipt;

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.red, size: 28),
      ),
      confirmDismiss: (direction) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Expense?'),
            content: Text(
              'This will reverse the balance change of ₹${expense.amount.toStringAsFixed(2)} to ${account?.name ?? 'this account'}. Are you sure you want to delete this expense?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        
        if (confirmed == true) {
          await _deleteExpense(expense);
        }
        return false;
      },
      child: Container(
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
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      categoryIcon,
                      color: const Color(0xFFEF4444),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getCategoryDisplayName(expense.category),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF202124),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          account?.name ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (expense.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
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
                  Text(
                    expense.formattedAmount,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
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

  Future<void> _deleteExpense(LedgerEntry expense) async {
    try {
      // Delete the transaction and reverse balance
      final success = await _accountService.deleteTransaction(
        transactionId: expense.id,
        transactionType: 'ledger',
      );

      if (success) {
        // Refresh the data
        await _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete expense'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}


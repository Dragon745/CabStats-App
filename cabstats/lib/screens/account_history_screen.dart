import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/account_balance_service.dart';

class AccountHistoryScreen extends StatefulWidget {
  const AccountHistoryScreen({super.key});

  @override
  State<AccountHistoryScreen> createState() => _AccountHistoryScreenState();
}

class _AccountHistoryScreenState extends State<AccountHistoryScreen> {
  final AccountBalanceService _accountService = AccountBalanceService();
  final List<Account> _accounts = Account.getSampleAccounts();
  
  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  
  String _selectedPeriod = 'month';
  DateTime _selectedDate = DateTime.now();
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String _selectedType = 'all';
  
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await _accountService.getAllAccountTransactions();
      setState(() {
        _allTransactions = transactions;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transactions: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _applyFilters() {
    _filteredTransactions = _allTransactions.where((transaction) {
      final transactionDate = DateTime.fromMillisecondsSinceEpoch(transaction['timestamp'] as int);
      if (!_isDateInRange(transactionDate)) return false;
      
      if (_selectedType == 'all') return true;
      if (_selectedType == 'expenditure' && transaction['type'] == 'ledger' && transaction['nature'] == 'expense') return true;
      if (_selectedType == 'earnings' && transaction['nature'] == 'earning') return true;
      if (_selectedType == 'rides' && transaction['rideId'] != null && transaction['rideId'].toString().isNotEmpty) return true;
      if (_selectedType == 'transfers' && transaction['type'] == 'transfer') return true;
      if (_selectedType == 'fuel' && transaction['category'] == 'fuel') return true;
      if (_selectedType == 'fees' && ['tollFee', 'platformFee', 'airportFee', 'parkingFee'].contains(transaction['category'])) return true;
      if (_selectedType == 'adjustments' && transaction['category'] == 'adjustment') return true;
      
      return false;
    }).toList();
  }

  bool _isDateInRange(DateTime date) {
    switch (_selectedPeriod) {
      case 'day':
        return date.year == _selectedDate.year && date.month == _selectedDate.month && date.day == _selectedDate.day;
      case 'week':
        final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return date.isAfter(weekStart.subtract(const Duration(days: 1))) && date.isBefore(weekEnd.add(const Duration(days: 1)));
      case 'month':
        return date.year == _selectedDate.year && date.month == _selectedDate.month;
      case 'custom':
        if (_customStartDate == null || _customEndDate == null) return false;
        return date.isAfter(_customStartDate!.subtract(const Duration(seconds: 1))) && date.isBefore(_customEndDate!.add(const Duration(days: 1)));
      default:
        return true;
    }
  }

  String _getPeriodDisplay() {
    switch (_selectedPeriod) {
      case 'day':
        return '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
      case 'week':
        final start = _getPeriodStart();
        final end = _getPeriodEnd();
        return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
      case 'month':
        return '${_selectedDate.month}/${_selectedDate.year}';
      case 'custom':
        if (_customStartDate != null && _customEndDate != null) {
          return '${_customStartDate!.day}/${_customStartDate!.month}/${_customStartDate!.year} - ${_customEndDate!.day}/${_customEndDate!.month}/${_customEndDate!.year}';
        }
        return 'Select Date Range';
      default:
        return '';
    }
  }

  DateTime _getPeriodStart() {
    switch (_selectedPeriod) {
      case 'day': return DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      case 'week': return _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      case 'month': return DateTime(_selectedDate.year, _selectedDate.month, 1);
      default: return DateTime.now();
    }
  }

  DateTime _getPeriodEnd() {
    switch (_selectedPeriod) {
      case 'day': return DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);
      case 'week': return _selectedDate.subtract(Duration(days: _selectedDate.weekday - 7)).add(const Duration(hours: 23, minutes: 59, seconds: 59));
      case 'month': return DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);
      default: return DateTime.now();
    }
  }

  void _navigatePeriod(int direction) {
    setState(() {
      switch (_selectedPeriod) {
        case 'day': _selectedDate = _selectedDate.add(Duration(days: direction)); break;
        case 'week': _selectedDate = _selectedDate.add(Duration(days: direction * 7)); break;
        case 'month': _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + direction, 1); break;
      }
      _applyFilters();
    });
  }

  Future<void> _showCustomDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null ? DateTimeRange(start: _customStartDate!, end: _customEndDate!) : null,
    );
    
    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _applyFilters();
      });
    }
  }

  Future<void> _deleteTransaction(Map<String, dynamic> transaction) async {
    setState(() => _isDeleting = true);

    try {
      final success = await _accountService.deleteTransaction(
        transactionId: transaction['id'] as String,
        transactionType: transaction['transactionType'] as String,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted successfully'), backgroundColor: Colors.green),
        );
        await _loadTransactions();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete transaction'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isDeleting = false);
    }
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
          'Account History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF202124),
            letterSpacing: 0.15,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF5F6368)),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF5F6368)),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20, color: Colors.grey.shade700),
                    const SizedBox(width: 12),
                    const Text('Export Data'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading || _isDeleting ? _buildLoadingState() : _buildBody(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: 3,
        color: const Color(0xFF4285F4),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildFilters(),
        Expanded(child: _buildTransactionList()),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Period', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF5F6368), letterSpacing: 0.15)),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'day', label: Text('Day'), icon: Icon(Icons.today, size: 18)),
              ButtonSegment(value: 'week', label: Text('Week'), icon: Icon(Icons.calendar_view_week, size: 18)),
              ButtonSegment(value: 'month', label: Text('Month'), icon: Icon(Icons.calendar_view_month, size: 18)),
              ButtonSegment(value: 'custom', label: Text('Custom'), icon: Icon(Icons.date_range, size: 18)),
            ],
            selected: {_selectedPeriod},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _selectedPeriod = newSelection.first;
                if (_selectedPeriod == 'custom' && _customStartDate == null) {
                  _showCustomDatePicker();
                }
                _applyFilters();
              });
            },
            style: SegmentedButton.styleFrom(
              backgroundColor: const Color(0xFFF8F9FA),
              selectedBackgroundColor: const Color(0xFF4285F4),
              selectedForegroundColor: Colors.white,
              foregroundColor: const Color(0xFF4285F4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          
          if (_selectedPeriod != 'custom') ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _navigatePeriod(-1),
                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                ),
                Expanded(
                  child: Text(
                    _getPeriodDisplay(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF202124)),
                  ),
                ),
                IconButton(
                  onPressed: DateTime.now().difference(_selectedDate).inDays >= 0 ? () => _navigatePeriod(1) : null,
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: _showCustomDatePicker,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDADCE0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_getPeriodDisplay(), style: const TextStyle(fontSize: 14, color: Color(0xFF202124))),
                    const Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFF5F6368)),
                  ],
                ),
              ),
            ),
            if (_customStartDate != null && _customEndDate != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _customStartDate = null;
                    _customEndDate = null;
                    _applyFilters();
                  });
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear'),
              ),
            ],
          ],
          
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE8EAED)),
          const SizedBox(height: 16),
          
          const Text('Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF5F6368), letterSpacing: 0.15)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All', Icons.list),
                const SizedBox(width: 8),
                _buildFilterChip('expenditure', 'Expenses', Icons.trending_down),
                const SizedBox(width: 8),
                _buildFilterChip('earnings', 'Earnings', Icons.trending_up),
                const SizedBox(width: 8),
                _buildFilterChip('rides', 'Rides', Icons.directions_car),
                const SizedBox(width: 8),
                _buildFilterChip('transfers', 'Transfers', Icons.swap_horiz),
                const SizedBox(width: 8),
                _buildFilterChip('fuel', 'Fuel', Icons.local_gas_station),
                const SizedBox(width: 8),
                _buildFilterChip('fees', 'Fees', Icons.receipt),
                const SizedBox(width: 8),
                _buildFilterChip('adjustments', 'Adjust', Icons.tune),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isSelected ? const Color(0xFF4285F4) : const Color(0xFF5F6368)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500)),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedType = type;
            _applyFilters();
          });
        }
      },
      selectedColor: const Color(0xFFE8F0FE),
      checkmarkColor: const Color(0xFF4285F4),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF4285F4) : const Color(0xFF5F6368),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF4285F4) : const Color(0xFFDADCE0),
        width: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildTransactionList() {
    if (_filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No transactions found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF5F6368)),
            ),
            const SizedBox(height: 8),
            Text('Try adjusting your filters', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedPeriod = 'month';
                  _selectedType = 'all';
                  _customStartDate = null;
                  _customEndDate = null;
                  _applyFilters();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Clear Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4285F4),
                side: const BorderSide(color: Color(0xFF4285F4)),
              ),
            ),
          ],
        ),
      );
    }

    final groupedTransactions = <String, List<Map<String, dynamic>>>{};
    for (final transaction in _filteredTransactions) {
      final date = DateTime.fromMillisecondsSinceEpoch(transaction['timestamp'] as int);
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      groupedTransactions.putIfAbsent(dateKey, () => []).add(transaction);
    }

    final sortedDates = groupedTransactions.keys.toList()..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      color: const Color(0xFF4285F4),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final dateKey = sortedDates[index];
          final transactions = groupedTransactions[dateKey]!;
          final date = DateTime.parse('$dateKey 00:00:00');
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  _formatDateHeader(date),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5F6368),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              ...transactions.map((transaction) => _buildTransactionCard(transaction)),
              if (index < sortedDates.length - 1) const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day} ${_getMonthName(date.month)}, ${date.year}';
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final isCredit = transaction['transactionType'] == 'ledger' && transaction['type'] == 'credit';
    final icon = _getTransactionIcon(transaction);
    final color = _getTransactionColor(transaction);
    final account = _accounts.firstWhere((a) => a.id == transaction['accountId'], orElse: () => _accounts.first);

    return Dismissible(
      key: Key(transaction['id'] as String),
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
            title: const Text('Delete Transaction?'),
            content: const Text('This will reverse the balance changes. Are you sure you want to delete this transaction?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        
        if (confirmed == true) {
          _deleteTransaction(transaction);
          return false;
        }
        return false;
      },
      onDismissed: (direction) {},
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
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction['description'] ?? 'Transaction',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF202124)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          account.name,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isCredit ? "+" : "-"}₹${(transaction['amount'] as num).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(DateTime.fromMillisecondsSinceEpoch(transaction['timestamp'] as int)),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTransactionIcon(Map<String, dynamic> transaction) {
    if (transaction['transactionType'] == 'transfer') return Icons.swap_horiz;
    if (transaction['category'] == 'fuel') return Icons.local_gas_station;
    if (transaction['category'] == 'food') return Icons.restaurant;
    if (transaction['category'] == 'tollFee') return Icons.toll;
    if (transaction['category'] == 'parkingFee') return Icons.local_parking;
    if (transaction['category'] == 'paymentReceived') return Icons.payment;
    if (transaction['category'] == 'adjustment') return Icons.tune;
    return Icons.receipt;
  }

  Color _getTransactionColor(Map<String, dynamic> transaction) {
    if (transaction['transactionType'] == 'transfer') return const Color(0xFF4285F4);
    if (transaction['category'] == 'fuel') return Colors.orange;
    if (transaction['nature'] == 'earning') return Colors.green;
    if (transaction['nature'] == 'expense') return Colors.red;
    return const Color(0xFF5F6368);
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

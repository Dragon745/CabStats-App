import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ride.dart';
import '../services/ride_service.dart';
import '../services/account_balance_service.dart';
import 'edit_ride_screen.dart';

class RidesHistoryScreen extends StatefulWidget {
  const RidesHistoryScreen({super.key});

  @override
  State<RidesHistoryScreen> createState() => _RidesHistoryScreenState();
}

class _RidesHistoryScreenState extends State<RidesHistoryScreen> {
  final RideService _rideService = RideService();
  final AccountBalanceService _accountService = AccountBalanceService();
  
  List<Ride> _rides = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _searchQuery = '';
  
  // Filter states
  RideStatus? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortBy = 'date'; // date, profit, duration
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Loading rides history...');
      
      // Debug: Get raw data first
      final rawRides = await _rideService.getAllRidesRaw();
      print('📊 Raw rides data: ${rawRides.length}');
      
      // Try to load all rides first to see what we have
      final allRides = await _rideService.getRideHistory(limit: 100);
      print('📊 Total rides found: ${allRides.length}');
      
      for (final ride in allRides) {
        print('🚗 Ride: ${ride.id} - Status: ${ride.status.name} - Start: ${ride.startLocality}');
      }
      
      final results = await Future.wait([
        _rideService.getCompletedRides(limit: 50),
        _rideService.getComprehensiveStatistics(),
      ]);

      final completedRides = results[0] as List<Ride>;
      print('✅ Completed rides loaded: ${completedRides.length}');

      setState(() {
        _rides = completedRides;
        _statistics = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading rides: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading rides: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Edit ride functionality
  void _editRide(Ride ride) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRideScreen(ride: ride),
      ),
    );

    // If ride was updated successfully, refresh the data
    if (result == true) {
      await _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Delete ride with confirmation
  void _confirmDeleteRide(Ride ride) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Ride'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete this ride?'),
              const SizedBox(height: 8),
              Text('Ride Details:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• KM: ${ride.km.toStringAsFixed(1)}'),
              Text('• Fare: ₹${ride.fare.toStringAsFixed(2)}'),
              Text('• Profit: ₹${ride.calculateProfit().toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will reverse all transactions related to this ride',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteRide(ride);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Delete ride implementation
  Future<void> _deleteRide(Ride ride) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Deleting ride...'),
              ],
            ),
          );
        },
      );

      // Delete ride with transaction reversal
      final success = await _rideService.deleteRideWithTransactionReversal(ride.id);

      // Hide loading indicator
      Navigator.of(context).pop();

      if (success) {
        // Refresh the data
        await _refreshData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ride deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete ride'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator if still showing
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting ride: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      await _loadInitialData();
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  List<Ride> _getFilteredRides() {
    List<Ride> filtered = List.from(_rides);

    // Filter by status
    if (_selectedStatus != null) {
      filtered = filtered.where((ride) => ride.status == _selectedStatus).toList();
    }

    // Filter by date range
    if (_startDate != null && _endDate != null) {
      filtered = filtered.where((ride) {
        return ride.startTime.isAfter(_startDate!) && 
               ride.startTime.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((ride) {
        return ride.startLocality.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (ride.endLocality?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // Sort rides
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'profit':
          return _sortAscending 
              ? a.calculateProfit().compareTo(b.calculateProfit())
              : b.calculateProfit().compareTo(a.calculateProfit());
        case 'duration':
          return _sortAscending
              ? a.getDurationMinutes().compareTo(b.getDurationMinutes())
              : b.getDurationMinutes().compareTo(a.getDurationMinutes());
        case 'date':
        default:
          return _sortAscending
              ? a.startTime.compareTo(b.startTime)
              : b.startTime.compareTo(a.startTime);
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredRides = _getFilteredRides();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rides History'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
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
                  // Statistics Cards
                  _buildStatisticsCards(),
                  
                  const SizedBox(height: 24),
                  
                  // Filter Bar
                  _buildFilterBar(),
                  
                  const SizedBox(height: 20),
                  
                  // Rides List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rides (${filteredRides.length})',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade800,
                        ),
                      ),
                      if (filteredRides.isNotEmpty)
                        TextButton.icon(
                          onPressed: _showSortOptions,
                          icon: const Icon(Icons.sort),
                          label: Text(_getSortLabel()),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.deepPurple,
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Rides List
                  _buildRidesList(filteredRides),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    if (_isLoading) {
      return _buildLoadingCards();
    }

    return Column(
      children: [
        // First row - Main stats
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Rides',
                value: '${_statistics['completedRides'] ?? 0}',
                icon: Icons.directions_car,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Total Profit',
                value: '₹${(_statistics['totalProfit'] ?? 0.0).toStringAsFixed(0)}',
                icon: Icons.trending_up,
                color: Colors.green,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Second row - Additional stats
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Avg Profit/KM',
                value: '₹${(_statistics['averageProfitPerKm'] ?? 0.0).toStringAsFixed(1)}',
                icon: Icons.speed,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'This Month',
                value: '₹${(_statistics['thisMonthProfit'] ?? 0.0).toStringAsFixed(0)}',
                icon: Icons.calendar_month,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildShimmerCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildShimmerCard()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildShimmerCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildShimmerCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // Search bar
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search by location...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', _selectedStatus == null, () {
                  setState(() {
                    _selectedStatus = null;
                  });
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', _selectedStatus == RideStatus.completed, () {
                  setState(() {
                    _selectedStatus = RideStatus.completed;
                  });
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Cancelled', _selectedStatus == RideStatus.cancelled, () {
                  setState(() {
                    _selectedStatus = RideStatus.cancelled;
                  });
                }),
                const SizedBox(width: 8),
                _buildDateRangeChip(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Colors.deepPurple.shade100,
      checkmarkColor: Colors.deepPurple,
      labelStyle: TextStyle(
        color: isSelected ? Colors.deepPurple : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildDateRangeChip() {
    String label = 'All Time';
    if (_startDate != null && _endDate != null) {
      final startStr = DateFormat('MMM dd').format(_startDate!);
      final endStr = DateFormat('MMM dd').format(_endDate!);
      label = '$startStr - $endStr';
    }

    return FilterChip(
      label: Text(label),
      selected: _startDate != null && _endDate != null,
      onSelected: (_) => _showDateRangePicker(),
      selectedColor: Colors.deepPurple.shade100,
      checkmarkColor: Colors.deepPurple,
      labelStyle: TextStyle(
        color: (_startDate != null && _endDate != null) ? Colors.deepPurple : Colors.grey.shade700,
        fontWeight: (_startDate != null && _endDate != null) ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildRidesList(List<Ride> rides) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (rides.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rides.length,
      itemBuilder: (context, index) {
        final ride = rides[index];
        return _buildRideCard(ride);
      },
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;
    
    if (_searchQuery.isNotEmpty || _selectedStatus != null || _startDate != null) {
      title = 'No rides found matching your filters';
      subtitle = 'Try adjusting your search or filters';
      icon = Icons.filter_list;
    } else if (_statistics['completedRides'] == 0) {
      title = 'No completed rides yet';
      subtitle = 'Complete some rides to see them here';
      icon = Icons.directions_car_outlined;
    } else {
      title = 'No rides recorded yet';
      subtitle = 'Start recording rides to see them here';
      icon = Icons.directions_car_outlined;
    }

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
            icon,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Go back to home screen
                },
                icon: const Icon(Icons.home),
                label: const Text('Go to Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  _loadInitialData(); // Refresh data
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Debug info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Debug Info:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total rides: ${_rides.length}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  'Completed rides: ${_statistics['completedRides'] ?? 0}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  'Total rides (all): ${_statistics['totalRides'] ?? 0}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  'Loading: $_isLoading',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(Ride ride) {
    final profit = ride.calculateProfit();
    final duration = ride.getDurationMinutes();
    final profitPerKm = ride.calculateProfitPerKm();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        onTap: () => _showRideDetails(ride),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ride.status == RideStatus.completed 
                          ? Colors.green.shade100 
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ride.status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: ride.status == RideStatus.completed 
                            ? Colors.green.shade700 
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Date badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      DateFormat('MMM dd').format(ride.startTime),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Route
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ride.startLocality,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride.endLocality ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Metrics row
              Row(
                children: [
                  _buildMetricChip(
                    '${duration.toStringAsFixed(0)}m',
                    Icons.access_time,
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildMetricChip(
                    '${ride.km.toStringAsFixed(1)}km',
                    Icons.straighten,
                    Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _buildMetricChip(
                    '₹${profitPerKm.toStringAsFixed(1)}/km',
                    Icons.speed,
                    Colors.green,
                  ),
                  const Spacer(),
                  // Profit
                  Text(
                    '₹${profit.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: profit >= 0 ? Colors.green.shade600 : Colors.red.shade600,
                    ),
                  ),
                ],
              ),
              // Action buttons row
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                    onPressed: () => _editRide(ride),
                    tooltip: 'Edit ride',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _confirmDeleteRide(ride),
                    tooltip: 'Delete ride',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sort by',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSortOption('Date', 'date'),
            _buildSortOption('Profit', 'profit'),
            _buildSortOption('Duration', 'duration'),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value) {
    final isSelected = _sortBy == value;
    return ListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected)
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: Colors.deepPurple,
            ),
          const SizedBox(width: 8),
          if (isSelected)
            Icon(
              Icons.check,
              color: Colors.deepPurple,
            ),
        ],
      ),
      onTap: () {
        setState(() {
          if (_sortBy == value) {
            _sortAscending = !_sortAscending;
          } else {
            _sortBy = value;
            _sortAscending = false;
          }
        });
        Navigator.pop(context);
      },
    );
  }

  String _getSortLabel() {
    String label;
    switch (_sortBy) {
      case 'profit':
        label = 'Profit';
        break;
      case 'duration':
        label = 'Duration';
        break;
      case 'date':
      default:
        label = 'Date';
        break;
    }
    return '$label ${_sortAscending ? '↑' : '↓'}';
  }

  void _showRideDetails(Ride ride) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildRideDetailsSheet(ride),
    );
  }

  Widget _buildRideDetailsSheet(Ride ride) {
    final profit = ride.calculateProfit();
    final tip = ride.calculateTip();
    final fuelAllocation = ride.calculateFuelAllocation();
    final profitPerKm = ride.calculateProfitPerKm();
    final profitPerMin = ride.calculateProfitPerMin();
    final totalReceived = ride.getTotalAmountReceived();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Ride Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route section
                  _buildDetailsSection(
                    'Route',
                    Icons.route,
                    [
                      _buildDetailRow('From', ride.startLocality),
                      _buildDetailRow('To', ride.endLocality ?? 'Unknown'),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Timing section
                  _buildDetailsSection(
                    'Timing',
                    Icons.access_time,
                    [
                      _buildDetailRow('Start', DateFormat('MMM dd, yyyy • HH:mm').format(ride.startTime)),
                      if (ride.endTime != null)
                        _buildDetailRow('End', DateFormat('MMM dd, yyyy • HH:mm').format(ride.endTime!)),
                      _buildDetailRow('Duration', ride.getFormattedDuration()),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Financial breakdown
                  _buildDetailsSection(
                    'Financial Breakdown',
                    Icons.account_balance_wallet,
                    [
                      _buildDetailRow('Amount Received', '₹${totalReceived.toStringAsFixed(2)}'),
                      _buildDetailRow('Fare', '₹${ride.fare.toStringAsFixed(2)}'),
                      _buildDetailRow('Platform Fee', '₹${ride.platformFee.toStringAsFixed(2)}'),
                      _buildDetailRow('Toll Fee', '₹${ride.tollFee.toStringAsFixed(2)}'),
                      _buildDetailRow('Airport Fee', '₹${ride.airportFee.toStringAsFixed(2)}'),
                      _buildDetailRow('Other Fee', '₹${ride.otherFee.toStringAsFixed(2)}'),
                      _buildDetailRow('Tip', '₹${tip.toStringAsFixed(2)}', isHighlight: true),
                      _buildDetailRow('Profit', '₹${profit.toStringAsFixed(2)}', isHighlight: true),
                      _buildDetailRow('Fuel Allocation', '₹${fuelAllocation.toStringAsFixed(2)}'),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Performance metrics
                  _buildDetailsSection(
                    'Performance',
                    Icons.speed,
                    [
                      _buildDetailRow('Distance', '${ride.km.toStringAsFixed(2)} km'),
                      _buildDetailRow('Profit per KM', '₹${profitPerKm.toStringAsFixed(2)}'),
                      _buildDetailRow('Profit per Minute', '₹${profitPerMin.toStringAsFixed(2)}'),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.deepPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? Colors.deepPurple.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

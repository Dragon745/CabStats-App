import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/ride_service.dart';
import '../services/location_service.dart';
import '../services/account_balance_service.dart';
import '../models/account.dart';
import '../models/ride.dart';
import '../models/pending_fuel_allocation.dart';
import 'qr_code_screen.dart';
import 'end_ride_wizard_screen.dart';
import 'accounts_screen.dart';
import 'fuel_screen.dart';
import 'expense_screen.dart';
import 'expense_stats_screen.dart';
import 'rides_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final RideService _rideService = RideService();
  final AccountBalanceService _accountService = AccountBalanceService();

  @override
  Widget build(BuildContext context) {
    final User? user = _authService.currentUser;
    final List<Account> sampleAccounts = Account.getSampleAccounts();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? const Icon(
                      Icons.person,
                      size: 20,
                      color: Color(0xFF5F6368),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            const Text(
              'CabStats',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
                color: Color(0xFF202124),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        elevation: 0,
        surfaceTintColor: const Color(0xFFE8EAED),
        actions: [
          // QR Code Button
          IconButton(
            icon: const Icon(Icons.qr_code, color: Color(0xFF5F6368)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QRCodeScreen(),
                ),
              );
            },
            tooltip: 'Payment QR Code',
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Container(
        color: const Color(0xFFF8F9FA),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Single Ride Card - Handles both start and active ride (FIRST)
                StreamBuilder<Ride?>(
                  key: const ValueKey('active_ride_stream'),
                  stream: _rideService.getActiveRideStream(),
                  builder: (context, snapshot) {
                    final hasActiveRide = snapshot.hasData && snapshot.data != null;
                    final activeRide = snapshot.data;
                    
                    return _buildRideCard(context, hasActiveRide, activeRide, _rideService);
                  },
                ),
                const SizedBox(height: 12),

                // Comprehensive Balance & Accounts Card
                FutureBuilder<List<Account>>(
                  future: _getAccountsWithBalances(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.deepPurple, Colors.purple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.deepPurple, Colors.purple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'Error loading accounts',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }

                    final accounts = snapshot.data ?? [];
                    final totalBalance = _calculateTotalBalance(accounts);

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE8EAED)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with Total Balance and Actions
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
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '₹${totalBalance.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF202124),
                                        letterSpacing: -0.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                              // Refresh Button
                              IconButton(
                                icon: const Icon(Icons.refresh, size: 20),
                                color: const Color(0xFF5F6368),
                                onPressed: _refreshAccountBalances,
                                tooltip: 'Refresh Balances',
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFFF8F9FA),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Accounts Grid
                          const Text(
                            'Account Breakdown',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF202124),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Accounts in 2x2 grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.6,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: accounts.length,
                            itemBuilder: (context, index) {
                              final account = accounts[index];
                              return _buildAccountInBalanceCard(account);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Pending Fuel Allocation Card
                StreamBuilder<PendingFuelAllocation?>(
                  stream: _accountService.getPendingFuelAllocationStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null && snapshot.data!.amount > 0) {
                      final allocation = snapshot.data!;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFB8500),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
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
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const FuelScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '₹${allocation.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'From ${allocation.rideIds.length} ride${allocation.rideIds.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 12),

                // Quick Actions (Only Add Expense)
                SizedBox(
                  width: double.infinity,
                  child: _buildQuickActionCard(
                    icon: Icons.receipt_long,
                    color: const Color(0xFF10B981),
                    label: 'Add Expense',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ExpenseScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8EAED)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF202124),
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final User? user = _authService.currentUser;
    
    return Drawer(
      child: Container(
        color: const Color(0xFFF8F9FA),
        child: Column(
          children: [
            // User Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 24),
              decoration: const BoxDecoration(
                color: Color(0xFF4285F4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                        child: user?.photoURL == null
                            ? const Icon(Icons.person, size: 28, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'User',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                letterSpacing: 0.15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                letterSpacing: 0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.account_balance,
                    title: 'Accounts',
                    subtitle: 'Manage your accounts',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AccountsScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.directions_car,
                    title: 'Rides',
                    subtitle: 'View ride history',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RidesHistoryScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.local_gas_station,
                    title: 'Fuel',
                    subtitle: 'Manage fuel allocation',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FuelScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.receipt_long,
                    title: 'Expense Stats',
                    subtitle: 'View and analyze expenses',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ExpenseStatsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  const SizedBox(height: 8),
                  
                  // Sign Out
                  _buildDestructiveDrawerItem(
                    context,
                    icon: Icons.logout,
                    title: 'Sign Out',
                    onTap: () {
                      Navigator.pop(context);
                      _authService.signOut();
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Reset All Data
                  _buildDestructiveDrawerItem(
                    context,
                    icon: Icons.delete_forever,
                    title: 'Reset All Data',
                    subtitle: 'Delete all rides, accounts, and transactions',
                    isDestructive: false,
                    onTap: () {
                      Navigator.pop(context);
                      _showResetDataDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF4285F4),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF202124),
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDestructiveDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    bool isDestructive = true,
    required VoidCallback onTap,
  }) {
    final color = isDestructive ? const Color(0xFFEF4444) : const Color(0xFFEF6C00);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: color,
                          letterSpacing: 0.1,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRideCard(BuildContext context, bool hasActiveRide, Ride? activeRide, RideService rideService) {
    if (hasActiveRide && activeRide != null) {
      // Active Ride Card - Material Design 3
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Ride in Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeRide.startLocality.isNotEmpty ? activeRide.startLocality : 'Unknown Location',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        StreamBuilder<DateTime>(
                          key: const ValueKey('ride_timer_stream'),
                          stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text(
                                'Duration: --:--:--',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              );
                            }
                            
                            final now = snapshot.data ?? DateTime.now();
                            final duration = now.difference(activeRide.startTime);
                            final durationString = _formatDuration(duration);
                            
                            return Text(
                              durationString,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancelRide(context, rideService, activeRide.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _endRide(context, activeRide),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text('End Ride'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      // Start Ride Card - Material Design 3
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF4285F4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Start New Ride',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _startRide(context, rideService),
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label: const Text('Start Ride'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4285F4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  Future<void> _startRide(BuildContext context, RideService rideService) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Starting ride...',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );

      // First check if location is ready
      final locationService = LocationService();
      final readiness = await locationService.checkLocationReadiness();
      
      if (!readiness['ready']) {
        Navigator.pop(context); // Close loading dialog
        
        // Show specific error dialog based on the issue
        await _showLocationErrorDialog(context, readiness);
        return;
      }
      
      // Get current location
      final locality = await locationService.getCurrentLocality();
      
      if (locality == null || locality.isEmpty) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get current location. Please check your GPS signal and try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      // Start the ride
      final ride = await rideService.startRide(locality);
      
      Navigator.pop(context); // Close loading dialog
      
      if (ride != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride started successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start ride. Please check your internet connection and try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      
      // Provide more specific error messages
      String errorMessage = 'Error starting ride: ${e.toString()}';
      if (e.toString().contains('permission')) {
        errorMessage = 'Location permission is required. Please grant location permission in your device settings.';
      } else if (e.toString().contains('disabled')) {
        errorMessage = 'Location services are disabled. Please enable location services in your device settings.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Location request timed out. Please check your GPS signal and try again.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _showLocationErrorDialog(BuildContext context, Map<String, dynamic> readiness) async {
    String action = readiness['action'] ?? 'retry';
    String message = readiness['message'] ?? 'Location error occurred';
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Required'),
          content: Text(message),
          actions: <Widget>[
            if (action == 'request_permission')
              TextButton(
                child: const Text('Grant Permission'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  final locationService = LocationService();
                  await locationService.requestLocationPermissionWithMessage();
                  // Retry starting ride
                  _startRide(context, _rideService);
                },
              ),
            if (action == 'enable_location_services')
              TextButton(
                child: const Text('Open Settings'),
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enable location services in your device settings and try again.'),
                      duration: Duration(seconds: 5),
                    ),
                  );
                },
              ),
            if (action == 'open_app_settings')
              TextButton(
                child: const Text('Open App Settings'),
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enable location permission in app settings and try again.'),
                      duration: Duration(seconds: 5),
                    ),
                  );
                },
              ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            if (action == 'retry')
              TextButton(
                child: const Text('Retry'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _startRide(context, _rideService);
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _cancelRide(BuildContext context, RideService rideService, String rideId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Ride?'),
        content: const Text('Are you sure you want to cancel this ride? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Option 1: Mark as cancelled (keeps in database for history)
        // final success = await rideService.cancelRide(rideId);
        
        // Option 2: Completely delete (removes from database)
        final success = await rideService.deleteRide(rideId);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride deleted successfully!'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete ride. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting ride: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
        );
      }
    }
  }

  Future<void> _endRide(BuildContext context, Ride activeRide) async {
    // Get current location for end locality
    try {
      final locationService = LocationService();
      final endLocality = await locationService.getCurrentLocality();
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EndRideWizardScreen(
            ride: activeRide,
            endLocality: endLocality,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAccountInBalanceCard(Account account) {
    // Map account IDs to Material icons
    IconData accountIcon;
    switch (account.id) {
      case 'federal_bank':
        accountIcon = Icons.account_balance;
        break;
      case 'axis_bank':
        accountIcon = Icons.local_gas_station;
        break;
      case 'cash':
        accountIcon = Icons.attach_money;
        break;
      case 'platform_wallets':
        accountIcon = Icons.account_balance_wallet;
        break;
      default:
        accountIcon = Icons.account_balance;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(int.parse(account.color)).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE8EAED),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(int.parse(account.color)).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  accountIcon,
                  color: Color(int.parse(account.color)),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF202124),
                        letterSpacing: 0,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      account.type,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '₹${account.balance.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4285F4),
              letterSpacing: 0,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  // Manual refresh method - triggers a rebuild
  Future<void> _refreshAccountBalances() async {
    setState(() {
      // This will trigger the FutureBuilder to rebuild with fresh data
    });
  }

  // Fetch account balances from database
  Future<List<Account>> _getAccountsWithBalances() async {
    final List<Account> sampleAccounts = Account.getSampleAccounts();
    final List<Account> accountsWithBalances = [];
    
    for (final account in sampleAccounts) {
      try {
        final balance = await _accountService.getAccountBalance(account.id);
        
        final accountWithBalance = Account(
          id: account.id,
          name: account.name,
          type: account.type,
          balance: balance,
          icon: account.icon,
          color: account.color,
        );
        accountsWithBalances.add(accountWithBalance);
      } catch (e) {
        // Add account with zero balance if there's an error
        accountsWithBalances.add(account);
      }
    }
    
    return accountsWithBalances;
  }

  // Calculate total balance from accounts
  double _calculateTotalBalance(List<Account> accounts) {
    return accounts.fold(0.0, (sum, account) => sum + account.balance);
  }

  void _showResetDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text('Reset All Data'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action will permanently delete:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              const Text('• All ride records'),
              const Text('• All account balances'),
              const Text('• All transaction history'),
              const Text('• All account transfers'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone!',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
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
              onPressed: () {
                Navigator.of(context).pop();
                _resetAllData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete All Data'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetAllData() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Deleting all data...'),
              ],
            ),
          );
        },
      );

      // Delete all user data
      await _rideService.deleteAllRides();
      await _accountService.deleteAllAccountData();

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data has been deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the screen
      setState(() {});
    } catch (e) {
      // Close loading dialog if still open
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

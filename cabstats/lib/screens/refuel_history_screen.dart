import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/refuel.dart';
import '../services/account_balance_service.dart';

class RefuelHistoryScreen extends StatefulWidget {
  const RefuelHistoryScreen({super.key});

  @override
  State<RefuelHistoryScreen> createState() => _RefuelHistoryScreenState();
}

class _RefuelHistoryScreenState extends State<RefuelHistoryScreen> {
  final AccountBalanceService _accountService = AccountBalanceService();
  
  List<Refuel> _refuels = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadRefuels();
  }

  Future<void> _loadRefuels() async {
    try {
      final refuels = await _accountService.getRefuels();
      if (mounted) {
        setState(() {
          _refuels = refuels;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading refuel history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    await _loadRefuels();

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _deleteRefuel(Refuel refuel) async {
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
                Text('Deleting refuel record...'),
              ],
            ),
          );
        },
      );

      // Delete refuel record
      if (refuel.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot delete refuel record: Invalid ID'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final success = await _accountService.deleteRefuel(refuel.id!);

      // Hide loading indicator
      Navigator.of(context).pop();

      if (success) {
        // Refresh the data
        await _refreshData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refuel record deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete refuel record'),
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
          content: Text('Error deleting refuel record: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmDeleteRefuel(Refuel refuel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Refuel Record'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete this refuel record?'),
              const SizedBox(height: 8),
              Text('Refuel Details:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Cost: ₹${refuel.cost.toStringAsFixed(2)}'),
              Text('• Kilometers: ${refuel.kilometers.toStringAsFixed(0)} km'),
              if (refuel.location != null) Text('• Location: ${refuel.location}'),
              Text('• Date: ${DateFormat('MMM dd, yyyy • HH:mm').format(refuel.timestamp)}'),
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
                await _deleteRefuel(refuel);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refuel History'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _refuels.isEmpty
                ? _buildEmptyState()
                : _buildRefuelsList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_gas_station_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No refuel records yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start recording refuels to see them here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Go back to fuel screen
            },
            icon: const Icon(Icons.local_gas_station),
            label: const Text('Go to Fuel Screen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefuelsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _refuels.length,
      itemBuilder: (context, index) {
        final refuel = _refuels[index];
        return _buildRefuelCard(refuel);
      },
    );
  }

  Widget _buildRefuelCard(Refuel refuel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Fuel icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_gas_station,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Cost
                Expanded(
                  child: Text(
                    '₹${refuel.cost.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade600,
                    ),
                  ),
                ),
                // Delete button
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red.shade400, size: 20),
                  onPressed: () => _confirmDeleteRefuel(refuel),
                  tooltip: 'Delete refuel record',
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Kilometers',
                    '${refuel.kilometers.toStringAsFixed(0)} km',
                    Icons.speed,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Date',
                    DateFormat('MMM dd, yyyy').format(refuel.timestamp),
                    Icons.calendar_today,
                    Colors.grey,
                  ),
                ),
              ],
            ),
            
            // Time
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  DateFormat('HH:mm').format(refuel.timestamp),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            
            // Location and notes
            if (refuel.location != null || refuel.notes != null) ...[
              const SizedBox(height: 12),
              if (refuel.location != null) ...[
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        refuel.location!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (refuel.notes != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        refuel.notes!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

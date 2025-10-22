import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ride.dart';
import '../models/account.dart';
import '../services/ride_service.dart';

class EndRideScreen extends StatefulWidget {
  final Ride ride;
  final String? endLocality;

  const EndRideScreen({super.key, required this.ride, this.endLocality});

  @override
  State<EndRideScreen> createState() => _EndRideScreenState();
}

class _EndRideScreenState extends State<EndRideScreen> {
  final RideService _rideService = RideService();
  final List<Account> _accounts = Account.getSampleAccounts();
  
  // Form controllers
  final TextEditingController _kmController = TextEditingController();
  final TextEditingController _fareController = TextEditingController();
  final TextEditingController _tollFeeController = TextEditingController();
  final TextEditingController _platformFeeController = TextEditingController();
  final TextEditingController _otherFeeController = TextEditingController();
  final TextEditingController _airportFeeController = TextEditingController();
  
  // Account selections
  String _tollFeeAccount = 'federal_bank';
  String _platformFeeAccount = 'federal_bank';
  String _otherFeeAccount = 'federal_bank';
  String _airportFeeAccount = 'federal_bank';
  
  // Payment splits
  List<Map<String, dynamic>> _paymentSplits = [
    {'accountId': 'federal_bank', 'amount': 0.0}
  ];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    // Set default values
    _kmController.text = '0';
    _fareController.text = '0';
    _tollFeeController.text = '0';
    _platformFeeController.text = '0';
    _otherFeeController.text = '0';
    _airportFeeController.text = '0';
    
    // Set default account selections
    _tollFeeAccount = Account.getDefaultAccount(_accounts).id;
    _platformFeeAccount = Account.getDefaultAccount(_accounts).id;
    _otherFeeAccount = Account.getDefaultAccount(_accounts).id;
    _airportFeeAccount = Account.getDefaultAccount(_accounts).id;
    
    // Initialize payment splits with default account
    _paymentSplits = [
      {'accountId': Account.getDefaultAccount(_accounts).id, 'amount': 0.0}
    ];
  }

  @override
  void dispose() {
    _kmController.dispose();
    _fareController.dispose();
    _tollFeeController.dispose();
    _platformFeeController.dispose();
    _otherFeeController.dispose();
    _airportFeeController.dispose();
    super.dispose();
  }

  double _parseDouble(String value) {
    return double.tryParse(value) ?? 0.0;
  }

  Map<String, double> _getPaymentSplitsMap() {
    Map<String, double> splits = {};
    for (var split in _paymentSplits) {
      final accountId = split['accountId'] as String;
      final amount = split['amount'] as double;
      if (amount != 0) {
        splits[accountId] = amount;
      }
    }
    return splits;
  }

  double _getTotalAmountReceived() {
    return _paymentSplits.fold(0.0, (sum, split) => sum + (split['amount'] as double));
  }

  Ride _createUpdatedRide() {
    return widget.ride.copyWith(
      endLocality: widget.endLocality ?? widget.ride.endLocality,
      km: _parseDouble(_kmController.text),
      fare: _parseDouble(_fareController.text),
      tollFee: _parseDouble(_tollFeeController.text),
      platformFee: _parseDouble(_platformFeeController.text),
      otherFee: _parseDouble(_otherFeeController.text),
      airportFee: _parseDouble(_airportFeeController.text),
      paymentSplits: _getPaymentSplitsMap(),
      tollFeeAccount: _tollFeeAccount,
      platformFeeAccount: _platformFeeAccount,
      otherFeeAccount: _otherFeeAccount,
      airportFeeAccount: _airportFeeAccount,
    );
  }

  void _addPaymentSplit() {
    setState(() {
      _paymentSplits.add({'accountId': Account.getDefaultAccount(_accounts).id, 'amount': 0.0});
    });
  }

  void _removePaymentSplit(int index) {
    if (_paymentSplits.length > 1) {
      setState(() {
        _paymentSplits.removeAt(index);
      });
    }
  }

  void _updatePaymentSplit(int index, String field, dynamic value) {
    setState(() {
      _paymentSplits[index][field] = value;
    });
  }

  Future<void> _saveRide() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedRide = _createUpdatedRide();
      final success = await _rideService.endRide(widget.ride.id, updatedRide);
      
      if (success) {
        Navigator.popUntil(context, (route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save ride. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving ride: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildAccountDropdown(String value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: _accounts.map((account) {
        return DropdownMenuItem<String>(
          value: account.id,
          child: Text(account.displayName),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildNumberField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixText: label.contains('₹') ? '₹' : null,
        suffixText: label.contains('KM') ? 'km' : null,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*')),
      ],
      onChanged: (value) => setState(() {}),
    );
  }

  Widget _buildPaymentSplitRow(int index) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: _paymentSplits[index]['accountId'],
                decoration: const InputDecoration(
                  labelText: 'Account',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                items: _accounts.map((account) {
                  return DropdownMenuItem<String>(
                    value: account.id,
                    child: Text(account.shortDisplayName),
                  );
                }).toList(),
                onChanged: (value) => _updatePaymentSplit(index, 'accountId', value ?? _paymentSplits[index]['accountId']),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixText: '₹',
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*')),
                ],
                onChanged: (value) {
                  _updatePaymentSplit(index, 'amount', _parseDouble(value));
                },
              ),
            ),
            if (_paymentSplits.length > 1)
              IconButton(
                onPressed: () => _removePaymentSplit(index),
                icon: const Icon(Icons.remove_circle, color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final updatedRide = _createUpdatedRide();
    final totalAmountReceived = _getTotalAmountReceived();
    final tip = updatedRide.calculateTip();
    final profit = updatedRide.calculateProfit();
    final fuelAllocation = updatedRide.calculateFuelAllocation();
    final profitPerKm = updatedRide.calculateProfitPerKm();
    final profitPerMin = updatedRide.calculateProfitPerMin();

    return Scaffold(
      appBar: AppBar(
        title: const Text('End Ride'),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ride Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ride Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('From: ${widget.ride.startLocality}'),
                        Text('To: ${widget.endLocality ?? widget.ride.endLocality ?? "Unknown"}'),
                        Text('Duration: ${widget.ride.getDurationString()}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Basic Ride Data
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ride Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildNumberField(_kmController, 'Distance (KM)'),
                        const SizedBox(height: 12),
                        _buildNumberField(_fareController, 'Fare (₹)'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Fees Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fees & Deductions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildNumberField(_tollFeeController, 'Toll Fee')),
                            const SizedBox(width: 8),
                            Expanded(child: _buildAccountDropdown(_tollFeeAccount, (value) => setState(() => _tollFeeAccount = value ?? _tollFeeAccount))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildNumberField(_platformFeeController, 'Platform Fee')),
                            const SizedBox(width: 8),
                            Expanded(child: _buildAccountDropdown(_platformFeeAccount, (value) => setState(() => _platformFeeAccount = value ?? _platformFeeAccount))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildNumberField(_otherFeeController, 'Other Fee')),
                            const SizedBox(width: 8),
                            Expanded(child: _buildAccountDropdown(_otherFeeAccount, (value) => setState(() => _otherFeeAccount = value ?? _otherFeeAccount))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildNumberField(_airportFeeController, 'Airport Fee')),
                            const SizedBox(width: 8),
                            Expanded(child: _buildAccountDropdown(_airportFeeAccount, (value) => setState(() => _airportFeeAccount = value ?? _airportFeeAccount))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Splits Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Payment Received',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _addPaymentSplit,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Payment'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(_paymentSplits.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildPaymentSplitRow(index),
                          );
                        }),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Amount Received:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '₹${totalAmountReceived.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Calculations Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Calculations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildCalculationRow('Tip', tip, Colors.orange),
                        _buildCalculationRow('Profit', profit, Colors.green),
                        _buildCalculationRow('Fuel Allocation', fuelAllocation, Colors.blue),
                        _buildCalculationRow('Profit Per KM', profitPerKm, Colors.purple),
                        _buildCalculationRow('Profit Per Min', profitPerMin, Colors.teal),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveRide,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Save Ride'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalculationRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ride.dart';
import '../models/account.dart';
import '../services/ride_service.dart';
import '../services/account_balance_service.dart';

class EditRideScreen extends StatefulWidget {
  final Ride ride;

  const EditRideScreen({super.key, required this.ride});

  @override
  State<EditRideScreen> createState() => _EditRideScreenState();
}

class _EditRideScreenState extends State<EditRideScreen> {
  final RideService _rideService = RideService();
  final AccountBalanceService _accountService = AccountBalanceService();
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late TextEditingController _kmController;
  late TextEditingController _fareController;
  late TextEditingController _tollFeeController;
  late TextEditingController _platformFeeController;
  late TextEditingController _otherFeeController;
  late TextEditingController _airportFeeController;

  // Payment split controllers
  late Map<String, TextEditingController> _paymentControllers;

  // Selected accounts for fees
  String _tollFeeAccount = '';
  String _platformFeeAccount = '';
  String _otherFeeAccount = '';
  String _airportFeeAccount = '';

  // Available accounts
  List<Account> _accounts = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadAccounts();
  }

  void _initializeControllers() {
    final ride = widget.ride;
    
    _kmController = TextEditingController(text: ride.km.toString());
    _fareController = TextEditingController(text: ride.fare.toString());
    _tollFeeController = TextEditingController(text: ride.tollFee.toString());
    _platformFeeController = TextEditingController(text: ride.platformFee.toString());
    _otherFeeController = TextEditingController(text: ride.otherFee.toString());
    _airportFeeController = TextEditingController(text: ride.airportFee.toString());

    // Initialize payment controllers
    _paymentControllers = {};
    for (final account in Account.getSampleAccounts()) {
      final amount = ride.paymentSplits[account.id] ?? 0.0;
      _paymentControllers[account.id] = TextEditingController(text: amount.toString());
    }

    // Set fee accounts
    _tollFeeAccount = ride.tollFeeAccount;
    _platformFeeAccount = ride.platformFeeAccount;
    _otherFeeAccount = ride.otherFeeAccount;
    _airportFeeAccount = ride.airportFeeAccount;
  }

  void _loadAccounts() {
    setState(() {
      _accounts = Account.getSampleAccounts();
    });
  }

  @override
  void dispose() {
    _kmController.dispose();
    _fareController.dispose();
    _tollFeeController.dispose();
    _platformFeeController.dispose();
    _otherFeeController.dispose();
    _airportFeeController.dispose();
    
    for (final controller in _paymentControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }

  double _getTotalPaymentAmount() {
    double total = 0.0;
    for (final controller in _paymentControllers.values) {
      final amount = double.tryParse(controller.text) ?? 0.0;
      total += amount;
    }
    return total;
  }

  double _getTotalFees() {
    final tollFee = double.tryParse(_tollFeeController.text) ?? 0.0;
    final platformFee = double.tryParse(_platformFeeController.text) ?? 0.0;
    final otherFee = double.tryParse(_otherFeeController.text) ?? 0.0;
    final airportFee = double.tryParse(_airportFeeController.text) ?? 0.0;
    return tollFee + platformFee + otherFee + airportFee;
  }

  double _calculateProfit() {
    return _getTotalPaymentAmount() - _getTotalFees();
  }

  double _calculateTip() {
    final fare = double.tryParse(_fareController.text) ?? 0.0;
    return _getTotalPaymentAmount() - fare - _getTotalFees();
  }

  Map<String, double> _getPaymentSplits() {
    Map<String, double> splits = {};
    for (final entry in _paymentControllers.entries) {
      final amount = double.tryParse(entry.value.text) ?? 0.0;
      if (amount > 0) {
        splits[entry.key] = amount;
      }
    }
    return splits;
  }

  Future<void> _saveRide() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create updated ride
      final updatedRide = widget.ride.copyWith(
        km: double.parse(_kmController.text),
        fare: double.parse(_fareController.text),
        tollFee: double.parse(_tollFeeController.text),
        platformFee: double.parse(_platformFeeController.text),
        otherFee: double.parse(_otherFeeController.text),
        airportFee: double.parse(_airportFeeController.text),
        paymentSplits: _getPaymentSplits(),
        tollFeeAccount: _tollFeeAccount,
        platformFeeAccount: _platformFeeAccount,
        otherFeeAccount: _otherFeeAccount,
        airportFeeAccount: _airportFeeAccount,
      );

      // First, reverse old transactions
      await _accountService.reverseRideTransactions(widget.ride.id);

      // Update the ride document
      await _rideService.updateRide(widget.ride.id, updatedRide.toJson());

      // Process new transactions
      final paymentSplits = _getPaymentSplits();
      final feeDeductions = <String, double>{};
      final paymentCredits = <String, double>{};

      // Add fee deductions
      final tollFee = double.parse(_tollFeeController.text);
      final platformFee = double.parse(_platformFeeController.text);
      final otherFee = double.parse(_otherFeeController.text);
      final airportFee = double.parse(_airportFeeController.text);

      if (tollFee > 0) feeDeductions[_tollFeeAccount] = tollFee;
      if (platformFee > 0) feeDeductions[_platformFeeAccount] = platformFee;
      if (otherFee > 0) feeDeductions[_otherFeeAccount] = otherFee;
      if (airportFee > 0) feeDeductions[_airportFeeAccount] = airportFee;

      // Add payment credits
      for (final entry in paymentSplits.entries) {
        paymentCredits[entry.key] = entry.value;
      }

      // Process transactions
      await _accountService.processRideTransactions(
        rideId: widget.ride.id,
        feeDeductions: feeDeductions,
        paymentCredits: paymentCredits,
      );

      // Add fuel allocation
      final fuelAllocation = _calculateProfit() / 2;
      if (fuelAllocation > 0) {
        await _accountService.addPendingFuelAllocation(fuelAllocation, widget.ride.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating ride: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Ride'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveRide,
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
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
                      Text(
                        'Ride Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _kmController,
                              decoration: const InputDecoration(
                                labelText: 'Distance (KM)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter distance';
                                }
                                final km = double.tryParse(value);
                                if (km == null || km <= 0) {
                                  return 'Please enter valid distance';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _fareController,
                              decoration: const InputDecoration(
                                labelText: 'Fare (₹)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter fare';
                                }
                                final fare = double.tryParse(value);
                                if (fare == null || fare < 0) {
                                  return 'Please enter valid fare';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Fees Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fees',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tollFeeController,
                              decoration: const InputDecoration(
                                labelText: 'Toll Fee (₹)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _platformFeeController,
                              decoration: const InputDecoration(
                                labelText: 'Platform Fee (₹)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _otherFeeController,
                              decoration: const InputDecoration(
                                labelText: 'Other Fee (₹)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _airportFeeController,
                              decoration: const InputDecoration(
                                labelText: 'Airport Fee (₹)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Payment Splits Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Splits',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._accounts.map((account) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          controller: _paymentControllers[account.id],
                          decoration: InputDecoration(
                            labelText: '${account.name} (₹)',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Payment:'),
                          Text(
                            '₹${_getTotalPaymentAmount().toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Fees:'),
                          Text(
                            '₹${_getTotalFees().toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tip:'),
                          Text(
                            '₹${_calculateTip().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _calculateTip() >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Profit:'),
                          Text(
                            '₹${_calculateProfit().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _calculateProfit() >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Fuel Allocation:'),
                          Text(
                            '₹${(_calculateProfit() / 2).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

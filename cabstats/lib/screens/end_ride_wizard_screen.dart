import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ride.dart';
import '../models/account.dart';
import '../models/ledger_entry.dart';
import '../services/ride_service.dart';
import '../services/account_balance_service.dart';
import 'ride_stats_screen.dart';

class EndRideWizardScreen extends StatefulWidget {
  final Ride ride;
  final String? endLocality;

  const EndRideWizardScreen({super.key, required this.ride, this.endLocality});

  @override
  State<EndRideWizardScreen> createState() => _EndRideWizardScreenState();
}

class _EndRideWizardScreenState extends State<EndRideWizardScreen> {
  final RideService _rideService = RideService();
  final AccountBalanceService _accountService = AccountBalanceService();
  final List<Account> _accounts = Account.getSampleAccounts();
  
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Form data
  final TextEditingController _kmController = TextEditingController();
  final TextEditingController _fareController = TextEditingController();
  final TextEditingController _tollFeeController = TextEditingController();
  final TextEditingController _platformFeeController = TextEditingController();
  final TextEditingController _airportFeeController = TextEditingController();
  final TextEditingController _otherFeeController = TextEditingController();
  final TextEditingController _upiPaymentController = TextEditingController();
  final TextEditingController _cashPaymentController = TextEditingController();
  final TextEditingController _platformPaymentController = TextEditingController();

  // Focus nodes for auto-focus and auto-advance
  final List<FocusNode> _focusNodes = List.generate(9, (index) => FocusNode());

  String _tollFeeAccount = '';
  String _platformFeeAccount = '';
  String _airportFeeAccount = '';
  String _otherFeeAccount = '';

  // Calculated values
  double _tip = 0.0;
  double _profit = 0.0;
  double _fuelAllocation = 0.0;
  double _profitPerKm = 0.0;
  double _profitPerMin = 0.0;

  @override
  void initState() {
    super.initState();
    final defaultAccount = Account.getDefaultAccount(_accounts);
    _tollFeeAccount = defaultAccount.id;
    _platformFeeAccount = defaultAccount.id;
    _airportFeeAccount = defaultAccount.id;
    _otherFeeAccount = defaultAccount.id;
    
    // Auto-focus the first field after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _kmController.dispose();
    _fareController.dispose();
    _tollFeeController.dispose();
    _platformFeeController.dispose();
    _airportFeeController.dispose();
    _otherFeeController.dispose();
    _upiPaymentController.dispose();
    _cashPaymentController.dispose();
    _platformPaymentController.dispose();
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  double _parseDouble(String value) {
    if (value.isEmpty) return 0.0;
    return double.tryParse(value) ?? 0.0;
  }

  void _calculateMetrics() {
    final km = _parseDouble(_kmController.text);
    final fare = _parseDouble(_fareController.text);
    final tollFee = _parseDouble(_tollFeeController.text);
    final platformFee = _parseDouble(_platformFeeController.text);
    final airportFee = _parseDouble(_airportFeeController.text);
    final otherFee = _parseDouble(_otherFeeController.text);
    
    final upiPayment = _parseDouble(_upiPaymentController.text);
    final cashPayment = _parseDouble(_cashPaymentController.text);
    final platformPayment = _parseDouble(_platformPaymentController.text);
    
    final totalAmountReceived = upiPayment + cashPayment + platformPayment;
    final totalFees = tollFee + platformFee + airportFee + otherFee;

    // Tip = Amount Received - Fare - Platform Fee - Other Fee - Airport Fee - Toll Fee
    _tip = totalAmountReceived - fare - totalFees;

    // Profit = Amount Received - Platform Fee - Other Fee - Airport Fee - Toll Fee
    _profit = totalAmountReceived - totalFees;

    // Fuel Allocation = Profit / 2
    _fuelAllocation = _profit / 2;

    // Profit Per KM = Profit / KM
    _profitPerKm = (km > 0) ? _profit / km : 0;

    // Profit Per Min = Profit / Minutes
    final durationMinutes = widget.ride.getDurationMinutes();
    _profitPerMin = (durationMinutes > 0) ? _profit / durationMinutes : 0;

    setState(() {});
  }

  void _nextStep() {
    if (_currentStep < 8) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      // Auto-focus the next field after page transition
      Future.delayed(const Duration(milliseconds: 350), () {
        if (_currentStep < _focusNodes.length) {
          _focusNodes[_currentStep].requestFocus();
        }
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveRide() async {
    try {
      // Create updated ride
      final updatedRide = widget.ride.copyWith(
        endLocality: widget.endLocality ?? widget.ride.endLocality,
        km: _parseDouble(_kmController.text),
        fare: _parseDouble(_fareController.text),
        tollFee: _parseDouble(_tollFeeController.text),
        platformFee: _parseDouble(_platformFeeController.text),
        otherFee: _parseDouble(_otherFeeController.text),
        airportFee: _parseDouble(_airportFeeController.text),
        tollFeeAccount: _tollFeeAccount,
        platformFeeAccount: _platformFeeAccount,
        otherFeeAccount: _otherFeeAccount,
        airportFeeAccount: _airportFeeAccount,
        paymentSplits: {
          'federal_bank': _parseDouble(_upiPaymentController.text),
          'cash': _parseDouble(_cashPaymentController.text),
          'platform_wallets': _parseDouble(_platformPaymentController.text),
        },
        status: RideStatus.completed,
      );

      // Calculate metrics
      updatedRide.calculateMetrics();

      // Save ride
      final success = await _rideService.endRide(updatedRide.id!, updatedRide);
      
      if (success) {
        // Process account transactions
        await _processAccountTransactions(updatedRide);
        
        if (mounted) {
          // Navigate to stats screen instead of closing
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RideStatsScreen(ride: updatedRide),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save ride. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving ride: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processAccountTransactions(Ride ride) async {
    try {
      // Process fee deductions
      Map<String, double> feeDeductions = {};
      if (ride.tollFee != null && ride.tollFee! > 0) {
        feeDeductions[ride.tollFeeAccount!] = ride.tollFee!;
      }
      if (ride.platformFee != null && ride.platformFee! > 0) {
        feeDeductions[ride.platformFeeAccount!] = ride.platformFee!;
      }
      if (ride.airportFee != null && ride.airportFee! > 0) {
        feeDeductions[ride.airportFeeAccount!] = ride.airportFee!;
      }
      if (ride.otherFee != null && ride.otherFee! > 0) {
        feeDeductions[ride.otherFeeAccount!] = ride.otherFee!;
      }

      // Process payment credits
      Map<String, double> paymentCredits = {};
      ride.paymentSplits.forEach((accountId, amount) {
        if (amount > 0) {
          paymentCredits[accountId] = amount;
        }
      });

      // Add transactions to ledger
      await _accountService.processRideTransactions(
        rideId: ride.id!,
        feeDeductions: feeDeductions,
        paymentCredits: paymentCredits,
      );

      // Add pending fuel allocation
      if (ride.fuelAllocation != null && ride.fuelAllocation! > 0) {
        await _accountService.addPendingFuelAllocation(
          ride.fuelAllocation!,
          ride.id!,
        );
        print('✅ Added pending fuel allocation: ₹${ride.fuelAllocation}');
      }

      print('Account transactions processed successfully');
    } catch (e) {
      print('Error processing account transactions: $e');
    }
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(9, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: index <= _currentStep ? Colors.deepPurple : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentStep == 8 ? _saveRide : _nextStep,
              child: Text(_currentStep == 8 ? 'Save Ride' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('End Ride - Step ${_currentStep + 1} of 9'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildDistanceStep(),
                _buildFareStep(),
                _buildTollFeeStep(),
                _buildPlatformFeeStep(),
                _buildAirportFeeStep(),
                _buildOtherFeeStep(),
                _buildUpiPaymentStep(),
                _buildCashPaymentStep(),
                _buildPlatformPaymentStep(),
                _buildStatsStep(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildDistanceStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distance Traveled',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _kmController,
            focusNode: _focusNodes[0],
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*')),
            ],
            decoration: const InputDecoration(
              labelText: 'Distance (KM)',
              hintText: 'Enter distance traveled',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.straighten),
            ),
            onChanged: (_) => _calculateMetrics(),
            onFieldSubmitted: (_) => _nextStep(),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          const Text(
            'Note: You can enter negative values for adjustments',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFareStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fare Amount',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fareController,
            focusNode: _focusNodes[1],
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*')),
            ],
            decoration: const InputDecoration(
              labelText: 'Fare (₹)',
              hintText: 'Enter fare amount',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.currency_rupee),
            ),
            onChanged: (_) => _calculateMetrics(),
            onFieldSubmitted: (_) => _nextStep(),
            textInputAction: TextInputAction.next,
          ),
        ],
      ),
    );
  }

  Widget _buildTollFeeStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Toll Fee',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tollFeeController,
            focusNode: _focusNodes[2],
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*')),
            ],
            decoration: const InputDecoration(
              labelText: 'Toll Fee (₹)',
              hintText: 'Enter toll fee amount',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.toll),
            ),
            onChanged: (_) => _calculateMetrics(),
            onFieldSubmitted: (_) => _nextStep(),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          const Text('Deduct from:', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _tollFeeAccount,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: _accounts.map((account) {
              return DropdownMenuItem(
                value: account.id,
                child: Text('${account.icon} ${account.name}'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _tollFeeAccount = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformFeeStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Platform Fee',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _platformFeeController,
            focusNode: _focusNodes[3],
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*')),
            ],
            decoration: const InputDecoration(
              labelText: 'Platform Fee (₹)',
              hintText: 'Enter platform fee amount',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business),
            ),
            onChanged: (_) => _calculateMetrics(),
            onFieldSubmitted: (_) => _nextStep(),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          const Text('Deduct from:', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _platformFeeAccount,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: _accounts.map((account) {
              return DropdownMenuItem(
                value: account.id,
                child: Text('${account.icon} ${account.name}'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _platformFeeAccount = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAirportFeeStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Airport Fee',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _airportFeeController,
            focusNode: _focusNodes[4],
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*')),
            ],
            decoration: const InputDecoration(
              labelText: 'Airport Fee (₹)',
              hintText: 'Enter airport fee amount',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.flight),
            ),
            onChanged: (_) => _calculateMetrics(),
            onFieldSubmitted: (_) => _nextStep(),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          const Text('Deduct from:', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _airportFeeAccount,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: _accounts.map((account) {
              return DropdownMenuItem(
                value: account.id,
                child: Text('${account.icon} ${account.name}'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _airportFeeAccount = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOtherFeeStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Other Fee',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _otherFeeController,
            focusNode: _focusNodes[5],
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*')),
            ],
            decoration: const InputDecoration(
              labelText: 'Other Fee (₹)',
              hintText: 'Enter other fee amount',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.more_horiz),
            ),
            onChanged: (_) => _calculateMetrics(),
            onFieldSubmitted: (_) => _nextStep(),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          const Text('Deduct from:', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _otherFeeAccount,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: _accounts.map((account) {
              return DropdownMenuItem(
                value: account.id,
                child: Text('${account.icon} ${account.name}'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _otherFeeAccount = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUpiPaymentStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'UPI Payment',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _upiPaymentController,
            focusNode: _focusNodes[6],
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*')),
            ],
            decoration: const InputDecoration(
              labelText: 'UPI Payment (₹)',
              hintText: 'Enter UPI payment amount',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.payment),
            ),
            onChanged: (_) => _calculateMetrics(),
            onFieldSubmitted: (_) => _nextStep(),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          const Text(
            'This amount will be credited to your Main Account (Federal Bank)',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCashPaymentStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cash Payment',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cashPaymentController,
            focusNode: _focusNodes[7],
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*')),
            ],
            decoration: const InputDecoration(
              labelText: 'Cash Payment (₹)',
              hintText: 'Enter cash payment amount',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.money),
            ),
            onChanged: (_) => _calculateMetrics(),
            onFieldSubmitted: (_) => _nextStep(),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          const Text(
            'This amount will be credited to your Cash Wallet',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformPaymentStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Platform Payment',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _platformPaymentController,
            focusNode: _focusNodes[8],
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*')),
            ],
            decoration: const InputDecoration(
              labelText: 'Platform Payment (₹)',
              hintText: 'Enter platform payment amount',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.account_balance_wallet),
            ),
            onChanged: (_) => _calculateMetrics(),
            onFieldSubmitted: (_) => _nextStep(),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16),
          const Text(
            'This amount will be credited to your Platform Wallets',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsStep() {
    _calculateMetrics();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ride Statistics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatRow('Tips', '₹${_tip.toStringAsFixed(2)}', Colors.orange),
                  _buildStatRow('Profit', '₹${_profit.toStringAsFixed(2)}', Colors.green),
                  _buildStatRow('Fuel Allocation', '₹${_fuelAllocation.toStringAsFixed(2)}', Colors.blue),
                  _buildStatRow('Profit Per KM', '₹${_profitPerKm.toStringAsFixed(2)}', Colors.purple),
                  _buildStatRow('Profit Per Min', '₹${_profitPerMin.toStringAsFixed(2)}', Colors.red),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ride Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text('From: ${widget.ride.startLocality}'),
                  Text('To: ${widget.endLocality ?? widget.ride.endLocality ?? "Unknown"}'),
                  Text('Duration: ${widget.ride.getDurationString()}'),
                  Text('Distance: ${_kmController.text} KM'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;

  // Check current connectivity status
  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result == ConnectivityResult.mobile ||
             result == ConnectivityResult.wifi ||
             result == ConnectivityResult.ethernet;
    } catch (e) {
      return false;
    }
  }

  // Stream of connectivity changes as ConnectivityResult
  Stream<ConnectivityResult> get connectivityStream => _connectivity.onConnectivityChanged;

  // Stream of connectivity changes as boolean
  Stream<bool> get connectivityStreamBool {
    return _connectivity.onConnectivityChanged.map((result) {
      return result == ConnectivityResult.mobile ||
             result == ConnectivityResult.wifi ||
             result == ConnectivityResult.ethernet;
    });
  }

  // Dispose
  void dispose() {
    _subscription?.cancel();
  }
}


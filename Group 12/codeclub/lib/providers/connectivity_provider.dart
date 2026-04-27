import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/services/connectivity_service.dart';

/// Connectivity provider for managing internet connection status
class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityService _connectivityService = ConnectivityService();

  bool _isConnected = true;
  bool _isInitialized = false;
  ConnectivityResult _currentStatus = ConnectivityResult.wifi;

  bool get isConnected => _isConnected;
  bool get isInitialized => _isInitialized;
  ConnectivityResult get currentStatus => _currentStatus;

  ConnectivityProvider() {
    _initializeConnectivity();
  }

  /// Initialize connectivity and listen to changes
  Future<void> _initializeConnectivity() async {
    try {
      // Check initial connection status
      _currentStatus = await _connectivityService.getConnectivityStatus();
      _isConnected = _currentStatus != ConnectivityResult.none;
      _isInitialized = true;
      _safeNotifyListeners();

      // Listen to connectivity changes
      _connectivityService.getConnectivityStream().listen((result) {
        _currentStatus = result;
        _isConnected = result != ConnectivityResult.none;
        if (kDebugMode) print('Connectivity changed: $_isConnected (${result.toString()})');
        _safeNotifyListeners();
      });
    } catch (e) {
      if (kDebugMode) print('Error initializing connectivity: $e');
      _isInitialized = true;
      _safeNotifyListeners();
    }
  }

  /// Refresh connectivity status manually
  Future<void> refreshConnectivityStatus() async {
    try {
      _currentStatus = await _connectivityService.getConnectivityStatus();
      _isConnected = _currentStatus != ConnectivityResult.none;
      _safeNotifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error refreshing connectivity: $e');
    }
  }

  /// Safe notify listeners to prevent errors after dispose
  void _safeNotifyListeners() {
    if (!hasListeners) return;
    try {
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error notifying listeners: $e');
    }
  }
}

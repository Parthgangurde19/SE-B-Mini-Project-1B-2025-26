import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  
  final Connectivity _connectivity = Connectivity();

  ConnectivityService._internal();

  factory ConnectivityService() {
    return _instance;
  }

  /// Check if device has internet connection
  Future<bool> hasInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.isNotEmpty && !results.contains(ConnectivityResult.none);
    } catch (e) {
      if (kDebugMode) print('Error checking connectivity: $e');
      return false;
    }
  }

  /// Get the current connectivity status (returns first result or none)
  Future<ConnectivityResult> getConnectivityStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.isNotEmpty ? results.first : ConnectivityResult.none;
    } catch (e) {
      if (kDebugMode) print('Error getting connectivity status: $e');
      return ConnectivityResult.none;
    }
  }

  /// Listen to connectivity changes
  Stream<ConnectivityResult> getConnectivityStream() {
    return _connectivity.onConnectivityChanged.map((results) {
      return results.isNotEmpty ? results.first : ConnectivityResult.none;
    });
  }

  /// Check if the connection is WiFi
  Future<bool> isWiFiConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.wifi);
    } catch (e) {
      if (kDebugMode) print('Error checking WiFi: $e');
      return false;
    }
  }

  /// Check if the connection is mobile data
  Future<bool> isMobileDataConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.mobile);
    } catch (e) {
      if (kDebugMode) print('Error checking mobile data: $e');
      return false;
    }
  }
}

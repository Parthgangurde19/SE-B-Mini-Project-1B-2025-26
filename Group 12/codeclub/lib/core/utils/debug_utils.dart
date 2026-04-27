import 'package:flutter/foundation.dart';

/// Debug utilities for CodeClub
class DebugUtils {
  DebugUtils._();

  /// Print debug message only in debug mode
  static void debugPrint(String message, [String? tag]) {
    if (kDebugMode) {
      final debugTag = tag != null ? '[$tag] ' : '[DEBUG] ';
      print('$debugTag$message');
    }
  }

  /// Print error message
  static void debugError(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('[ERROR] $message');
      if (error != null) {
        print('[ERROR] Error: $error');
      }
      if (stackTrace != null) {
        print('[ERROR] StackTrace: $stackTrace');
      }
    }
  }

  /// Print Firestore operation
  static void debugFirestore(String operation, String collection, [String? docId]) {
    if (kDebugMode) {
      final doc = docId != null ? '/$docId' : '';
      print('[FIRESTORE] $operation: $collection$doc');
    }
  }
}
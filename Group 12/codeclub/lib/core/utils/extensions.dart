import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Extension methods for common operations
extension StringExtensions on String {
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize each word
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Get initials from name
  String get initials {
    if (isEmpty) return '';
    final words = trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return words[0][0].toUpperCase();
  }
}

extension DateTimeExtensions on DateTime {
  /// Format as readable date
  String get formattedDate {
    return DateFormat('MMM dd, yyyy').format(this);
  }

  /// Format as time
  String get formattedTime {
    return DateFormat('hh:mm a').format(this);
  }

  /// Format date as short string (Jan 1, 2024)
  String get formatDateShort {
    return DateFormat('MMM d, yyyy').format(this);
  }

  /// Format date as full string (Monday, January 1, 2024)
  String get formatDateFull {
    return DateFormat('EEEE, MMMM d, yyyy').format(this);
  }

  /// Format time as HH:MM AM/PM
  String get formatTime {
    return DateFormat('h:mm a').format(this);
  }

  /// Format as date and time
  String get formattedDateTime {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(this);
  }

  /// Format as relative time (e.g., "2 hours ago")
  String get timeAgo {
    return timeago.format(this);
  }

  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && 
           month == yesterday.month && 
           day == yesterday.day;
  }

  /// Smart format for chat messages
  String get chatTimeFormat {
    if (isToday) {
      return formattedTime;
    } else if (isYesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd').format(this);
    }
  }
}

extension ContextExtensions on BuildContext {
  /// Get theme
  ThemeData get theme => Theme.of(this);

  /// Get text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Check if dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Get screen size
  Size get screenSize => MediaQuery.of(this).size;

  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Get safe area padding
  EdgeInsets get padding => MediaQuery.of(this).padding;

  /// Show snackbar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show loading dialog
  void showLoadingDialog({String? message}) {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(message),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Hide loading dialog
  void hideLoadingDialog() {
    Navigator.of(this).pop();
  }
}

extension ListExtensions<T> on List<T> {
  /// Safely get element at index
  T? safeGet(int index) {
    if (index >= 0 && index < length) {
      return this[index];
    }
    return null;
  }
}

import 'package:email_validator/email_validator.dart';
import '../constants/app_constants.dart';

/// Form validation utilities for CodeClub
class Validators {
  Validators._();

  /// Validate email format and domain
  /// Only allows @apsit.edu.in emails
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    if (!EmailValidator.validate(value)) {
      return 'Please enter a valid email address';
    }
    
    if (!value.toLowerCase().endsWith(AppConstants.allowedEmailDomain)) {
      return AppConstants.invalidEmailDomain;
    }
    
    return null;
  }

  /// Validate password
  /// Minimum 6 characters
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }

  /// Validate confirm password
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate name (letters and spaces only)
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }
    
    return null;
  }

  /// Validate team name
  static String? validateTeamName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Team name is required';
    }
    
    if (value.length < 3) {
      return 'Team name must be at least 3 characters';
    }
    
    if (value.length > 30) {
      return 'Team name cannot exceed 30 characters';
    }
    
    return null;
  }

  /// Validate bio (optional but with max length)
  static String? validateBio(String? value) {
    if (value != null && value.length > 200) {
      return 'Bio cannot exceed 200 characters';
    }
    return null;
  }
}

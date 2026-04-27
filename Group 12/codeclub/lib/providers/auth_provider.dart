import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/services/auth_service.dart';
import '../data/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart' hide FirebaseAuthException;

/// Authentication state provider
enum AuthState { initial, authenticated, unauthenticated, loading }

/// Auth provider for managing authentication state
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  AuthState _authState = AuthState.initial;
  UserModel? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;
  Timer? _notificationDebouncer;
  StreamSubscription? _authStateSubscription;

  // Getters
  AuthState get authState => _authState;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _authState == AuthState.authenticated;
  bool get isProfileComplete => _currentUser?.isProfileComplete ?? false;
  String? get currentUserId => _authService.currentUserId;

  AuthProvider() {
    _init();
  }

  /// Initialize auth state
  void _init() {
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAuthListener();
      _checkExistingUser();
    });
  }

  /// Setup auth state change listener
  void _setupAuthListener() {
    _authStateSubscription = _authService.authStateChanges.listen((
      User? user,
    ) async {
      try {
        if (user != null) {
          _authState = AuthState.authenticated;
          await _loadUserProfile();
        } else {
          _currentUser = null;
          _authState = AuthState.unauthenticated;
        }
        _debouncedNotifyListeners();
      } catch (e) {
        _errorMessage = e.toString();
        _authState = AuthState.unauthenticated;
        _debouncedNotifyListeners();
      }
    });
  }

  /// Check for existing user session on app startup
  Future<void> _checkExistingUser() async {
    if (_authService.currentUser != null) {
      try {
        _authState = AuthState.authenticated;
        await _loadUserProfile();
        _debouncedNotifyListeners();
      } catch (e) {
        _errorMessage = e.toString();
        _authState = AuthState.unauthenticated;
        _debouncedNotifyListeners();
      }
    } else {
      // No user found, set state to unauthenticated
      _authState = AuthState.unauthenticated;
      _debouncedNotifyListeners();
    }
  }

  /// Load current user profile
  Future<void> _loadUserProfile() async {
    try {
      _currentUser = await _authService.getCurrentUserProfile();
      if (_currentUser == null && _authService.currentUserId != null) {
        // Profile doesn't exist yet, create a basic one
        print('User profile not found in Firestore, user might need to complete profile');
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('Error loading user profile: $e');
    }
  }

  /// Refresh user profile
  Future<void> refreshUserProfile() async {
    if (_authService.currentUserId == null) {
      _currentUser = null;
      return;
    }
    await _loadUserProfile();
    _debouncedNotifyListeners();
  }

  /// Sign up
  Future<bool> signUp({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    _debouncedNotifyListeners();

    try {
      await _authService.signUp(email: email, password: password);
      await _loadUserProfile();
      _isLoading = false;
      _debouncedNotifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.userMessage;
      _isLoading = false;
      _debouncedNotifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _debouncedNotifyListeners();
      return false;
    }
  }

  /// Sign in
  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    _debouncedNotifyListeners();

    try {
      await _authService.signIn(email: email, password: password);
      await _loadUserProfile();
      _isLoading = false;
      _debouncedNotifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.userMessage;
      _isLoading = false;
      _debouncedNotifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _debouncedNotifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading = true;
    _debouncedNotifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
      _authState = AuthState.unauthenticated;
      print('Sign out successful - auth state: $_authState');
    } catch (e) {
      _errorMessage = e.toString();
      print('Sign out error: $e');
    }

    _isLoading = false;
    // Cancel any pending debounced notification and notify immediately
    _notificationDebouncer?.cancel();
    print('Calling notifyListeners from signOut');
    notifyListeners();
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    _debouncedNotifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      _debouncedNotifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.userMessage;
      _isLoading = false;
      _debouncedNotifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _debouncedNotifyListeners();
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile(UserModel updatedUser) async {
    _isLoading = true;
    _errorMessage = null;
    _debouncedNotifyListeners();

    try {
      await _userService.updateUserProfile(updatedUser);
      _currentUser = updatedUser;
      _isLoading = false;
      _debouncedNotifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _debouncedNotifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    _debouncedNotifyListeners();
  }

  /// Debounced notify listeners to prevent excessive rebuilds
  void _debouncedNotifyListeners() {
    _notificationDebouncer?.cancel();
    _notificationDebouncer = Timer(const Duration(milliseconds: 50), () {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _notificationDebouncer?.cancel();
    _authStateSubscription?.cancel();
    super.dispose();
  }
}

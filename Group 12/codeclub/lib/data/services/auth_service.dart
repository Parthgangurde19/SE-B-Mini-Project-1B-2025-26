import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

/// Authentication service for CodeClub
/// Handles Firebase Auth operations with APSIT email domain restriction
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Validate if email is from APSIT domain
  bool _isValidAPSITEmail(String email) {
    // Allow Gmail for testing - remove this in production
    if (email.toLowerCase().endsWith('@gmail.com')) {
      return true;
    }
    return email.toLowerCase().endsWith(AppConstants.allowedEmailDomain);
  }

  /// Sign up with email and password
  /// Returns the created user or throws an exception
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    // Validate email domain
    if (!_isValidAPSITEmail(email)) {
      throw FirebaseAuthException(
        code: 'invalid-email-domain',
        message: AppConstants.invalidEmailDomain,
      );
    }

    try {
      // Create user with Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      if (credential.user != null) {
        final user = UserModel.empty(credential.user!.uid, email);
        try {
          await _firestore
              .collection('users')
              .doc(credential.user!.uid)
              .set(user.toFirestore(), SetOptions(merge: true));
        } catch (e) {
          final errorMsg = e.toString().toLowerCase();
          // Check if it's a network error
          if (errorMsg.contains('network') || 
              errorMsg.contains('unreachable') || 
              errorMsg.contains('timeout') ||
              errorMsg.contains('internet') ||
              errorMsg.contains('connection')) {
            await credential.user!.delete();
            throw FirebaseAuthException(
              code: 'network-request-failed',
              message: 'Network error: $e',
            );
          }
          // If Firestore fails for other reasons, delete the created user account
          await credential.user!.delete();
          throw FirebaseAuthException(
            code: 'signup-failed',
            message: 'Failed to create user profile: $e',
          );
        }
      }

      return credential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'signup-failed',
        message: e.toString(),
      );
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    // Validate email domain
    if (!_isValidAPSITEmail(email)) {
      throw FirebaseAuthException(
        code: 'invalid-email-domain',
        message: AppConstants.invalidEmailDomain,
      );
    }

    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'signin-failed',
        message: e.toString(),
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    // Validate email domain
    if (!_isValidAPSITEmail(email)) {
      throw FirebaseAuthException(
        code: 'invalid-email-domain',
        message: AppConstants.invalidEmailDomain,
      );
    }

    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Get user profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    if (currentUserId == null) return null;
    return getUserProfile(currentUserId!);
  }

  /// Stream of current user profile
  Stream<UserModel?> get currentUserProfileStream {
    if (currentUserId == null) {
      return Stream.value(null);
    }
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  /// Check if user profile is complete
  Future<bool> isProfileComplete() async {
    final profile = await getCurrentUserProfile();
    return profile?.isProfileComplete ?? false;
  }
}

/// Custom Firebase Auth Exception
class FirebaseAuthException implements Exception {
  final String code;
  final String message;

  FirebaseAuthException({required this.code, required this.message});

  @override
  String toString() => message;

  /// Get user-friendly error message
  String get userMessage {
    switch (code) {
      case 'invalid-email-domain':
        return message;
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return AppConstants.networkError;
      case 'signup-failed':
        // Check if it's a Firestore permission error
        if (message.contains('permission') || message.contains('Permission')) {
          return 'Unable to create account profile. Please check your internet connection and try again.';
        }
        return 'Failed to create account. Please try again.';
      case 'operation-not-allowed':
        return 'Account creation is not enabled. Please contact support.';
      default:
        return AppConstants.unknownError;
    }
  }
}

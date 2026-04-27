import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get loyaltyPoints => _currentUser?.loyaltyPoints ?? 0;
  bool get freeItemReady => _currentUser?.freeItemReady ?? false;

  AuthProvider() {
    _auth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser == null) {
        _currentUser = null;
        notifyListeners();
      } else {
        await _fetchUserData(firebaseUser.uid, firebaseUser.email!);
      }
    });
  }

  StreamSubscription<DocumentSnapshot>? _userDocSub;

  Future<void> _fetchUserData(String uid, String email) async {
    final isAdminEmail = email.toLowerCase() == 'admin@coffee.com';

    _currentUser = User(
      id: uid,
      name: email.split('@').first,
      email: email,
      password: '',
      role: isAdminEmail ? 'admin' : 'customer',
    );
    notifyListeners();

    _userDocSub?.cancel();
    _userDocSub = _firestore.collection('users').doc(uid).snapshots().listen((doc) async {
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        if (isAdminEmail) data['role'] = 'admin';
        _currentUser = User.fromMap(data);
        notifyListeners();
      } else {
        // Only initialize if the doc is truly missing and signup didn't write it yet.
        // We use 'customer' explicitly here to avoid any admin defaults.
        final userMap = {
          'name': _currentUser!.name,
          'email': _currentUser!.email,
          'role': isAdminEmail ? 'admin' : 'customer',
          'loyaltyPoints': 0,
          'freeItemReady': false,
          'orderFrequency': {},
        };
        await _firestore.collection('users').doc(uid).set(userMap);
      }
    }, onError: (e) {
      if (kDebugMode) print('Error in user doc stream: $e');
    });
  }

  /// Refreshes loyalty data from Firestore after an order is placed.
  Future<void> refreshUser() async {
    final uid = _auth.currentUser?.uid;
    final email = _auth.currentUser?.email;
    if (uid == null || email == null) return;
    await _fetchUserData(uid, email);
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await _fetchUserData(userCredential.user!.uid, userCredential.user!.email!);
        _isLoading = false;
        return true;
      }
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if ((email.toLowerCase() == 'admin@coffee.com') &&
          password == '123456' &&
          (e.code == 'user-not-found' ||
              e.code == 'invalid-credential' ||
              e.code == 'INVALID_LOGIN_CREDENTIALS')) {
        return await signup('Admin', email, password, 'admin');
      }
      _isLoading = false;
      _error = e.message ?? 'Login failed. Please check your credentials.';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'An unexpected error occurred: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup(String name, String email, String password, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCredential.user!.uid;
      final userMap = {
        'name': name,
        'email': email,
        'role': role,
        'loyaltyPoints': 0,
        'freeItemReady': false,
        'orderFrequency': {},
      };
      await _firestore.collection('users').doc(uid).set(userMap);
      userMap['id'] = uid;
      userMap['password'] = '';
      _currentUser = User.fromMap(userMap);
      _isLoading = false;
      notifyListeners();
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = e.message ?? 'Signup failed. Please try again.';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'An unexpected error occurred: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      _userDocSub?.cancel();
      _userDocSub = null;
      await _auth.signOut();
      _currentUser = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Error logging out: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Admin Initialization Service
/// Use this to set up the default admin account (admin@apsit.edu.in)
class AdminInitService {
  static const String adminEmail = 'admin@apsit.edu.in';
  static const String adminPassword = 'Admin@123'; // Change this in production
  static const String adminName = 'Admin User';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize default admin account
  /// Returns true if successful, false otherwise
  Future<bool> initializeAdminAccount() async {
    try {
      // Check if admin already exists
      final adminDoc = await _firestore
          .collection('users')
          .where('email', isEqualTo: adminEmail)
          .limit(1)
          .get();

      if (adminDoc.docs.isNotEmpty) {
        print('Admin account already exists');
        return true;
      }

      // Create Firebase Auth user
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      final uid = userCred.user!.uid;

      // Create admin user document in Firestore
      final adminUser = UserModel(
        uid: uid,
        email: adminEmail,
        fullName: adminName,
        branch: 'Administration',
        year: 'Faculty',
        skills: ['Admin'],
        role: 'admin', // KEY: Set role as admin
        bio: 'System Administrator',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isProfileComplete: true,
      );

      await _firestore
          .collection('users')
          .doc(uid)
          .set(adminUser.toFirestore());

      print('✅ Admin account created successfully!');
      print('Email: $adminEmail');
      print('Password: $adminPassword');
      print('UID: $uid');

      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print('⚠️  Email already exists. Updating role to admin...');
        return await _updateExistingUserToAdmin(adminEmail);
      }
      print('❌ Error creating admin: ${e.message}');
      return false;
    } catch (e) {
      print('❌ Error: $e');
      return false;
    }
  }

  /// Update an existing user to admin
  Future<bool> _updateExistingUserToAdmin(String email) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) {
        print('❌ User not found');
        return false;
      }

      final uid = userDoc.docs.first.id;
      await _firestore.collection('users').doc(uid).update({
        'role': 'admin',
        'updatedAt': Timestamp.now(),
      });

      print('✅ User updated to admin!');
      print('Email: $email');
      print('UID: $uid');
      return true;
    } catch (e) {
      print('❌ Error updating user: $e');
      return false;
    }
  }

  /// Get admin credentials (for reference)
  static Map<String, String> getAdminCredentials() {
    return {
      'email': adminEmail,
      'password': adminPassword,
      'name': adminName,
    };
  }

  /// Print admin credentials to console
  static void printAdminCredentials() {
    print('');
    print('═══════════════════════════════════════');
    print('     📱 ADMIN LOGIN CREDENTIALS');
    print('═══════════════════════════════════════');
    print('Email:    $adminEmail');
    print('Password: $adminPassword');
    print('Name:     $adminName');
    print('═══════════════════════════════════════');
    print('');
  }
}

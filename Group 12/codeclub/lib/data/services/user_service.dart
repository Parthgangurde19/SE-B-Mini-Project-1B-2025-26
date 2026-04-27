import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../core/utils/debug_utils.dart';

/// User service for CodeClub
/// Handles all user-related Firestore operations
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Get user by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      DebugUtils.debugFirestore('GET', 'users', uid);
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        DebugUtils.debugPrint('Successfully retrieved user: ${doc.data()?['fullName']}', 'UserService');
        return UserModel.fromFirestore(doc);
      }
      DebugUtils.debugPrint('User not found: $uid', 'UserService');
      return null;
    } catch (e) {
      DebugUtils.debugError('Error getting user by ID: $uid', e);
      rethrow;
    }
  }

  /// Get user stream
  Stream<UserModel?> getUserStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map(
          (doc) => doc.exists ? UserModel.fromFirestore(doc) : null,
        );
  }

  /// Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      DebugUtils.debugFirestore('UPDATE', 'users', user.uid);
      DebugUtils.debugPrint('Updating profile for: ${user.fullName}', 'UserService');
      
      await _usersCollection.doc(user.uid).set(
        user.toFirestore(),
        SetOptions(merge: true),
      );
      
      DebugUtils.debugPrint('Profile updated successfully', 'UserService');
    } catch (e) {
      DebugUtils.debugError('Error updating user profile: ${user.uid}', e);
      rethrow;
    }
  }

  /// Get all users (for finding team members)
  Future<List<UserModel>> getAllUsers({
    String? excludeUserId,
    List<String>? excludeUserIds,
  }) async {
    try {
      // Use a simple query that doesn't require custom indexes
      Query query = _usersCollection;
      
      // Add the isProfileComplete filter
      query = query.where('isProfileComplete', isEqualTo: true);
      
      // Limit the results to avoid large queries
      query = query.limit(100);
      
      final snapshot = await query.get();
      
      final excludeIds = <String>{};
      if (excludeUserId != null) excludeIds.add(excludeUserId);
      if (excludeUserIds != null) excludeIds.addAll(excludeUserIds);
      
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => !excludeIds.contains(user.uid))
          .toList();
    } catch (e) {
      print('Error getting all users: $e');
      // If the query fails due to missing index, try without complex filtering
      try {
        final simpleQuery = await _usersCollection.limit(50).get();
        final excludeIds = <String>{};
        if (excludeUserId != null) excludeIds.add(excludeUserId);
        if (excludeUserIds != null) excludeIds.addAll(excludeUserIds);
        
        return simpleQuery.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .where((user) => user.isProfileComplete && !excludeIds.contains(user.uid))
            .toList();
      } catch (e2) {
        print('Error with fallback query: $e2');
        return [];
      }
    }
  }

  /// Search users by name or skill
  /// Optimized: Pre-computes lowercase query once, uses Set for O(1) skill lookup
  Future<List<UserModel>> searchUsers({
    String? query,
    String? skill,
    String? role,
    String? year,
    String? excludeUserId,
  }) async {
    try {
      // Get all users first, then filter in memory
      // This is a simple approach; for production, consider using Algolia or similar
      final users = await getAllUsers(excludeUserId: excludeUserId);
      
      // Pre-compute lowercase values once (O(1) instead of O(n))
      final queryLower = query?.toLowerCase();
      final skillLower = skill?.toLowerCase();
      final roleLower = role?.toLowerCase();
      final yearLower = year?.toLowerCase();
      
      return users.where((user) {
        // Filter by query (name search) - use pre-computed lowercase
        if (queryLower != null && queryLower.isNotEmpty) {
          final nameLower = user.fullName.toLowerCase();
          final emailLower = user.email.toLowerCase();
          if (!nameLower.contains(queryLower) &&
              !emailLower.contains(queryLower)) {
            return false;
          }
        }
        
        // Filter by skill - convert skills to lowercase Set for O(1) lookup
        if (skillLower != null && skillLower.isNotEmpty) {
          final skillsLowerSet = user.skills.map((s) => s.toLowerCase()).toSet();
          if (!skillsLowerSet.contains(skillLower)) {
            return false;
          }
        }
        
        // Filter by role
        if (roleLower != null && roleLower.isNotEmpty) {
          if (user.role.toLowerCase() != roleLower) {
            return false;
          }
        }
        
        // Filter by year
        if (yearLower != null && yearLower.isNotEmpty) {
          if (user.year.toLowerCase() != yearLower) {
            return false;
          }
        }
        
        return true;
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get users by IDs
  Future<List<UserModel>> getUsersByIds(List<String> uids) async {
    if (uids.isEmpty) return [];
    
    try {
      final users = <UserModel>[];
      
      // Firestore 'whereIn' has a limit of 10 items
      // So we batch the requests
      for (var i = 0; i < uids.length; i += 10) {
        final batch = uids.sublist(
          i,
          i + 10 > uids.length ? uids.length : i + 10,
        );
        
        final snapshot = await _usersCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        users.addAll(
          snapshot.docs.map((doc) => UserModel.fromFirestore(doc)),
        );
      }
      
      return users;
    } catch (e) {
      rethrow;
    }
  }

  /// Update user's current team
  Future<void> updateUserTeam(String uid, String? teamId) async {
    try {
      await _usersCollection.doc(uid).update({
        'currentTeamId': teamId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }
}

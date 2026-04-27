import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/admin_model.dart';
import '../models/hackathon_model.dart';

class AdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _admins =>
      _firestore.collection('admins');
  CollectionReference<Map<String, dynamic>> get _adminLegacy =>
      _firestore.collection('admin');
  CollectionReference<Map<String, dynamic>> get _hackathons =>
      _firestore.collection('hackathons');

  HackathonModel? _safeHackathonFromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    try {
      return HackathonModel.fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AdminService: Skipping malformed hackathon ${doc.id}: $e');
      }
      return null;
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _getAdminDoc(String uid) async {
    final adminsDoc = await _admins.doc(uid).get();
    if (adminsDoc.exists) {
      return adminsDoc;
    }

    final legacyDoc = await _adminLegacy.doc(uid).get();
    if (legacyDoc.exists) {
      return legacyDoc;
    }

    return null;
  }

  Future<AdminModel?> signInAdmin(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Unable to sign in as admin. Please try again.');
      }

      // Force refresh the token to get the latest custom claims
      final tokenResult = await user.getIdTokenResult(true);
      final isAdminClaim = tokenResult.claims?['admin'] == true;
      if (!isAdminClaim) {
        await signOutAdmin();
        throw Exception('You are not authorized as an admin.');
      }

      // Read admin document with explicit error handling
      final adminDoc = await _getAdminDoc(user.uid);
      if (adminDoc == null) {
        await signOutAdmin();
        throw Exception('Admin profile not found in Firestore. Please contact superadmin.');
      }

      final admin = AdminModel.fromFirestore(adminDoc);
      if (!admin.isActive) {
        await signOutAdmin();
        throw Exception('This admin account is currently disabled.');
      }

      // Update last login timestamp
      try {
        await adminDoc.reference.update({'lastLoginAt': FieldValue.serverTimestamp()});
      } catch (e) {
        // If update fails, don't block the login
        if (kDebugMode) {
          debugPrint('Warning: Could not update lastLoginAt: $e');
        }
      }

      return admin;
    } catch (e) {
      await signOutAdmin();
      rethrow;
    }
  }

  Future<void> signOutAdmin() async {
    await _auth.signOut();
  }

  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }

    final tokenResult = await user.getIdTokenResult(true);
    if (tokenResult.claims?['admin'] != true) {
      return false;
    }

    final adminDoc = await _getAdminDoc(user.uid);
    if (adminDoc == null) {
      return false;
    }

    final admin = AdminModel.fromFirestore(adminDoc);
    return admin.isActive;
  }

  Future<AdminModel?> getCurrentAdmin() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    if (!await isCurrentUserAdmin()) {
      return null;
    }

    final adminDoc = await _getAdminDoc(user.uid);
    if (adminDoc == null) {
      return null;
    }

    return AdminModel.fromFirestore(adminDoc);
  }

  Stream<AdminModel?> adminAuthStateChanges() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        return null;
      }

      final tokenResult = await user.getIdTokenResult(true);
      if (tokenResult.claims?['admin'] != true) {
        return null;
      }

      final doc = await _getAdminDoc(user.uid);
      if (doc == null) {
        return null;
      }

      final admin = AdminModel.fromFirestore(doc);
      if (!admin.isActive) {
        return null;
      }

      return admin;
    });
  }

  Future<AdminDashboardStats> getDashboardStats() async {
    final usersFuture = _firestore.collection('users').get();
    final teamsFuture = _firestore.collection('teams').get();
    final hackathonsFuture = _hackathons.get();

    final snapshots = await Future.wait([usersFuture, teamsFuture, hackathonsFuture]);

    final usersSnapshot = snapshots[0];
    final teamsSnapshot = snapshots[1];
    final hackathonsSnapshot = snapshots[2];

    int activeCount = 0;
    final validHackathons = <HackathonModel>[];

    for (final doc in hackathonsSnapshot.docs) {
      final model = _safeHackathonFromFirestore(doc);
      if (model == null) {
        continue;
      }
      validHackathons.add(model);
      if (model.isDeleted) {
        continue;
      }
      if (model.status == HackathonStatus.published ||
          model.status == HackathonStatus.ongoing) {
        activeCount++;
      }
    }

    return AdminDashboardStats(
      totalUsers: usersSnapshot.docs.length,
      totalTeams: teamsSnapshot.docs.length,
      totalHackathons: validHackathons.where((h) => !h.isDeleted).length,
      activeHackathons: activeCount,
    );
  }

  Stream<int> getTotalUsersStream() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getTotalTeamsStream() {
    return _firestore
        .collection('teams')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getActiveHackathonsStream() {
    return _hackathons
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(_safeHackathonFromFirestore)
            .whereType<HackathonModel>()
            .where((h) => !h.isDeleted && h.isActive)
            .length);
  }

  Future<String> createHackathon(HackathonModel hackathon, String adminId) async {
    final doc = _hackathons.doc();
    await doc.set({
      ...hackathon.copyWith(id: doc.id).toFirestore(),
      'createdByAdminId': adminId,
      'createdAt': FieldValue.serverTimestamp(),
      'isDeleted': false,
      'status': (hackathon.status).value,
      'isActive': hackathon.status == HackathonStatus.published ||
          hackathon.status == HackathonStatus.ongoing,
    });
    return doc.id;
  }

  Future<List<HackathonModel>> getAllHackathons({bool includeDeleted = false}) async {
    final snapshot = await _hackathons.get();
    final hackathons = snapshot.docs.map(_safeHackathonFromFirestore).whereType<HackathonModel>().where((h) {
      if (includeDeleted) {
        return true;
      }
      return !h.isDeleted;
    }).toList();

    hackathons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return hackathons;
  }

  Stream<List<HackathonModel>> getHackathonsStream({bool includeDeleted = false}) {
    return _hackathons.snapshots().map((snapshot) {
      final hackathons = snapshot.docs.map(_safeHackathonFromFirestore).whereType<HackathonModel>().where((h) {
        if (includeDeleted) {
          return true;
        }
        return !h.isDeleted;
      }).toList();

      hackathons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return hackathons;
    });
  }

  Future<HackathonModel?> getHackathonById(String hackathonId) async {
    final doc = await _hackathons.doc(hackathonId).get();
    if (!doc.exists) {
      return null;
    }
    return _safeHackathonFromFirestore(doc);
  }

  Future<void> updateHackathon(
    String hackathonId,
    Map<String, dynamic> data,
    String adminId,
  ) async {
    final mutable = Map<String, dynamic>.from(data);

    if (mutable.containsKey('status')) {
      final statusRaw = mutable['status'];
      final status = statusRaw is HackathonStatus
          ? statusRaw
          : hackathonStatusFromString(statusRaw?.toString());
      mutable['status'] = status.value;
      mutable['isActive'] =
          status == HackathonStatus.published || status == HackathonStatus.ongoing;
    }

    mutable['lastEditedByAdminId'] = adminId;
    mutable['lastEditedAt'] = FieldValue.serverTimestamp();

    await _hackathons.doc(hackathonId).update(mutable);
  }

  Future<void> toggleHackathonStatus(
    String hackathonId,
    HackathonStatus newStatus,
    String adminId,
  ) async {
    await _hackathons.doc(hackathonId).update({
      'status': newStatus.value,
      'isActive':
          newStatus == HackathonStatus.published || newStatus == HackathonStatus.ongoing,
      'lastEditedByAdminId': adminId,
      'lastEditedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> softDeleteHackathon(String hackathonId, String adminId) async {
    await _hackathons.doc(hackathonId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'status': HackathonStatus.cancelled.value,
      'isActive': false,
      'lastEditedByAdminId': adminId,
      'lastEditedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> permanentlyDeleteHackathon(String hackathonId) async {
    await deleteHackathonBanner(hackathonId);
    await _hackathons.doc(hackathonId).delete();
  }

  Future<String> uploadHackathonBanner(String hackathonId, XFile imageFile) async {
    final ref = _storage.ref().child('hackathons/$hackathonId/banner.jpg');
    final bytes = await imageFile.readAsBytes();
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<void> deleteHackathonBanner(String hackathonId) async {
    try {
      final ref = _storage.ref().child('hackathons/$hackathonId/banner.jpg');
      await ref.delete();
    } catch (_) {
      // Ignore if no banner exists.
    }
  }
}


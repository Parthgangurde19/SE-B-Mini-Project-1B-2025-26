import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/hackathon_model.dart';

/// Hackathon service for CodeClub
/// Handles all hackathon-related Firestore operations
class HackathonService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _hackathonsCollection =>
      _firestore.collection('hackathons');

  HackathonModel? _safeHackathonFromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    try {
      return HackathonModel.fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HackathonService: Skipping malformed hackathon ${doc.id}: $e');
      }
      return null;
    }
  }

  // ==================== HACKATHON OPERATIONS ====================

  /// Get all hackathons
  Future<List<HackathonModel>> getAllHackathons() async {
    try {
      final snapshot = await _hackathonsCollection
          .orderBy('startDate', descending: false)
          .get();

      return snapshot.docs
          .map(_safeHackathonFromFirestore)
          .whereType<HackathonModel>()
          .where((h) => h.isVisibleToStudents)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get upcoming hackathons
  Future<List<HackathonModel>> getUpcomingHackathons() async {
    try {
      final now = DateTime.now();
      final all = await getAllHackathons();
      return all
          .where((h) => h.startDate.isAfter(now))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get ongoing hackathons
  Future<List<HackathonModel>> getOngoingHackathons() async {
    try {
      final now = DateTime.now();
      final allHackathons = await getAllHackathons();
      
      return allHackathons
          .where((h) => h.startDate.isBefore(now) && h.endDate.isAfter(now))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get hackathon by ID
  Future<HackathonModel?> getHackathonById(String hackathonId) async {
    try {
      final doc = await _hackathonsCollection.doc(hackathonId).get();
      if (doc.exists) {
        return _safeHackathonFromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Stream of hackathons
  Stream<List<HackathonModel>> getHackathonsStream() {
    return _hackathonsCollection
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map(_safeHackathonFromFirestore)
        .whereType<HackathonModel>()
            .where((h) => h.isVisibleToStudents)
            .toList());
  }

  // ==================== ADMIN OPERATIONS ====================

  /// Create hackathon (Admin only)
  Future<HackathonModel> createHackathon(HackathonModel hackathon) async {
    try {
      final doc = _hackathonsCollection.doc();
      final newHackathon = hackathon.copyWith(id: doc.id);
      await doc.set(newHackathon.toFirestore());
      return newHackathon;
    } catch (e) {
      rethrow;
    }
  }

  /// Update hackathon (Admin only)
  Future<void> updateHackathon(HackathonModel hackathon) async {
    try {
      await _hackathonsCollection.doc(hackathon.id).update(hackathon.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  /// Delete hackathon (Admin only)
  Future<void> deleteHackathon(String hackathonId) async {
    try {
      await _hackathonsCollection.doc(hackathonId).delete();
    } catch (e) {
      rethrow;
    }
  }
}

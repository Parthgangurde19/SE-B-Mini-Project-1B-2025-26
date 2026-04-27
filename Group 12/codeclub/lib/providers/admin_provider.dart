import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/models/admin_model.dart';
import '../data/models/hackathon_model.dart';
import '../data/services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  AdminModel? _currentAdmin;
  AdminDashboardStats? _dashStats;
  List<HackathonModel> _hackathons = <HackathonModel>[];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  HackathonStatus? _filterStatus;
  String _searchQuery = '';

  AdminModel? get currentAdmin => _currentAdmin;
  AdminDashboardStats? get dashStats => _dashStats;
  List<HackathonModel> get hackathons => _hackathons;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  HackathonStatus? get filterStatus => _filterStatus;
  bool get isAuthenticated => _currentAdmin != null;

  List<HackathonModel> get filteredHackathons {
    var list = List<HackathonModel>.from(_hackathons);

    if (_filterStatus != null) {
      list = list.where((h) => h.status == _filterStatus).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      list = list
          .where((h) =>
              h.title.toLowerCase().contains(query) ||
              h.venue.toLowerCase().contains(query))
          .toList();
    }

    return list;
  }

  Stream<int> get totalUsersStream => _adminService.getTotalUsersStream();
  Stream<int> get totalTeamsStream => _adminService.getTotalTeamsStream();
  Stream<int> get activeHackathonsStream => _adminService.getActiveHackathonsStream();

  Future<void> _refreshAdminData({bool includeDeleted = false}) async {
    await loadAllHackathons(includeDeleted: includeDeleted);
    await loadDashboardStats();
  }

  Future<void> initializeAdminState() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentAdmin = await _adminService.getCurrentAdmin();
      if (_currentAdmin != null) {
        await _refreshAdminData();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInAdmin(String email, String password) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentAdmin = await _adminService.signInAdmin(email, password);
      await _refreshAdminData();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> signOutAdmin() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _adminService.signOutAdmin();
      _currentAdmin = null;
      _dashStats = null;
      _hackathons = <HackathonModel>[];
      _filterStatus = null;
      _searchQuery = '';
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDashboardStats() async {
    try {
      _dashStats = await _adminService.getDashboardStats();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadAllHackathons({bool includeDeleted = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _hackathons = await _adminService.getAllHackathons(
        includeDeleted: includeDeleted,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createHackathon(HackathonModel model, XFile? bannerImage) async {
    final admin = _currentAdmin;
    if (admin == null) {
      throw Exception('Admin session not found. Please sign in again.');
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final id = await _adminService.createHackathon(model, admin.uid);
      if (bannerImage != null) {
        final imageUrl = await _adminService.uploadHackathonBanner(id, bannerImage);
        await _adminService.updateHackathon(
          id,
          {'imageUrl': imageUrl},
          admin.uid,
        );
      }
      await _refreshAdminData();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> updateHackathon(
    String id,
    Map<String, dynamic> data,
    XFile? newBanner,
  ) async {
    final admin = _currentAdmin;
    if (admin == null) {
      throw Exception('Admin session not found. Please sign in again.');
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (newBanner != null) {
        final imageUrl = await _adminService.uploadHackathonBanner(id, newBanner);
        data['imageUrl'] = imageUrl;
      }

      await _adminService.updateHackathon(id, data, admin.uid);
      await _refreshAdminData();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> deleteHackathon(String id) async {
    final admin = _currentAdmin;
    if (admin == null) {
      throw Exception('Admin session not found. Please sign in again.');
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      await _adminService.softDeleteHackathon(id, admin.uid);
      await _refreshAdminData();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> permanentDeleteHackathon(String id) async {
    if (_currentAdmin?.role != AdminRole.superadmin) {
      throw Exception('Only superadmin can permanently delete hackathons.');
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      await _adminService.permanentlyDeleteHackathon(id);
      await _refreshAdminData(includeDeleted: true);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> toggleStatus(String id, HackathonStatus status) async {
    final admin = _currentAdmin;
    if (admin == null) {
      throw Exception('Admin session not found. Please sign in again.');
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      await _adminService.toggleHackathonStatus(id, status, admin.uid);
      await _refreshAdminData();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void setFilter(HackathonStatus? status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

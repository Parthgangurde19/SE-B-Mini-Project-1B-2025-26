import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminRole {
  superadmin,
  admin,
}

AdminRole adminRoleFromString(String? value) {
  switch (value) {
    case 'superadmin':
      return AdminRole.superadmin;
    case 'admin':
      return AdminRole.admin;
    default:
      return AdminRole.admin;
  }
}

extension AdminRoleExtension on AdminRole {
  String get value {
    switch (this) {
      case AdminRole.superadmin:
        return 'superadmin';
      case AdminRole.admin:
        return 'admin';
    }
  }
}

class AdminModel {
  final String uid;
  final String email;
  final String displayName;
  final AdminRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const AdminModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory AdminModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return AdminModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: adminRoleFromString(data['role']),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role.value,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt':
          lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }

  AdminModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    AdminRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return AdminModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

class AdminDashboardStats {
  final int totalUsers;
  final int totalTeams;
  final int totalHackathons;
  final int activeHackathons;

  const AdminDashboardStats({
    required this.totalUsers,
    required this.totalTeams,
    required this.totalHackathons,
    required this.activeHackathons,
  });

  factory AdminDashboardStats.empty() {
    return const AdminDashboardStats(
      totalUsers: 0,
      totalTeams: 0,
      totalHackathons: 0,
      activeHackathons: 0,
    );
  }

  AdminDashboardStats copyWith({
    int? totalUsers,
    int? totalTeams,
    int? totalHackathons,
    int? activeHackathons,
  }) {
    return AdminDashboardStats(
      totalUsers: totalUsers ?? this.totalUsers,
      totalTeams: totalTeams ?? this.totalTeams,
      totalHackathons: totalHackathons ?? this.totalHackathons,
      activeHackathons: activeHackathons ?? this.activeHackathons,
    );
  }
}

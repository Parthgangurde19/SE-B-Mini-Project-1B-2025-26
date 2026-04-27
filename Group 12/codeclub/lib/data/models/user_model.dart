import 'package:cloud_firestore/cloud_firestore.dart';

/// User/Student model for CodeClub
class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String branch;
  final String year;
  final List<String> skills;
  final String role;
  final String bio;
  final String? profileImageUrl;
  final String? currentTeamId;
  final String? linkedInUrl;
  final String? githubUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isProfileComplete;
  final bool isAdmin;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.branch,
    required this.year,
    required this.skills,
    required this.role,
    required this.bio,
    this.profileImageUrl,
    this.currentTeamId,
    this.linkedInUrl,
    this.githubUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isProfileComplete = false,
    this.isAdmin = false,
  });

  /// Create empty user (for new signups)
  factory UserModel.empty(String uid, String email) {
    final now = DateTime.now();
    return UserModel(
      uid: uid,
      email: email,
      fullName: '',
      branch: '',
      year: '',
      skills: [],
      role: '',
      bio: '',
      createdAt: now,
      updatedAt: now,
      isProfileComplete: false,
      linkedInUrl: null,
      githubUrl: null,
      isAdmin: false,
    );
  }

  /// Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    String? readOptionalString(List<String> keys) {
      for (final key in keys) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      return null;
    }

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      branch: data['branch'] ?? '',
      year: data['year'] ?? '',
      skills: List<String>.from(data['skills'] ?? []),
      role: data['role'] ?? '',
      bio: data['bio'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      currentTeamId: data['currentTeamId'],
      linkedInUrl: readOptionalString([
        'linkedInUrl',
        'linkedinUrl',
        'linkedIn',
        'linkedin',
      ]),
      githubUrl: readOptionalString([
        'githubUrl',
        'gitHubUrl',
        'github',
      ]),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isProfileComplete: data['isProfileComplete'] ?? false,
      isAdmin: data['isAdmin'] ?? false,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'fullName': fullName,
      'branch': branch,
      'year': year,
      'skills': skills,
      'role': role,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'currentTeamId': currentTeamId,
      'linkedInUrl': linkedInUrl,
      'githubUrl': githubUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'isProfileComplete': isProfileComplete,
      'isAdmin': isAdmin,
    };
  }

  /// Copy with modifications
  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? branch,
    String? year,
    List<String>? skills,
    String? role,
    String? bio,
    String? profileImageUrl,
    String? currentTeamId,
    String? linkedInUrl,
    String? githubUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isProfileComplete,
    bool? isAdmin,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      branch: branch ?? this.branch,
      year: year ?? this.year,
      skills: skills ?? this.skills,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      currentTeamId: currentTeamId ?? this.currentTeamId,
      linkedInUrl: linkedInUrl ?? this.linkedInUrl,
      githubUrl: githubUrl ?? this.githubUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  /// Check if profile is complete for team finding
  bool get hasCompleteProfile {
    return fullName.isNotEmpty &&
        branch.isNotEmpty &&
        year.isNotEmpty &&
        skills.isNotEmpty &&
        role.isNotEmpty;
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, fullName: $fullName, role: $role)';
  }
}

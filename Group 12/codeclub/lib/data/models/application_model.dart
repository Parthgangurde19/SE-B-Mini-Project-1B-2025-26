import 'package:cloud_firestore/cloud_firestore.dart';

/// Application status enum
enum ApplicationStatus { pending, approved, rejected }

/// Application model for hackathon applications
class ApplicationModel {
  final String id;
  final String hackathonId;
  final String userId;
  final String? teamId;
  final String userName;
  final String? teamName;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? remarks;

  ApplicationModel({
    required this.id,
    required this.hackathonId,
    required this.userId,
    this.teamId,
    required this.userName,
    this.teamName,
    this.status = ApplicationStatus.pending,
    required this.appliedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.remarks,
  });

  /// Create from Firestore document
  factory ApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ApplicationModel(
      id: doc.id,
      hackathonId: data['hackathonId'] ?? '',
      userId: data['userId'] ?? '',
      teamId: data['teamId'],
      userName: data['userName'] ?? '',
      teamName: data['teamName'],
      status: _statusFromString(data['status'] ?? 'pending'),
      appliedAt:
          (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewedBy'],
      remarks: data['remarks'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'hackathonId': hackathonId,
      'userId': userId,
      'teamId': teamId,
      'userName': userName,
      'teamName': teamName,
      'status': status.name,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'remarks': remarks,
    };
  }

  /// Copy with modifications
  ApplicationModel copyWith({
    String? id,
    String? hackathonId,
    String? userId,
    String? teamId,
    String? userName,
    String? teamName,
    ApplicationStatus? status,
    DateTime? appliedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? remarks,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      hackathonId: hackathonId ?? this.hackathonId,
      userId: userId ?? this.userId,
      teamId: teamId ?? this.teamId,
      userName: userName ?? this.userName,
      teamName: teamName ?? this.teamName,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      remarks: remarks ?? this.remarks,
    );
  }

  /// Whether this is a team application
  bool get isTeamApplication => teamId != null && teamId!.isNotEmpty;

  /// Whether the application is still pending
  bool get isPending => status == ApplicationStatus.pending;

  /// Human-readable status label
  String get statusLabel {
    switch (status) {
      case ApplicationStatus.pending:
        return 'Pending';
      case ApplicationStatus.approved:
        return 'Approved';
      case ApplicationStatus.rejected:
        return 'Rejected';
    }
  }

  static ApplicationStatus _statusFromString(String value) {
    switch (value) {
      case 'approved':
        return ApplicationStatus.approved;
      case 'rejected':
        return ApplicationStatus.rejected;
      default:
        return ApplicationStatus.pending;
    }
  }

  @override
  String toString() =>
      'ApplicationModel(id: $id, hackathon: $hackathonId, user: $userName, status: $statusLabel)';
}

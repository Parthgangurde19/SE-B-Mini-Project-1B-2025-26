import 'package:cloud_firestore/cloud_firestore.dart';

enum HackathonStatus {
  draft,
  published,
  ongoing,
  completed,
  cancelled,
}

extension HackathonStatusExtension on HackathonStatus {
  String get value {
    switch (this) {
      case HackathonStatus.draft:
        return 'draft';
      case HackathonStatus.published:
        return 'published';
      case HackathonStatus.ongoing:
        return 'ongoing';
      case HackathonStatus.completed:
        return 'completed';
      case HackathonStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case HackathonStatus.draft:
        return 'Draft';
      case HackathonStatus.published:
        return 'Published';
      case HackathonStatus.ongoing:
        return 'Ongoing';
      case HackathonStatus.completed:
        return 'Completed';
      case HackathonStatus.cancelled:
        return 'Cancelled';
    }
  }
}

HackathonStatus hackathonStatusFromString(String? value) {
  switch (value) {
    case 'draft':
      return HackathonStatus.draft;
    case 'published':
      return HackathonStatus.published;
    case 'ongoing':
      return HackathonStatus.ongoing;
    case 'completed':
      return HackathonStatus.completed;
    case 'cancelled':
      return HackathonStatus.cancelled;
    default:
      return HackathonStatus.published;
  }
}

/// Hackathon model for CodeClub
class HackathonModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime registrationDeadline;
  final int minTeamSize;
  final int maxTeamSize;
  final String venue;
  final String? website;
  final String registrationFormUrl;
  final List<String> prizes;
  final bool isActive;
  final DateTime createdAt;
  final List<String>? rules;
  final String createdByAdminId;
  final String? lastEditedByAdminId;
  final DateTime? lastEditedAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final List<String>? tags;
  final HackathonStatus status;

  HackathonModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.startDate,
    required this.endDate,
    required this.registrationDeadline,
    this.minTeamSize = 1,
    this.maxTeamSize = 4,
    required this.venue,
    this.website,
    required this.registrationFormUrl,
    this.prizes = const [],
    this.isActive = true,
    required this.createdAt,
    this.rules,
    this.createdByAdminId = '',
    this.lastEditedByAdminId,
    this.lastEditedAt,
    this.isDeleted = false,
    this.deletedAt,
    this.tags,
    this.status = HackathonStatus.published,
  });

  /// Create from Firestore document
  factory HackathonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HackathonModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      registrationDeadline: (data['registrationDeadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      minTeamSize: data['minTeamSize'] ?? 1,
      maxTeamSize: data['maxTeamSize'] ?? 4,
      venue: data['venue'] ?? '',
      website: data['website'],
      registrationFormUrl: data['registrationFormUrl'] ?? '',
      prizes: (data['prizes'] as List<dynamic>?)?.cast<String>() ?? [],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rules: (data['rules'] as List<dynamic>?)?.cast<String>(),
      createdByAdminId: data['createdByAdminId'] ?? '',
      lastEditedByAdminId: data['lastEditedByAdminId'],
      lastEditedAt: (data['lastEditedAt'] as Timestamp?)?.toDate(),
      isDeleted: data['isDeleted'] ?? false,
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      tags: (data['tags'] as List<dynamic>?)?.cast<String>(),
      status: hackathonStatusFromString(data['status']),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'registrationDeadline': Timestamp.fromDate(registrationDeadline),
      'minTeamSize': minTeamSize,
      'maxTeamSize': maxTeamSize,
      'venue': venue,
      'website': website,
      'registrationFormUrl': registrationFormUrl,
      'prizes': prizes,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'rules': rules,
      'createdByAdminId': createdByAdminId,
      'lastEditedByAdminId': lastEditedByAdminId,
      'lastEditedAt':
          lastEditedAt != null ? Timestamp.fromDate(lastEditedAt!) : null,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'tags': tags,
      'status': status.value,
    };
  }

  /// Copy with modifications
  HackathonModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? registrationDeadline,
    int? minTeamSize,
    int? maxTeamSize,
    String? venue,
    String? website,
    String? registrationFormUrl,
    List<String>? prizes,
    bool? isActive,
    DateTime? createdAt,
    List<String>? rules,
    String? createdByAdminId,
    String? lastEditedByAdminId,
    DateTime? lastEditedAt,
    bool? isDeleted,
    DateTime? deletedAt,
    List<String>? tags,
    HackathonStatus? status,
  }) {
    return HackathonModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      minTeamSize: minTeamSize ?? this.minTeamSize,
      maxTeamSize: maxTeamSize ?? this.maxTeamSize,
      venue: venue ?? this.venue,
      website: website ?? this.website,
      registrationFormUrl: registrationFormUrl ?? this.registrationFormUrl,
      prizes: prizes ?? this.prizes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      rules: rules ?? this.rules,
      createdByAdminId: createdByAdminId ?? this.createdByAdminId,
      lastEditedByAdminId: lastEditedByAdminId ?? this.lastEditedByAdminId,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      tags: tags ?? this.tags,
      status: status ?? this.status,
    );
  }

  /// Check if registration is open
  bool get isRegistrationOpen =>
      status != HackathonStatus.cancelled &&
      status != HackathonStatus.completed &&
      DateTime.now().isBefore(registrationDeadline);

  /// Check if hackathon is upcoming
  bool get isUpcoming => DateTime.now().isBefore(startDate);

  /// Check if hackathon is ongoing
  bool get isOngoing => 
      DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);

  /// Check if hackathon has ended
  bool get hasEnded => DateTime.now().isAfter(endDate);

  bool get isVisibleToStudents =>
      !isDeleted &&
      (status == HackathonStatus.published ||
          status == HackathonStatus.ongoing ||
          status == HackathonStatus.completed);

  /// Check if hackathon has a valid registration form URL
  bool get hasRegistrationForm => registrationFormUrl.isNotEmpty;

  @override
  String toString() {
    return 'HackathonModel(id: $id, title: $title)';
  }
}

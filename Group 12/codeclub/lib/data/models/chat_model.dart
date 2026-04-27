import 'package:cloud_firestore/cloud_firestore.dart';

/// Chat type enum for different types of chats
enum ChatType {
  private, // 1-on-1 private chat
  team, // Team chat (for hackathon teams)
  group, // General group chat (without hackathon)
  community, // Community chat (everyone can join)
}

/// Chat/Conversation model for CodeClub
class ChatModel {
  final String id;
  final DateTime? lastMessageAt;
  final List<String> participantIds;
  final String? teamId; // If it's a team chat
  final String? hackathonId; // If it's related to a hackathon
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageTime;
  final DateTime createdAt;
  final bool isGroupChat;
  final String? groupName; // For team/group chats
  final ChatType chatType; // Type of chat
  final String? groupDescription; // Description for groups
  final String? groupImageUrl; // Image for groups
  final String? createdBy; // Creator of the group/community

  ChatModel({
    required this.id,
    required this.participantIds,
    this.teamId,
    this.hackathonId,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageTime,
    this.lastMessageAt,
    required this.createdAt,
    this.isGroupChat = false,
    this.groupName,
    this.chatType = ChatType.private,
    this.groupDescription,
    this.groupImageUrl,
    this.createdBy,
  });

  /// Create from Firestore document
  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      teamId: data['teamId'],
      hackathonId: data['hackathonId'],
      lastMessage: data['lastMessage'],
      lastMessageSenderId: data['lastMessageSenderId'],
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      lastMessageAt: data['lastMessageAt']?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isGroupChat: data['isGroupChat'] ?? false,
      groupName: data['groupName'],
      chatType: ChatType.values.firstWhere(
        (e) => e.name == (data['chatType'] ?? 'private'),
        orElse: () => ChatType.private,
      ),
      groupDescription: data['groupDescription'],
      groupImageUrl: data['groupImageUrl'],
      createdBy: data['createdBy'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'participantIds': participantIds,
      'teamId': teamId,
      'hackathonId': hackathonId,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'isGroupChat': isGroupChat,
      'groupName': groupName,
      'chatType': chatType.name,
      'groupDescription': groupDescription,
      'groupImageUrl': groupImageUrl,
      'createdBy': createdBy,
    };
  }

  /// Copy with modifications
  ChatModel copyWith({
    String? id,
    List<String>? participantIds,
    String? teamId,
    String? hackathonId,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageTime,
    DateTime? createdAt,
    bool? isGroupChat,
    String? groupName,
    ChatType? chatType,
    String? groupDescription,
    String? groupImageUrl,
    String? createdBy,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      teamId: teamId ?? this.teamId,
      hackathonId: hackathonId ?? this.hackathonId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      createdAt: createdAt ?? this.createdAt,
      isGroupChat: isGroupChat ?? this.isGroupChat,
      groupName: groupName ?? this.groupName,
      chatType: chatType ?? this.chatType,
      groupDescription: groupDescription ?? this.groupDescription,
      groupImageUrl: groupImageUrl ?? this.groupImageUrl,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// Get other participant ID (for 1-1 chats)
  String getOtherParticipantId(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  /// Check if chat is a private chat
  bool get isPrivateChat => chatType == ChatType.private;

  /// Check if user is participant
  bool isParticipant(String userId) => participantIds.contains(userId);

  /// Check if user is the creator
  bool isCreator(String userId) => createdBy == userId;

  @override
  String toString() {
    return 'ChatModel(id: $id, participants: ${participantIds.length}, type: ${chatType.name})';
  }
}

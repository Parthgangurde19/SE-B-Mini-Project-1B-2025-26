import 'package:cloud_firestore/cloud_firestore.dart';

/// Message model for CodeClub chat
class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final bool isRead;
  final List<String> readBy; // For group chats

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.type = MessageType.text,
    required this.createdAt,
    this.isRead = false,
    this.readBy = const [],
  });

  /// Create from Firestore document
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      readBy: List<String>.from(data['readBy'] ?? []),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'readBy': readBy,
    };
  }

  /// Copy with modifications
  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    MessageType? type,
    DateTime? createdAt,
    bool? isRead,
    List<String>? readBy,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      readBy: readBy ?? this.readBy,
    );
  }

  /// Check if message is from current user
  bool isFromUser(String userId) => senderId == userId;

  @override
  String toString() {
    return 'MessageModel(id: $id, sender: $senderId, content: ${content.substring(0, content.length > 20 ? 20 : content.length)}...)';
  }
}

/// Message type enum
enum MessageType {
  text,
  image,
  file,
  system, // For system messages like "User joined the team"
}

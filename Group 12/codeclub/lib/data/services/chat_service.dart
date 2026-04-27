import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

/// Chat service for CodeClub
/// Handles all chat-related Firestore operations including:
/// - Private chats (1-on-1)
/// - Group chats (general groups without hackathon)
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  ChatModel? _safeChatFromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      return ChatModel.fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ChatService: Skipping malformed chat ${doc.id}: $e');
      }
      return null;
    }
  }

  MessageModel? _safeMessageFromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      return MessageModel.fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ChatService: Skipping malformed message ${doc.id}: $e');
      }
      return null;
    }
  }

  /// Collection references
  CollectionReference<Map<String, dynamic>> get _chatsCollection =>
      _firestore.collection('chats');

  CollectionReference<Map<String, dynamic>> _messagesCollection(
    String chatId,
  ) {
    _log('ChatService: Creating messages collection reference for chat $chatId');
    return _chatsCollection.doc(chatId).collection('messages');
  }

  // ==================== CHAT OPERATIONS ====================

  /// Get or create a one-on-one chat between two users
  Future<ChatModel> getOrCreateChat(String userId1, String userId2) async {
    try {
      // Check if chat already exists
      final existingChat = await _chatsCollection
          .where('participantIds', arrayContains: userId1)
          .where('isGroupChat', isEqualTo: false)
          .get();

      for (final doc in existingChat.docs) {
        final chat = _safeChatFromFirestore(doc);
        if (chat == null) {
          continue;
        }
        if (chat.participantIds.contains(userId2)) {
          return chat;
        }
      }

      // Create new chat
      final chatDoc = _chatsCollection.doc();
      final chat = ChatModel(
        id: chatDoc.id,
        participantIds: [userId1, userId2],
        createdAt: DateTime.now(),
        isGroupChat: false,
      );

      await chatDoc.set(chat.toFirestore());
      return chat;
    } catch (e) {
      rethrow;
    }
  }

  /// Get chat by ID
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final doc = await _chatsCollection.doc(chatId).get();
      if (doc.exists) {
        return ChatModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all chats for a user
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _chatsCollection
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
      .map((snapshot) => snapshot.docs
        .map(_safeChatFromFirestore)
        .whereType<ChatModel>()
        .toList());
  }

  /// Update chat participants (for group chats)
  Future<void> updateChatParticipants(
    String chatId,
    List<String> participantIds,
  ) async {
    try {
      await _chatsCollection.doc(chatId).update({
        'participantIds': participantIds,
      });
    } catch (e) {
      rethrow;
    }
  }

  // ==================== MESSAGE OPERATIONS ====================

  /// Send a message
  Future<MessageModel> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    try {
      _log('ChatService: Sending message to chat $chatId from $senderId');
      
      final messageDoc = _messagesCollection(chatId).doc();
      final message = MessageModel(
        id: messageDoc.id,
        chatId: chatId,
        senderId: senderId,
        content: content,
        type: type,
        createdAt: DateTime.now(),
        readBy: [senderId],
      );

      _log('ChatService: Created message with ID ${message.id}');

      // Send message
      await messageDoc.set(message.toFirestore());
      _log('ChatService: Message saved to Firestore');

      // Update chat's last message
      await _chatsCollection.doc(chatId).update({
        'lastMessage': content,
        'lastMessageSenderId': senderId,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
      _log('ChatService: Updated chat last message');

      return message;
    } catch (e) {
      _log('ChatService: Error sending message: $e');
      rethrow;
    }
  }

  /// Get messages for a chat
  /// Optimized: Uses List.of with reversed iterable to avoid double toList() call
  Stream<List<MessageModel>> getMessages(String chatId, {int limit = 50}) {
    _log('ChatService: Getting messages for chat $chatId');
    return _messagesCollection(chatId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) {
            _log('ChatService: Received ${snapshot.docs.length} message documents for chat $chatId');
            // Optimized: Create list directly in correct order using reversed
            final messages = List<MessageModel>.of(
              snapshot.docs.map((doc) {
                _log('ChatService: Processing message doc ${doc.id}');
                return _safeMessageFromFirestore(doc);
              }).whereType<MessageModel>().toList().reversed,
            );
            _log('ChatService: Returning ${messages.length} processed messages');
            return messages;
          },
        );
  }

  /// Load more messages (for pagination)
  Future<List<MessageModel>> loadMoreMessages(
    String chatId, {
    required DateTime beforeTime,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _messagesCollection(chatId)
          .orderBy('createdAt', descending: true)
          .where('createdAt', isLessThan: Timestamp.fromDate(beforeTime))
          .limit(limit)
          .get();

      return snapshot.docs
          .map(_safeMessageFromFirestore)
          .whereType<MessageModel>()
          .toList()
          .reversed
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(
    String chatId,
    String messageId,
    String userId,
  ) async {
    try {
      await _messagesCollection(chatId).doc(messageId).update({
        'isRead': true,
        'readBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Mark all messages in chat as read
  Future<void> markAllMessagesAsRead(String chatId, String userId) async {
    try {
      final unreadMessages = await _messagesCollection(
        chatId,
      ).where('senderId', isNotEqualTo: userId).get();

      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readBy': FieldValue.arrayUnion([userId]),
        });
      }
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _messagesCollection(chatId).doc(messageId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Get unread message count for a chat
  Future<int> getUnreadCount(String chatId, String userId) async {
    try {
      final snapshot = await _messagesCollection(chatId)
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get messages stream for a chat
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
      .map((snapshot) => snapshot.docs
        .map(_safeMessageFromFirestore)
        .whereType<MessageModel>()
        .toList());
  }

  /// Get or create private chat
  Future<ChatModel> getOrCreatePrivateChat(
    String user1Id,
    String user2Id,
  ) async {
    // Check if chat already exists
    final existingChat = await _firestore
        .collection('chats')
        .where('participantIds', arrayContains: user1Id)
        .where('chatType', isEqualTo: ChatType.private.name)
        .get();

    for (final doc in existingChat.docs) {
      final chat = _safeChatFromFirestore(doc);
      if (chat == null) {
        continue;
      }
      if (chat.participantIds.contains(user2Id)) {
        return chat;
      }
    }

    // Create new private chat
    final chatData = ChatModel(
      id: '',
      participantIds: [user1Id, user2Id],
      createdAt: DateTime.now(),
      isGroupChat: false,
      chatType: ChatType.private,
    );

    final docRef = await _firestore
        .collection('chats')
        .add(chatData.toFirestore());

    return ChatModel(
      id: docRef.id,
      participantIds: chatData.participantIds,
      createdAt: chatData.createdAt,
      isGroupChat: chatData.isGroupChat,
      chatType: chatData.chatType,
    );
  }

  // ==================== GROUP CHAT OPERATIONS ====================

  /// Create a general group chat (not tied to a team or hackathon)
  Future<ChatModel> createGroupChat({
    required String groupName,
    required String creatorId,
    required List<String> memberIds,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final allMembers = {...memberIds, creatorId}.toList();

      final chatDoc = _chatsCollection.doc();
      final chat = ChatModel(
        id: chatDoc.id,
        participantIds: allMembers,
        createdAt: DateTime.now(),
        isGroupChat: true,
        groupName: groupName,
        chatType: ChatType.group,
        groupDescription: description,
        groupImageUrl: imageUrl,
        createdBy: creatorId,
      );

      await chatDoc.set(chat.toFirestore());
      return chat;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all group chats for a user
  Stream<List<ChatModel>> getUserGroupChats(String userId) {
    return _chatsCollection
        .where('participantIds', arrayContains: userId)
        .where('chatType', isEqualTo: ChatType.group.name)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
      .map((snapshot) => snapshot.docs
        .map(_safeChatFromFirestore)
        .whereType<ChatModel>()
        .toList());
  }

  /// Add member to group chat
  Future<void> addMemberToGroup(String chatId, String userId) async {
    try {
      await _chatsCollection.doc(chatId).update({
        'participantIds': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Remove member from group chat
  Future<void> removeMemberFromGroup(String chatId, String userId) async {
    try {
      await _chatsCollection.doc(chatId).update({
        'participantIds': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get chats by type
  Stream<List<ChatModel>> getChatsByType(String userId, ChatType type) {
    return _chatsCollection
        .where('participantIds', arrayContains: userId)
        .where('chatType', isEqualTo: type.name)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList(),
        );
  }

  /// Get private chats only
  Stream<List<ChatModel>> getPrivateChats(String userId) {
    return getChatsByType(userId, ChatType.private);
  }
}

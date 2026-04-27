import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../data/models/chat_model.dart';
import '../data/models/message_model.dart';
import '../data/models/user_model.dart';
import '../data/services/chat_service.dart';
import '../data/services/user_service.dart';

/// Chat provider for managing chat state
/// Supports private chats, team chats, group chats, and community chats
class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();

  List<ChatModel> _chats = [];
  ChatModel? _currentChat;
  List<MessageModel> _messages = [];
  Map<String, UserModel> _chatUsers = {};
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _chatsSubscription;

  // Getters
  List<ChatModel> get chats => _chats;
  
  // Computed getters - O(n) but no memory duplication
  // These filter on-demand instead of storing duplicates
  List<ChatModel> get privateChats => _chats
      .where((c) => c.chatType == ChatType.private)
      .toList();
  List<ChatModel> get groupChats => _chats
      .where((c) => c.chatType == ChatType.group)
      .toList();
  ChatModel? get currentChat => _currentChat;
  List<MessageModel> get messages => _messages;
  Map<String, UserModel> get chatUsers => _chatUsers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load user's chats
  void loadUserChats(String userId) {
    _chatsSubscription?.cancel();
    _chatsSubscription = _chatService
        .getUserChats(userId)
        .listen(
          (chats) async {
            _chats = chats;

            // Removed duplicate list assignments - using computed getters now
            // This saves ~3x memory for chat storage

            // Load user details for each chat
            final userIds = <String>{};
            for (final chat in chats) {
              userIds.addAll(chat.participantIds);
            }

            if (userIds.isNotEmpty) {
              try {
                final users = await _userService.getUsersByIds(
                  userIds.toList(),
                );
                _chatUsers = {for (var user in users) user.uid: user};
              } catch (e) {
                print('Error loading chat users: $e');
                _errorMessage = e.toString();
              }
            }

            // Use addPostFrameCallback to avoid setState during build
            _safeNotifyListeners();
          },
          onError: (e) {
            print('Error loading chats: $e');
            _errorMessage = e.toString();
            _safeNotifyListeners();
          },
        );
  }

  /// Listen to user chats
  void listenToChats(String userId) {
    loadUserChats(userId);
  }

  /// Get messages stream for a chat
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _chatService.getMessagesStream(chatId);
  }

  /// Get chat by ID
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      return await _chatService.getChatById(chatId);
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  /// Open chat with user
  Future<ChatModel?> openChatWithUser(
    String currentUserId,
    String otherUserId,
  ) async {
    try {
      return await _chatService.getOrCreatePrivateChat(
        currentUserId,
        otherUserId,
      );
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  /// Select a chat and load messages
  Future<void> selectChat(ChatModel chat) async {
    print('Selecting chat: ${chat.id} (${chat.groupName ?? 'Private chat'})');
    
    _currentChat = chat;
    _messages = [];
    _safeNotifyListeners();

    // Load users for this chat
    final users = await _userService.getUsersByIds(chat.participantIds);
    for (final user in users) {
      _chatUsers[user.uid] = user;
    }

    // Subscribe to messages
    _messagesSubscription?.cancel();
    _messagesSubscription = _chatService
        .getMessages(chat.id)
        .listen(
          (messages) {
            print('Received ${messages.length} messages for chat ${chat.id}');
            _messages = messages;
            _safeNotifyListeners();
          },
          onError: (e) {
            print('Error loading messages: $e');
            _errorMessage = e.toString();
            _safeNotifyListeners();
          },
        );
  }

  /// Send a message
  Future<bool> sendMessage({
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    if (_currentChat == null || content.trim().isEmpty) {
      print('Cannot send message: current chat is null or content is empty');
      return false;
    }

    print('Sending message to chat ${_currentChat!.id}: $content');

    try {
      await _chatService.sendMessage(
        chatId: _currentChat!.id,
        senderId: senderId,
        content: content.trim(),
        type: type,
      );
      print('Message sent successfully');
      return true;
    } catch (e) {
      print('Error sending message: $e');
      _errorMessage = e.toString();
      _safeNotifyListeners();
      return false;
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String userId) async {
    if (_currentChat == null) return;

    try {
      await _chatService.markAllMessagesAsRead(_currentChat!.id, userId);
    } catch (e) {
      // Silent error handling
    }
  }

  /// Close current chat
  void closeChat() {
    _messagesSubscription?.cancel();
    _currentChat = null;
    _messages = [];
    _safeNotifyListeners();
  }

  /// Get user for chat display
  UserModel? getUserForChat(ChatModel chat, String currentUserId) {
    if (chat.isGroupChat) return null;
    final otherUserId = chat.getOtherParticipantId(currentUserId);
    return _chatUsers[otherUserId];
  }

  // ==================== GROUP CHAT OPERATIONS ====================

  /// Create a new group chat
  Future<ChatModel?> createGroupChat({
    required String groupName,
    required String creatorId,
    required List<String> memberIds,
    String? description,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final chat = await _chatService.createGroupChat(
        groupName: groupName,
        creatorId: creatorId,
        memberIds: memberIds,
        description: description,
      );
      _isLoading = false;
      _safeNotifyListeners();
      return chat;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _safeNotifyListeners();
      return null;
    }
  }

  /// Add member to group
  Future<bool> addMemberToGroup(String chatId, String userId) async {
    try {
      await _chatService.addMemberToGroup(chatId, userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  /// Remove member from group
  Future<bool> removeMemberFromGroup(String chatId, String userId) async {
    try {
      await _chatService.removeMemberFromGroup(chatId, userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    _safeNotifyListeners();
  }

  /// Safe notify listeners to avoid setState during build
  void _safeNotifyListeners() {
    if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      notifyListeners();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _chatsSubscription?.cancel();
    super.dispose();
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/user_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../widgets/loading_widgets.dart';

/// Chat conversation screen
class ChatScreen extends StatefulWidget {
  final String chatId;
  final String title;
  final bool isGroupChat;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.title,
    this.isGroupChat = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();
  
  Map<String, UserModel> _usersCache = {};
  StreamSubscription? _messagesSubscription;
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  String? _chatTitle;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _chatTitle = widget.title;
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
      _loadChatData();
      _listenToMessages();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  /// Initialize notification service
  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();
      await _notificationService.requestPermission();
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  Future<void> _loadChatData() async {
    final chatProvider = context.read<ChatProvider>();
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUserId;
    
    if (currentUserId == null) return;

    // First try to get the chat from existing chats
    ChatModel? chat;
    try {
      chat = chatProvider.chats.firstWhere(
        (c) => c.id == widget.chatId,
      );
    } catch (e) {
      // Chat not found in loaded chats, will try from service
      chat = null;
    }

    // If not found, try to get it directly from the service
    if (chat == null) {
      try {
        chat = await chatProvider.getChatById(widget.chatId);
      } catch (e) {
        print('Error loading chat: $e');
        return;
      }
    }

    if (chat == null) {
      print('Chat not found: ${widget.chatId}');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat not found'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    print('Found chat: ${chat.id} with ${chat.participantIds.length} participants');

    // Select this chat in the provider
    await chatProvider.selectChat(chat);
    
    // Load chat title for private chats
    if (!widget.isGroupChat && widget.title.isEmpty) {
      final otherUserId = chat.participantIds.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );
      
      if (otherUserId.isNotEmpty) {
        final user = await _userService.getUserById(otherUserId);
        if (user != null && mounted) {
          setState(() {
            _chatTitle = user.fullName;
            _usersCache[user.uid] = user;
          });
        }
      }
    }
  }

  void _listenToMessages() {
    // Since we're using ChatProvider's selectChat method,
    // we'll listen to the provider's messages directly in the build method
    setState(() {
      _isLoading = false;
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final senderId = authProvider.currentUserId;
    
    if (senderId == null) return;

    _messageController.clear();

    await chatProvider.sendMessage(
      senderId: senderId,
      content: text,
    );
  }

  Future<UserModel?> _getUser(String userId) async {
    if (_usersCache.containsKey(userId)) {
      return _usersCache[userId];
    }
    
    try {
      final user = await _userService.getUserById(userId);
      if (user != null) {
        _usersCache[userId] = user;
      }
      return user;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_chatTitle ?? 'Chat'),
        actions: [
          if (widget.isGroupChat)
            IconButton(
              onPressed: () {
                // TODO: Show group info
              },
              icon: const Icon(Icons.info_outline_rounded),
            ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, _) {
          final messages = chatProvider.messages;
          final currentUserId = context.read<AuthProvider>().currentUserId;
          
          // Show notification when new message arrives
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (messages.isNotEmpty && messages.length > _lastMessageCount) {
              final newMessage = messages.last;
              final isCurrentUser = newMessage.senderId == currentUserId;

              // Only show notification for messages from other users
              if (!isCurrentUser) {
                final senderUser = _usersCache[newMessage.senderId];
                final senderName = senderUser?.fullName ?? 'Unknown User';

                _notificationService.showMessageNotification(
                  chatId: widget.chatId,
                  senderName: senderName,
                  messageContent: newMessage.content,
                  senderImage: senderUser?.profileImageUrl,
                );
              }
              _lastMessageCount = messages.length;
            }
          });
          
          // Scroll to bottom when messages change
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (messages.isNotEmpty && _messages.length != messages.length) {
              _scrollToBottom();
            }
            _messages = messages; // Update local messages for comparison
          });
          
          return Column(
            children: [
              // Messages list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : messages.isEmpty
                        ? const Center(
                            child: EmptyStateWidget(
                              icon: Icons.chat_bubble_outline_rounded,
                              title: 'No messages yet',
                              subtitle: 'Send a message to start the conversation',
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final currentUserId =
                                  context.read<AuthProvider>().currentUserId;
                              final isMe = message.senderId == currentUserId;
                              
                              // Check if we should show date separator
                              final showDate = index == 0 ||
                                  !_isSameDay(
                                    messages[index - 1].createdAt,
                                    message.createdAt,
                                  );
                              
                              return Column(
                                children: [
                                  if (showDate)
                                    _DateSeparator(date: message.createdAt),
                                  _MessageBubble(
                                    message: message,
                                    isMe: isMe,
                                    showSenderName:
                                        widget.isGroupChat && !isMe,
                                    getUserFn: _getUser,
                                  ).animate().fadeIn(duration: 200.ms),
                                ],
                              );
                            },
                          ),
              ),
              // Message input
              _MessageInput(
                controller: _messageController,
                onSend: _sendMessage,
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

/// Date separator widget
class _DateSeparator extends StatelessWidget {
  final DateTime date;

  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: isDark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              date.formatDateFull,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
            ),
          ),
          Expanded(
            child: Divider(
              color: isDark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Message bubble widget
class _MessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final bool showSenderName;
  final Future<UserModel?> Function(String) getUserFn;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showSenderName,
    required this.getUserFn,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  String? _senderName;

  @override
  void initState() {
    super.initState();
    if (widget.showSenderName) {
      _loadSenderName();
    }
  }

  Future<void> _loadSenderName() async {
    final user = await widget.getUserFn(widget.message.senderId);
    if (user != null && mounted) {
      setState(() {
        _senderName = user.fullName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: widget.isMe
              ? AppColors.sentMessageBubble
              : (isDark
                  ? AppColors.receivedMessageBubbleDark
                  : AppColors.receivedMessageBubbleLight),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: widget.isMe
                ? const Radius.circular(16)
                : const Radius.circular(4),
            bottomRight: widget.isMe
                ? const Radius.circular(4)
                : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showSenderName && _senderName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  _senderName!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            Text(
              widget.message.content,
              style: TextStyle(
                color: widget.isMe
                    ? Colors.white
                    : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.message.createdAt.formatTime,
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                  ),
                ),
                if (widget.isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all_rounded,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Message input widget
class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _MessageInput({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Attachment button
          IconButton(
            onPressed: () {
              // TODO: Show attachment options
            },
            icon: const Icon(Icons.attach_file_rounded),
          ),
          // Text input
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: isDark
                    ? AppColors.backgroundDark
                    : AppColors.backgroundLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: onSend,
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

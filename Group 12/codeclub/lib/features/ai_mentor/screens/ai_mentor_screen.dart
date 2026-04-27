import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/ai_mentor_theme.dart';
import '../models/chat_message.dart';
import '../services/hackathon_api.dart';
import '../widgets/chat_bubble.dart';

class AIMentorScreen extends StatefulWidget {
  const AIMentorScreen({super.key});

  @override
  State<AIMentorScreen> createState() => _AIMentorScreenState();
}

class _AIMentorScreenState extends State<AIMentorScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;

  final List<String> _suggestions = [
    'Best tech stack for a hackathon website?',
    'Flutter vs React Native for hackathon?',
    'How to impress hackathon judges?',
    'How to build MVP in 24 hours?',
    'Best free APIs for hackathons?',
    'How to structure hackathon project?',
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _loadChatHistory();
    _addWelcomeMessage();
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _addWelcomeMessage() {
    if (_messages.isEmpty) {
      setState(() {
        _messages.add(
          ChatMessage.ai(
            "Hi! I am your AI Hackathon Mentor.\n\n"
            'I can help with:\n'
            '- Tech stack recommendations\n'
            '- Project architecture\n'
            '- MVP planning and execution\n'
            '- Pitching to judges\n'
            '- Time management during hackathons\n\n'
            'Ask me anything about hackathons.',
          ),
        );
      });
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMessages = prefs.getStringList('ai_mentor_chat') ?? [];
      if (savedMessages.isNotEmpty) {
        setState(() {
          _messages = savedMessages
              .map((encoded) => ChatMessage.fromJson(jsonDecode(encoded)))
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = _messages
          .where((m) => !m.isLoading)
          .map((m) => jsonEncode(m.toJson()))
          .toList();
      await prefs.setStringList('ai_mentor_chat', encoded);
    } catch (_) {}
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) {
      return;
    }

    final userMessage = ChatMessage.user(text.trim());
    final loadingMessage = ChatMessage.loading();

    setState(() {
      _messages.add(userMessage);
      _messages.add(loadingMessage);
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final answer = await HackathonApiService.askQuestion(text.trim());
      setState(() {
        _messages.remove(loadingMessage);
        _messages.add(ChatMessage.ai(answer));
        _isLoading = false;
      });
      await _saveChatHistory();
    } catch (e) {
      setState(() {
        _messages.remove(loadingMessage);
        _messages.add(
          ChatMessage.ai(
            'Error: ${e.toString().replaceAll('Exception: ', '')}\n\n'
            'Please check your connection and try again.',
          ),
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearChat() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ai_mentor_chat');
    setState(() {
      _messages.clear();
    });
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AIMentorTheme.scaffoldBackground(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: AIMentorTheme.backgroundGradient(context),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildChatList(),
              if (_messages.length <= 1) _buildSuggestions(),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AIMentorTheme.cardBg(context).withValues(alpha: 0.94),
        border: Border(
          bottom: BorderSide(color: AIMentorTheme.divider(context), width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AIMentorTheme.cardBg2(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AIMentorTheme.divider(context)),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: AIMentorTheme.textPrimary(context),
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AIMentorTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AIMentorTheme.primaryBlue.withValues(alpha: 0.28),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .shimmer(
                duration: 2500.ms,
                color: AIMentorTheme.accentGreen.withValues(alpha: 0.3),
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Hackathon Mentor',
                  style: AIMentorTheme.headingStyle(
                    context,
                  ).copyWith(fontSize: 16),
                ),
                Row(
                  children: [
                    Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00FF88),
                            shape: BoxShape.circle,
                          ),
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .fade(begin: 0.4, end: 1.0, duration: 1000.ms),
                    const SizedBox(width: 5),
                    Text(
                      _isLoading ? 'Thinking...' : 'Online',
                      style: AIMentorTheme.subtitleStyle(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: AIMentorTheme.cardBg(context),
                title: Text(
                  'Clear Chat',
                  style: GoogleFonts.inter(
                    color: AIMentorTheme.textPrimary(context),
                  ),
                ),
                content: Text(
                  'This will delete all messages.',
                  style: GoogleFonts.inter(
                    color: AIMentorTheme.textSecondary(context),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        color: AIMentorTheme.textSecondary(context),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _clearChat();
                    },
                    child: Text(
                      'Clear',
                      style: GoogleFonts.inter(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AIMentorTheme.cardBg2(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AIMentorTheme.divider(context)),
              ),
              child: Icon(
                Icons.delete_outline,
                color: AIMentorTheme.textSecondary(context),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildChatList() {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _messages.length,
        itemBuilder: (context, index) =>
            ChatBubble(message: _messages[index], index: index),
      ),
    );
  }

  Widget _buildSuggestions() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          return GestureDetector(
                onTap: () => _sendMessage(_suggestions[index]),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AIMentorTheme.cardBg(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AIMentorTheme.primaryBlue.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    _suggestions[index],
                    style: GoogleFonts.inter(
                      color: AIMentorTheme.textSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                ),
              )
              .animate(delay: Duration(milliseconds: index * 60))
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.3, end: 0);
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: BoxDecoration(
        color: AIMentorTheme.cardBg(context).withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: AIMentorTheme.divider(context))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AIMentorTheme.cardBg2(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? AIMentorTheme.primaryBlue
                      : AIMentorTheme.divider(context),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: AIMentorTheme.messageStyle(context),
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: _isLoading ? null : _sendMessage,
                      decoration: InputDecoration(
                        hintText: 'Ask anything about hackathons...',
                        hintStyle: AIMentorTheme.subtitleStyle(context),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isLoading ? null : () => _sendMessage(_controller.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: _isLoading
                    ? null
                    : const LinearGradient(
                        colors: AIMentorTheme.fabGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: _isLoading ? AIMentorTheme.divider(context) : null,
                shape: BoxShape.circle,
                boxShadow: _isLoading
                    ? null
                    : [
                        BoxShadow(
                          color: AIMentorTheme.primaryBlue.withValues(
                            alpha: 0.4,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AIMentorTheme.primaryBlue,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.3, end: 0);
  }
}

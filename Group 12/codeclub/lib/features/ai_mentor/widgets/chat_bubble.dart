import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/ai_mentor_theme.dart';
import '../models/chat_message.dart';
import 'typing_indicator.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final int index;

  const ChatBubble({super.key, required this.message, required this.index});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) _buildAIAvatar(),
              if (!isUser) const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (message.isLoading)
                      const TypingIndicator()
                    else
                      _buildBubble(context, isUser),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message.timestamp),
                      style: AIMentorTheme.subtitleStyle(
                        context,
                      ).copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (isUser) const SizedBox(width: 8),
              if (isUser) _buildUserAvatar(context),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: index * 50))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.3, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }

  Widget _buildBubble(BuildContext context, bool isUser) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: message.content));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Copied to clipboard',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: AIMentorTheme.primaryBlue,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [AIMentorTheme.primaryBlue, AIMentorTheme.deepBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser ? null : AIMentorTheme.aiBubble(context),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: AIMentorTheme.primaryBlue.withValues(alpha: 0.2),
                ),
          boxShadow: [
            BoxShadow(
              color: isUser
                  ? AIMentorTheme.primaryBlue.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isUser
            ? Text(message.content, style: AIMentorTheme.messageStyle(context))
            : MarkdownBody(
                data: message.content,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: AIMentorTheme.messageStyle(context),
                  strong: AIMentorTheme.messageStyle(context).copyWith(
                    fontWeight: FontWeight.bold,
                    color: AIMentorTheme.primaryBlue,
                  ),
                  code: AIMentorTheme.monoStyle(context),
                  codeblockDecoration: BoxDecoration(
                    color: AIMentorTheme.cardBg2(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AIMentorTheme.primaryBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  listBullet: AIMentorTheme.messageStyle(
                    context,
                  ).copyWith(color: AIMentorTheme.primaryBlue),
                  h1: AIMentorTheme.headingStyle(
                    context,
                  ).copyWith(fontSize: 18),
                  h2: AIMentorTheme.headingStyle(
                    context,
                  ).copyWith(fontSize: 16),
                  h3: AIMentorTheme.headingStyle(
                    context,
                  ).copyWith(fontSize: 14),
                ),
              ),
      ),
    );
  }

  Widget _buildAIAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: AIMentorTheme.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AIMentorTheme.primaryBlue.withValues(alpha: 0.35),
            blurRadius: 8,
          ),
        ],
      ),
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AIMentorTheme.cardBg(context),
        shape: BoxShape.circle,
        border: Border.all(color: AIMentorTheme.divider(context)),
      ),
      child: Icon(
        Icons.person,
        color: AIMentorTheme.textSecondary(context),
        size: 16,
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

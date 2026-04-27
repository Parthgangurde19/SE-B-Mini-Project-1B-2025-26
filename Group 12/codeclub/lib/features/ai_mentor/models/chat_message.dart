enum MessageRole { user, ai }

class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isLoading = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'role': role.name,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    content: json['content'] as String,
    role: MessageRole.values.firstWhere(
      (e) => e.name == json['role'],
      orElse: () => MessageRole.user,
    ),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  factory ChatMessage.user(String content) => ChatMessage(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    content: content,
    role: MessageRole.user,
    timestamp: DateTime.now(),
  );

  factory ChatMessage.ai(String content) => ChatMessage(
    id: '${DateTime.now().millisecondsSinceEpoch}_ai',
    content: content,
    role: MessageRole.ai,
    timestamp: DateTime.now(),
  );

  factory ChatMessage.loading() => ChatMessage(
    id: 'loading',
    content: '',
    role: MessageRole.ai,
    timestamp: DateTime.now(),
    isLoading: true,
  );
}

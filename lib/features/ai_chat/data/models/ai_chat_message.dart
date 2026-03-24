enum AiChatRole { user, assistant }

extension AiChatRoleX on AiChatRole {
  String get value => name;

  bool get isUser => this == AiChatRole.user;
}

class AiChatMessage {
  const AiChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  final AiChatRole role;
  final String content;
  final DateTime timestamp;

  AiChatMessage copyWith({
    AiChatRole? role,
    String? content,
    DateTime? timestamp,
  }) {
    return AiChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

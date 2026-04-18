import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: json['content'] as String? ?? '',
      isUser: json['role'] == 'user',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isLoadingHistory;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingHistory = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isLoadingHistory,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(const ChatState());

  Future<void> loadHistory() async {
    if (state.isLoadingHistory) return;
    state = state.copyWith(isLoadingHistory: true);
    try {
      final history = await ApiService.getChatHistory();
      final messages = history.map(ChatMessage.fromJson).toList();
      state = state.copyWith(messages: messages, isLoadingHistory: false);
    } catch (_) {
      state = state.copyWith(isLoadingHistory: false);
    }
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isLoading) return;

    final userMsg = ChatMessage(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      content: trimmed,
      isUser: true,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      clearError: true,
    );

    try {
      final response = await ApiService.sendChatMessage(trimmed);
      final aiMsg = ChatMessage(
        id: 'a_${DateTime.now().millisecondsSinceEpoch}',
        content: response,
        isUser: false,
        createdAt: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get response. Check your connection.',
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(),
);

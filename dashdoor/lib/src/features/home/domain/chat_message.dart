import 'package:flutter/foundation.dart';

import 'calendar_event.dart';
import 'food_suggestion.dart';

enum ChatSender { user, assistant }

sealed class ChatMessage {
  const ChatMessage({required this.id, required this.sender});

  final String id;
  final ChatSender sender;
}

class TextMessage extends ChatMessage {
  const TextMessage({
    required super.id,
    required super.sender,
    required this.text,
  });

  final String text;
}

class TypingMessage extends ChatMessage {
  const TypingMessage({required super.id})
      : super(sender: ChatSender.assistant);
}

/// Inline day-view card rendered inside the assistant's message.
class DayPlanMessage extends ChatMessage {
  const DayPlanMessage({
    required super.id,
    required this.date,
    required this.events,
    required this.suggestions,
    this.weatherEmoji,
    this.weatherLabel,
  }) : super(sender: ChatSender.assistant);

  final DateTime date;
  final List<CalendarEvent> events;
  final List<FoodSuggestion> suggestions;
  final String? weatherEmoji;
  final String? weatherLabel;
}

/// Scrollable alternatives rail shown in response to "swap".
class AlternativesMessage extends ChatMessage {
  const AlternativesMessage({
    required super.id,
    required this.replacingSuggestionId,
    required this.options,
  }) : super(sender: ChatSender.assistant);

  final String replacingSuggestionId;
  final List<FoodSuggestion> options;
}

@immutable
class QuickReply {
  const QuickReply({required this.label, required this.intent, this.icon});

  final String label;
  final String intent;
  final String? icon;
}

class QuickRepliesMessage extends ChatMessage {
  const QuickRepliesMessage({required super.id, required this.replies})
      : super(sender: ChatSender.assistant);

  final List<QuickReply> replies;
}

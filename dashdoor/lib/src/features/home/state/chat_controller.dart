import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_day_repository.dart';
import '../domain/calendar_event.dart';
import '../domain/chat_message.dart';
import '../domain/food_suggestion.dart';

final _idRand = math.Random();
String _nextId(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_idRand.nextInt(1 << 20)}';

class ChatState {
  ChatState({
    required this.messages,
    required this.events,
    required this.suggestions,
  });

  final List<ChatMessage> messages;
  final List<CalendarEvent> events;

  /// Keyed by [FoodSuggestion.id] so day-plan cards can look up details even
  /// after we've swapped in replacements.
  final Map<String, FoodSuggestion> suggestions;

  ChatState copyWith({
    List<ChatMessage>? messages,
    List<CalendarEvent>? events,
    Map<String, FoodSuggestion>? suggestions,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      events: events ?? this.events,
      suggestions: suggestions ?? this.suggestions,
    );
  }
}

class ChatController extends Notifier<ChatState> {
  Timer? _typingTimer;

  @override
  ChatState build() {
    ref.onDispose(() => _typingTimer?.cancel());
    final events = kMockDayRepository.events();
    final suggestions = {
      for (final s in kMockDayRepository.suggestions()) s.id: s,
    };

    final intro = _introMessages(events, suggestions.values.toList());

    Future.microtask(_sendInitialSequence);

    return ChatState(
      messages: intro.prologue,
      events: events,
      suggestions: suggestions,
    );
  }

  // region: public API

  void sendUserText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _appendMessage(TextMessage(
      id: _nextId('m'),
      sender: ChatSender.user,
      text: trimmed,
    ));
    _respondToFreeText(trimmed);
  }

  void tapQuickReply(QuickReply reply) {
    _appendMessage(TextMessage(
      id: _nextId('m'),
      sender: ChatSender.user,
      text: reply.label,
    ));
    switch (reply.intent) {
      case 'swap_lunch':
        _showLunchAlternatives();
      case 'lighter_dinner':
        _offerLighterDinner();
      case 'earlier_dinner':
        _offerEarlierDinner();
      case 'add_snack':
        _confirmExistingSnack();
      case 'why_this':
        _explainPicks();
      default:
        _respondToFreeText(reply.label);
    }
  }

  void requestSwap(String suggestionId) {
    final current = state.suggestions[suggestionId];
    final slot = current?.slot;
    _appendMessage(TextMessage(
      id: _nextId('m'),
      sender: ChatSender.user,
      text: 'Swap ${slot?.label.toLowerCase() ?? 'this meal'}',
    ));
    if (slot == MealSlot.lunch) {
      _showLunchAlternatives();
    } else {
      _withTyping(() {
        _appendMessage(TextMessage(
          id: _nextId('m'),
          sender: ChatSender.assistant,
          text:
              "Got it. I'll hold while you browse alternatives — tap any meal to see the full card.",
        ));
      });
    }
  }

  void pickAlternative(String replacingId, FoodSuggestion alt) {
    final suggestions = Map<String, FoodSuggestion>.from(state.suggestions);
    final current = suggestions[replacingId];
    if (current == null) return;

    final newSuggestion = FoodSuggestion(
      id: current.id,
      slot: current.slot,
      restaurant: alt.restaurant,
      headline: alt.headline,
      cuisine: alt.cuisine,
      rating: alt.rating,
      priceBand: alt.priceBand,
      windowStart: current.windowStart,
      windowEnd: current.windowEnd,
      distanceMin: alt.distanceMin,
      neighborhood: alt.neighborhood,
      reason: alt.reason,
      nutrition: alt.nutrition,
      menuItems: alt.menuItems,
      tags: alt.tags,
      artworkSeed: alt.artworkSeed,
    );
    suggestions[replacingId] = newSuggestion;

    state = state.copyWith(
      suggestions: suggestions,
      messages: _replaceDayPlan(state.messages, suggestions.values.toList()),
    );

    _appendMessage(TextMessage(
      id: _nextId('m'),
      sender: ChatSender.user,
      text: 'Pick ${alt.restaurant}',
    ));
    _withTyping(() {
      _appendMessage(TextMessage(
        id: _nextId('m'),
        sender: ChatSender.assistant,
        text:
            "Swapped ${current.slot.label.toLowerCase()} to ${alt.restaurant} — your day view updated above.",
      ));
      _appendMessage(QuickRepliesMessage(
        id: _nextId('m'),
        replies: const [
          QuickReply(label: 'Show me one more', intent: 'swap_lunch'),
          QuickReply(label: 'Why this one?', intent: 'why_this'),
          QuickReply(label: "Looks good, lock it in", intent: 'lock_in'),
        ],
      ));
    });
  }

  // endregion

  // region: scripted scenarios

  Future<void> _sendInitialSequence() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final intro = _introMessages(state.events, state.suggestions.values.toList());
    _appendAll(intro.followUps);
  }

  void _showLunchAlternatives() {
    final alts = state.suggestions.values
        .where((s) =>
            s.slot == MealSlot.lunch &&
            s.id.startsWith('food_lunch_alt_'))
        .toList();

    _withTyping(() {
      _appendMessage(TextMessage(
        id: _nextId('m'),
        sender: ChatSender.assistant,
        text:
            "Here are three lunches that fit your 12:00 window and design review right after.",
      ));
      _appendMessage(AlternativesMessage(
        id: _nextId('m'),
        replacingSuggestionId: 'food_lunch',
        options: alts,
      ));
    });
  }

  void _offerLighterDinner() {
    _withTyping(() {
      final dinner = state.suggestions['food_dinner'];
      _appendMessage(TextMessage(
        id: _nextId('m'),
        sender: ChatSender.assistant,
        text: dinner == null
            ? "Got it — I'll flag lighter options for dinner."
            : "${dinner.restaurant} is already on the lighter side for dinner (640 cal). Want me to swap to a broth-first option instead?",
      ));
      _appendMessage(QuickRepliesMessage(
        id: _nextId('m'),
        replies: const [
          QuickReply(label: 'Yes, show broth-first', intent: 'swap_lunch'),
          QuickReply(label: 'Keep it', intent: 'lock_in'),
        ],
      ));
    });
  }

  void _offerEarlierDinner() {
    _withTyping(() {
      _appendMessage(TextMessage(
        id: _nextId('m'),
        sender: ChatSender.assistant,
        text:
            "Your flight lands at 19:30 — earliest realistic dinner is 20:00 walk-up. I can hold a table at 20:15 if you want.",
      ));
    });
  }

  void _confirmExistingSnack() {
    _withTyping(() {
      _appendMessage(TextMessage(
        id: _nextId('m'),
        sender: ChatSender.assistant,
        text:
            "You already have a 3:30 pm snack (Joe & the Juice). Want me to upgrade it to something more filling?",
      ));
    });
  }

  void _explainPicks() {
    _withTyping(() {
      _appendMessage(TextMessage(
        id: _nextId('m'),
        sender: ChatSender.assistant,
        text:
            "Every pick is within a 10-min detour from your calendar, hits your protein target (~120g today), and avoids sugar spikes before meetings. You can tap any meal to see the reasoning.",
      ));
    });
  }

  void _respondToFreeText(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('vegan') || lower.contains('vegetarian')) {
      _withTyping(() {
        _appendMessage(TextMessage(
          id: _nextId('m'),
          sender: ChatSender.assistant,
          text:
              "On it. I'll bias to plant-forward from now — want me to re-suggest today's meals?",
        ));
        _appendMessage(QuickRepliesMessage(
          id: _nextId('m'),
          replies: const [
            QuickReply(label: 'Re-suggest today', intent: 'swap_lunch'),
            QuickReply(label: 'Just going forward', intent: 'noop'),
          ],
        ));
      });
      return;
    }
    if (lower.contains('swap') || lower.contains('replace')) {
      _showLunchAlternatives();
      return;
    }
    _withTyping(() {
      _appendMessage(TextMessage(
        id: _nextId('m'),
        sender: ChatSender.assistant,
        text:
            "Noted. Want me to adjust today's plan, or save this for tomorrow's suggestions?",
      ));
    });
  }

  // endregion

  // region: helpers

  _Intro _introMessages(
    List<CalendarEvent> events,
    List<FoodSuggestion> suggestions,
  ) {
    final prologue = <ChatMessage>[
      TextMessage(
        id: _nextId('m'),
        sender: ChatSender.assistant,
        text: 'Good morning, Avery ☀️',
      ),
    ];
    final followUps = <ChatMessage>[
      TextMessage(
        id: _nextId('m'),
        sender: ChatSender.assistant,
        text:
            "I mapped four meals around your day — walkable, protein-forward, and aligned with your calendar.",
      ),
      DayPlanMessage(
        id: _nextId('m'),
        date: DateTime.now(),
        events: events,
        suggestions: suggestions,
        weatherEmoji: '☀️',
        weatherLabel: '73° · light breeze',
      ),
      QuickRepliesMessage(
        id: _nextId('m'),
        replies: const [
          QuickReply(label: 'Swap lunch', intent: 'swap_lunch'),
          QuickReply(label: 'Lighter dinner', intent: 'lighter_dinner'),
          QuickReply(label: 'Add snack', intent: 'add_snack'),
          QuickReply(label: 'Why these?', intent: 'why_this'),
        ],
      ),
    ];
    return _Intro(prologue: prologue, followUps: followUps);
  }

  void _appendMessage(ChatMessage m) {
    state = state.copyWith(messages: [...state.messages, m]);
  }

  void _appendAll(List<ChatMessage> ms) {
    state = state.copyWith(messages: [...state.messages, ...ms]);
  }

  void _withTyping(void Function() then,
      {Duration thinkFor = const Duration(milliseconds: 900)}) {
    final typingId = _nextId('typ');
    _appendMessage(TypingMessage(id: typingId));
    _typingTimer?.cancel();
    _typingTimer = Timer(thinkFor, () {
      state = state.copyWith(
        messages: state.messages.where((m) => m.id != typingId).toList(),
      );
      then();
    });
  }

  List<ChatMessage> _replaceDayPlan(
    List<ChatMessage> messages,
    List<FoodSuggestion> suggestions,
  ) {
    return messages.map((m) {
      if (m is DayPlanMessage) {
        return DayPlanMessage(
          id: m.id,
          date: m.date,
          events: m.events,
          suggestions: suggestions,
          weatherEmoji: m.weatherEmoji,
          weatherLabel: m.weatherLabel,
        );
      }
      return m;
    }).toList();
  }

  // endregion
}

class _Intro {
  const _Intro({required this.prologue, required this.followUps});

  final List<ChatMessage> prologue;
  final List<ChatMessage> followUps;
}

final chatControllerProvider =
    NotifierProvider<ChatController, ChatState>(ChatController.new);

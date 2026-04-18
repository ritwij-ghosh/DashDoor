import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/storage/anonymous_user_id.dart';
import '../data/calendar_backend_client.dart';

final calendarBackendClientProvider = Provider<CalendarBackendClient>((ref) {
  final client = CalendarBackendClient();
  ref.onDispose(client.close);
  return client;
});

final anonymousUserIdProvider = FutureProvider<String>((ref) {
  return AnonymousUserId.getOrCreate();
});

enum CalendarLinkPhase {
  idle,
  loading,
  openingBrowser,
  polling,
  connected,
  error,
}

@immutable
class CalendarConnectionState {
  const CalendarConnectionState({
    this.phase = CalendarLinkPhase.idle,
    this.connectedAccountId,
    this.errorMessage,
  });

  final CalendarLinkPhase phase;
  final String? connectedAccountId;
  final String? errorMessage;

  bool get isConnected => phase == CalendarLinkPhase.connected;

  CalendarConnectionState copyWith({
    CalendarLinkPhase? phase,
    String? connectedAccountId,
    String? errorMessage,
  }) {
    return CalendarConnectionState(
      phase: phase ?? this.phase,
      connectedAccountId: connectedAccountId ?? this.connectedAccountId,
      errorMessage: errorMessage,
    );
  }
}

class CalendarConnection extends Notifier<CalendarConnectionState> {
  Timer? _pollTimer;
  int _pollTicks = 0;
  static const _maxPollTicks = 60;

  @override
  CalendarConnectionState build() {
    ref.onDispose(() {
      _pollTimer?.cancel();
      _pollTimer = null;
    });
    return const CalendarConnectionState();
  }

  Future<void> refreshStatus() async {
    final userId = await ref.read(anonymousUserIdProvider.future);
    final client = ref.read(calendarBackendClientProvider);
    try {
      final s = await client.getGoogleCalendarStatus(userId);
      if (s.connected) {
        state = CalendarConnectionState(
          phase: CalendarLinkPhase.connected,
          connectedAccountId: s.connectedAccountId,
        );
      } else {
        state = state.copyWith(
          phase: CalendarLinkPhase.idle,
          connectedAccountId: s.connectedAccountId,
        );
      }
    } catch (e) {
      // Offline / server down — keep local phase; do not flip to error on refresh.
      debugPrint('Calendar status refresh failed: $e');
    }
  }

  Future<void> startLinkFlow() async {
    if (state.phase == CalendarLinkPhase.loading ||
        state.phase == CalendarLinkPhase.openingBrowser ||
        state.phase == CalendarLinkPhase.polling) {
      return;
    }

    state = CalendarConnectionState(
      phase: CalendarLinkPhase.loading,
      connectedAccountId: state.connectedAccountId,
    );

    final userId = await ref.read(anonymousUserIdProvider.future);
    final client = ref.read(calendarBackendClientProvider);

    try {
      final link = await client.requestGoogleCalendarLink(userId);
      state = state.copyWith(phase: CalendarLinkPhase.openingBrowser);

      final uri = Uri.parse(link.redirectUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        state = const CalendarConnectionState(
          phase: CalendarLinkPhase.error,
          errorMessage: 'Could not open the browser for Google sign-in.',
        );
        return;
      }

      _startPolling(userId);
    } catch (e) {
      state = CalendarConnectionState(
        phase: CalendarLinkPhase.error,
        errorMessage: _humanMessage(e),
      );
    }
  }

  void _startPolling(String userId) {
    _pollTimer?.cancel();
    _pollTicks = 0;
    state = state.copyWith(phase: CalendarLinkPhase.polling);

    final client = ref.read(calendarBackendClientProvider);
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      _pollTicks++;
      if (_pollTicks > _maxPollTicks) {
        timer.cancel();
        state = state.copyWith(
          phase: CalendarLinkPhase.error,
          errorMessage:
              'Still waiting for Google Calendar. Return here after finishing in the browser, or try again.',
        );
        return;
      }

      try {
        final s = await client.getGoogleCalendarStatus(userId);
        if (s.connected) {
          timer.cancel();
          state = CalendarConnectionState(
            phase: CalendarLinkPhase.connected,
            connectedAccountId: s.connectedAccountId,
          );
        }
      } catch (e) {
        debugPrint('Calendar poll error: $e');
      }
    });
  }

  String _humanMessage(Object e) {
    if (e is CalendarBackendException) {
      if (e.statusCode == 404 || e.statusCode == 501) {
        return 'Calendar linking is not available yet. You can skip and connect later.';
      }
      return e.message;
    }
    return 'Something went wrong. Check your connection and try again.';
  }
}

final calendarConnectionProvider =
    NotifierProvider<CalendarConnection, CalendarConnectionState>(
  CalendarConnection.new,
);

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/api_service.dart';

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
    this.oauthUrl,
    this.errorMessage,
  });

  final CalendarLinkPhase phase;
  final String? oauthUrl;
  final String? errorMessage;

  bool get isConnected => phase == CalendarLinkPhase.connected;

  CalendarConnectionState copyWith({
    CalendarLinkPhase? phase,
    String? oauthUrl,
    String? errorMessage,
  }) {
    return CalendarConnectionState(
      phase: phase ?? this.phase,
      oauthUrl: oauthUrl ?? this.oauthUrl,
      errorMessage: errorMessage,
    );
  }
}

/// Talks to the Python/FastAPI backend (`/api/v1/calendar/*`), which uses
/// Composio under the hood. Auth is carried by the Supabase JWT attached
/// inside [ApiService], so the user must be signed in before linking.
class CalendarConnection extends Notifier<CalendarConnectionState> {
  Timer? _pollTimer;
  int _pollTicks = 0;
  static const _maxPollTicks = 60; // ~2 min at 2s cadence

  @override
  CalendarConnectionState build() {
    ref.onDispose(() {
      _pollTimer?.cancel();
      _pollTimer = null;
    });
    return const CalendarConnectionState();
  }

  Future<void> refreshStatus() async {
    try {
      final connected = await ApiService.getCalendarStatus();
      if (connected) {
        state = const CalendarConnectionState(
          phase: CalendarLinkPhase.connected,
        );
      } else if (state.phase != CalendarLinkPhase.polling &&
          state.phase != CalendarLinkPhase.openingBrowser &&
          state.phase != CalendarLinkPhase.loading) {
        state = state.copyWith(phase: CalendarLinkPhase.idle);
      }
    } catch (e) {
      // Offline / backend down / not signed in — don't clobber active flows.
      debugPrint('Calendar status refresh failed: $e');
    }
  }

  Future<void> startLinkFlow() async {
    if (state.phase == CalendarLinkPhase.loading ||
        state.phase == CalendarLinkPhase.openingBrowser ||
        state.phase == CalendarLinkPhase.polling) {
      return;
    }

    state = const CalendarConnectionState(phase: CalendarLinkPhase.loading);

    try {
      final data = await ApiService.connectCalendar();
      final url = data['oauth_url'] as String?;
      final err = data['error'] as String?;
      if (url == null || url.isEmpty) {
        state = CalendarConnectionState(
          phase: CalendarLinkPhase.error,
          errorMessage: err?.isNotEmpty == true
              ? err
              : 'Backend returned no OAuth URL.',
        );
        return;
      }

      state = CalendarConnectionState(
        phase: CalendarLinkPhase.openingBrowser,
        oauthUrl: url,
      );

      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        state = CalendarConnectionState(
          phase: CalendarLinkPhase.error,
          oauthUrl: url,
          errorMessage:
              'Could not open the browser. Copy this URL manually:\n$url',
        );
        return;
      }

      _startPolling();
    } catch (e) {
      state = CalendarConnectionState(
        phase: CalendarLinkPhase.error,
        errorMessage: _humanMessage(e),
      );
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTicks = 0;
    state = state.copyWith(phase: CalendarLinkPhase.polling);

    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      _pollTicks++;
      if (_pollTicks > _maxPollTicks) {
        timer.cancel();
        state = state.copyWith(
          phase: CalendarLinkPhase.error,
          errorMessage:
              'Still waiting for Google. Finish in the browser and tap Connect again.',
        );
        return;
      }

      try {
        final connected = await ApiService.getCalendarStatus();
        if (connected) {
          timer.cancel();
          state = const CalendarConnectionState(
            phase: CalendarLinkPhase.connected,
          );
        }
      } catch (e) {
        debugPrint('Calendar poll error: $e');
      }
    });
  }

  String _humanMessage(Object e) {
    final s = e.toString();
    if (s.contains('Failed to get OAuth URL')) {
      return 'Calendar linking unavailable — check that you are signed in and that the backend has a Composio API key configured.';
    }
    return 'Something went wrong. Check your connection and try again.';
  }
}

final calendarConnectionProvider =
    NotifierProvider<CalendarConnection, CalendarConnectionState>(
  CalendarConnection.new,
);

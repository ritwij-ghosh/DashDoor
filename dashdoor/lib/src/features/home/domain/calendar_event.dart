import 'package:flutter/material.dart';

enum CalendarEventType {
  meeting,
  focus,
  personal,
  workout,
  travel,
  food,
}

@immutable
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.startHour,
    required this.endHour,
    required this.type,
    this.subtitle,
    this.location,
    this.attendees = const [],
    this.foodSuggestionId,
  });

  final String id;
  final String title;
  final String? subtitle;

  /// Decimal hours in 24h format, e.g. 9.5 == 09:30.
  final double startHour;
  final double endHour;

  final CalendarEventType type;
  final String? location;
  final List<String> attendees;

  /// Links to a [FoodSuggestion.id] when [type] is [CalendarEventType.food].
  final String? foodSuggestionId;

  double get durationHours => endHour - startHour;

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? subtitle,
    double? startHour,
    double? endHour,
    CalendarEventType? type,
    String? location,
    List<String>? attendees,
    String? foodSuggestionId,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
      type: type ?? this.type,
      location: location ?? this.location,
      attendees: attendees ?? this.attendees,
      foodSuggestionId: foodSuggestionId ?? this.foodSuggestionId,
    );
  }
}

String formatHour(double hour) {
  final whole = hour.floor();
  final mins = ((hour - whole) * 60).round();
  final hr12 = whole % 12 == 0 ? 12 : whole % 12;
  final suffix = whole >= 12 ? 'pm' : 'am';
  final mm = mins.toString().padLeft(2, '0');
  if (mins == 0) return '$hr12$suffix';
  return '$hr12:$mm$suffix';
}

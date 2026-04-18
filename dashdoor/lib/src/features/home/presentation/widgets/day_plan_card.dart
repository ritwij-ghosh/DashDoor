import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/calendar_event.dart';
import '../../domain/chat_message.dart';
import '../../domain/food_suggestion.dart';
import 'food_artwork.dart';
import 'food_detail_sheet.dart';

/// Inline day-view card — Google Calendar-style vertical timeline with food
/// suggestions highlighted as interactive events.
class DayPlanCard extends ConsumerStatefulWidget {
  const DayPlanCard({
    super.key,
    required this.message,
    required this.suggestions,
  });

  final DayPlanMessage message;
  final Map<String, FoodSuggestion> suggestions;

  @override
  ConsumerState<DayPlanCard> createState() => _DayPlanCardState();
}

class _DayPlanCardState extends ConsumerState<DayPlanCard> {
  static const double _startHour = 7.0;
  static const double _endHour = 22.0;
  static const double _pxPerHour = 72.0;

  final ScrollController _scrollCtrl = ScrollController();
  bool _didInitialScroll = false;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToNow(double nowHour) {
    if (!_scrollCtrl.hasClients) return;
    final target = ((nowHour - _startHour) * _pxPerHour) - 80;
    _scrollCtrl.animateTo(
      target.clamp(0, _scrollCtrl.position.maxScrollExtent).toDouble(),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  double get _nowHour {
    final now = DateTime.now();
    return now.hour + now.minute / 60.0;
  }

  double _effectiveNowHour() {
    final now = _nowHour;
    // Keep the preview useful at any time of day — clamp within rendered range.
    if (now < _startHour) return _startHour + 0.25;
    if (now > _endHour) return _endHour - 0.25;
    return now;
  }

  @override
  Widget build(BuildContext context) {
    final text = context.appText;
    final events = widget.message.events;
    final hoursSpan = (_endHour - _startHour);
    final timelineHeight = hoursSpan * _pxPerHour;
    final mealsCount =
        events.where((e) => e.type == CalendarEventType.food).length;
    final meetingsCount =
        events.where((e) => e.type == CalendarEventType.meeting).length;
    final travelCount =
        events.where((e) => e.type == CalendarEventType.travel).length;

    if (!_didInitialScroll) {
      _didInitialScroll = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToNow(_effectiveNowHour()),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: AppPalette.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: AppPalette.deepNavy.withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(
              date: widget.message.date,
              weatherEmoji: widget.message.weatherEmoji,
              weatherLabel: widget.message.weatherLabel,
            ),
            _SummaryStrip(
              meals: mealsCount,
              meetings: meetingsCount,
              travel: travelCount,
            ),
            _MealRail(
              suggestions: widget.message.suggestions,
              onTap: (s) => showFoodDetailSheet(context, suggestion: s),
            ),
            const Divider(height: 1, color: AppPalette.border),
            SizedBox(
              height: 380,
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  height: timelineHeight + 24,
                  child: _TimelineBody(
                    startHour: _startHour,
                    endHour: _endHour,
                    pxPerHour: _pxPerHour,
                    events: events,
                    suggestions: widget.suggestions,
                    nowHour: _nowHour,
                    onFoodTap: (s) =>
                        showFoodDetailSheet(context, suggestion: s),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: AppPalette.border),
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                _scrollToNow(_effectiveNowHour());
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.my_location_rounded,
                        size: 14, color: AppPalette.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Jump to now',
                      style: text.smallStrong.copyWith(
                        color: AppPalette.primary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.date,
    this.weatherEmoji,
    this.weatherLabel,
  });

  final DateTime date;
  final String? weatherEmoji;
  final String? weatherLabel;

  String _title(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final text = context.appText;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF704E), AppPalette.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today',
                  style: text.smallStrong
                      .copyWith(color: AppPalette.neutral500),
                ),
                Text(
                  _title(date),
                  style: text.h3.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          if (weatherEmoji != null && weatherLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppPalette.neutral100,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(weatherEmoji!,
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    weatherLabel!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppPalette.deepNavy,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.meals,
    required this.meetings,
    required this.travel,
  });

  final int meals;
  final int meetings;
  final int travel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _SummaryPill(
            icon: Icons.ramen_dining_rounded,
            label: '$meals meals',
            accent: AppPalette.primary,
          ),
          _SummaryPill(
            icon: Icons.groups_rounded,
            label: '$meetings meetings',
            accent: const Color(0xFF5B6BFF),
          ),
          if (travel > 0)
            _SummaryPill(
              icon: Icons.flight_takeoff_rounded,
              label: '$travel flight${travel == 1 ? '' : 's'}',
              accent: const Color(0xFF8F70FF),
            ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealRail extends StatelessWidget {
  const _MealRail({required this.suggestions, required this.onTap});

  final List<FoodSuggestion> suggestions;
  final void Function(FoodSuggestion) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ShaderMask(
        shaderCallback: (rect) {
          return const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            stops: [0.0, 0.03, 0.92, 1.0],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 4, 32, 16),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final s = suggestions[i];
            return _MealRailCard(suggestion: s, onTap: () => onTap(s));
          },
        ),
      ),
    );
  }
}

class _MealRailCard extends StatelessWidget {
  const _MealRailCard({required this.suggestion, required this.onTap});

  final FoodSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppPalette.creamBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppPalette.border),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: Hero(
                tag: 'food_artwork_rail_${suggestion.id}',
                child: FoodArtwork(suggestion: suggestion, radius: 14),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    suggestion.slot.label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.primary,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    suggestion.restaurant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppPalette.deepNavy,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatHour(suggestion.windowStart)} · ${suggestion.nutrition.calories} cal',
                    style: const TextStyle(
                      color: AppPalette.neutral500,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineBody extends StatelessWidget {
  const _TimelineBody({
    required this.startHour,
    required this.endHour,
    required this.pxPerHour,
    required this.events,
    required this.suggestions,
    required this.nowHour,
    required this.onFoodTap,
  });

  final double startHour;
  final double endHour;
  final double pxPerHour;
  final List<CalendarEvent> events;
  final Map<String, FoodSuggestion> suggestions;
  final double nowHour;
  final void Function(FoodSuggestion) onFoodTap;

  static const double _leftGutter = 56;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          for (int h = startHour.toInt(); h <= endHour.toInt(); h++)
            _hourRow(h),
          for (final event in events) _eventTile(event),
          if (nowHour >= startHour && nowHour <= endHour) _nowLine(),
        ],
      ),
    );
  }

  Widget _hourRow(int hour) {
    final top = (hour - startHour) * pxPerHour;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _leftGutter,
            child: Text(
              formatHour(hour.toDouble()),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppPalette.neutral500,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppPalette.border.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                child: const SizedBox(height: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventTile(CalendarEvent event) {
    final top = (event.startHour - startHour) * pxPerHour;
    final rawHeight = event.durationHours * pxPerHour;
    // Give every tile a sensible minimum so the smallest slots still look good,
    // and leave a small gap above/below adjacent events.
    final height = rawHeight.clamp(34.0, double.infinity) - 3;
    if (event.type == CalendarEventType.food) {
      final suggestion =
          event.foodSuggestionId == null ? null : suggestions[event.foodSuggestionId];
      return Positioned(
        top: top + 2,
        height: height,
        left: _leftGutter + 10,
        right: 4,
        child: _FoodEventTile(
          event: event,
          suggestion: suggestion,
          onTap: suggestion == null ? null : () => onFoodTap(suggestion),
        ),
      );
    }
    return Positioned(
      top: top + 2,
      height: height,
      left: _leftGutter + 10,
      right: 4,
      child: _StandardEventTile(event: event),
    );
  }

  Widget _nowLine() {
    final top = (nowHour - startHour) * pxPerHour;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _leftGutter,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppPalette.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    formatHour(nowHour),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: AppPalette.primary,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StandardEventTile extends StatelessWidget {
  const _StandardEventTile({required this.event});
  final CalendarEvent event;

  Color get _bg {
    switch (event.type) {
      case CalendarEventType.meeting:
        return const Color(0xFFEDEEFF);
      case CalendarEventType.focus:
        return const Color(0xFFE8F6EC);
      case CalendarEventType.workout:
        return const Color(0xFFFFF2E4);
      case CalendarEventType.travel:
        return const Color(0xFFEEE9FF);
      case CalendarEventType.personal:
        return const Color(0xFFF5F5F1);
      case CalendarEventType.food:
        return AppPalette.primary.withValues(alpha: 0.16);
    }
  }

  Color get _accent {
    switch (event.type) {
      case CalendarEventType.meeting:
        return const Color(0xFF5B6BFF);
      case CalendarEventType.focus:
        return const Color(0xFF3AC47D);
      case CalendarEventType.workout:
        return const Color(0xFFFB7D5B);
      case CalendarEventType.travel:
        return const Color(0xFF8F70FF);
      case CalendarEventType.personal:
        return AppPalette.neutral500;
      case CalendarEventType.food:
        return AppPalette.primary;
    }
  }

  IconData get _icon {
    switch (event.type) {
      case CalendarEventType.meeting:
        return Icons.groups_rounded;
      case CalendarEventType.focus:
        return Icons.edit_note_rounded;
      case CalendarEventType.workout:
        return Icons.directions_run_rounded;
      case CalendarEventType.travel:
        return Icons.flight_takeoff_rounded;
      case CalendarEventType.personal:
        return Icons.event_rounded;
      case CalendarEventType.food:
        return Icons.restaurant_rounded;
    }
  }

  String get _timeLabel =>
      '${formatHour(event.startHour)} – ${formatHour(event.endHour)}';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight;
        // Layout tier selection based on real allocated height.
        final micro = h < 40; // single line, just title + tiny time
        final compact = !micro && h < 62; // title + time, tight padding
        final vPad = micro ? 4.0 : (compact ? 7.0 : 10.0);

        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: vPad),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(14),
              border: Border(left: BorderSide(color: _accent, width: 3)),
            ),
            child: Row(
              crossAxisAlignment: micro
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Icon(_icon, size: micro ? 12 : 14, color: _accent),
                const SizedBox(width: 8),
                Expanded(
                  child: micro
                      ? _microRow()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: compact
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppPalette.deepNavy,
                                fontSize: compact ? 12.5 : 13,
                                height: 1.15,
                              ),
                            ),
                            SizedBox(height: compact ? 1 : 2),
                            Text(
                              event.subtitle != null && !compact
                                  ? '$_timeLabel · ${event.subtitle}'
                                  : _timeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppPalette.neutral500,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _microRow() {
    return Row(
      children: [
        Flexible(
          child: Text(
            event.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppPalette.deepNavy,
              fontSize: 12,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          formatHour(event.startHour),
          maxLines: 1,
          style: const TextStyle(
            color: AppPalette.neutral500,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class _FoodEventTile extends StatelessWidget {
  const _FoodEventTile({
    required this.event,
    required this.suggestion,
    required this.onTap,
  });

  final CalendarEvent event;
  final FoodSuggestion? suggestion;
  final VoidCallback? onTap;

  String get _timeLabel =>
      '${formatHour(event.startHour)} – ${formatHour(event.endHour)}';
  String get _slotLabel =>
      (suggestion?.slot.label ?? event.title).toUpperCase();
  String get _restaurant => suggestion?.restaurant ?? event.title;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight;
        final micro = h < 46; // ultra-short slot: 1 line
        final compact = !micro && h < 82; // 2-line: name + time
        final pad = micro ? 6.0 : (compact ? 7.0 : 9.0);
        final imageSize = micro ? 0.0 : (compact ? 32.0 : 42.0);
        final radius = micro ? 12.0 : 14.0;

        return InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: pad + 1,
                vertical: pad,
              ),
              decoration: BoxDecoration(
                color: AppPalette.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: AppPalette.primary.withValues(alpha: 0.4),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.primary.withValues(alpha: 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: micro
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.center,
                children: [
                  if (imageSize > 0) ...[
                    SizedBox(
                      width: imageSize,
                      height: imageSize,
                      child: suggestion != null
                          ? FoodArtwork(
                              suggestion: suggestion!,
                              radius: imageSize * 0.28,
                              showGlyph: false,
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: AppPalette.primary,
                                borderRadius:
                                    BorderRadius.circular(imageSize * 0.28),
                              ),
                              child: Icon(Icons.restaurant_rounded,
                                  color: Colors.white,
                                  size: imageSize * 0.42),
                            ),
                    ),
                    SizedBox(width: pad + 2),
                  ],
                  Expanded(
                    child: micro
                        ? _microBody()
                        : compact
                            ? _compactBody()
                            : _fullBody(),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded,
                      color: AppPalette.deepNavy.withValues(alpha: 0.85),
                      size: micro ? 16 : 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _slotPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppPalette.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _slotLabel,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 9,
          color: Colors.white,
          letterSpacing: 0.8,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _microBody() {
    // Single compressed line: pill + restaurant + time
    return Row(
      children: [
        _slotPill(),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            _restaurant,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppPalette.deepNavy,
              fontSize: 12,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          formatHour(event.startHour),
          maxLines: 1,
          style: const TextStyle(
            color: AppPalette.neutral500,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
      ],
    );
  }

  Widget _compactBody() {
    // Two lines: pill + time, then restaurant name.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _slotPill(),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _timeLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppPalette.neutral500,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          _restaurant,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AppPalette.deepNavy,
            fontSize: 13.5,
            height: 1.15,
          ),
        ),
      ],
    );
  }

  Widget _fullBody() {
    final s = suggestion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            _slotPill(),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _timeLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppPalette.neutral500,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          _restaurant,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AppPalette.deepNavy,
            fontSize: 14,
            height: 1.15,
          ),
        ),
        if (s != null) ...[
          const SizedBox(height: 2),
          Text(
            '${s.nutrition.calories} cal · ${s.nutrition.protein}g protein',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppPalette.neutral500,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';

class AppSidebar extends ConsumerStatefulWidget {
  const AppSidebar({super.key});

  @override
  ConsumerState<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends ConsumerState<AppSidebar> {
  List<Map<String, dynamic>> _recommendations = [];
  List<Map<String, dynamic>> _mealScores = [];
  Map<String, dynamic> _profile = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getRecommendations(),
        ApiService.getMealScores(),
        ApiService.getProfile(),
      ]);
      if (mounted) {
        setState(() {
          _recommendations = results[0] as List<Map<String, dynamic>>;
          _mealScores = results[1] as List<Map<String, dynamic>>;
          _profile = results[2] as Map<String, dynamic>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = _profile['name'] as String? ??
        user?.email?.split('@').first ??
        'User';

    return Drawer(
      backgroundColor: AppPalette.creamBackground,
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Header
                  _SidebarHeader(
                    name: name,
                    email: user?.email,
                    onRefresh: _load,
                    isLoading: _loading,
                  ),

                  const SizedBox(height: 8),

                  // Upcoming Meal Plans
                  const _SectionHeader(title: 'Upcoming Meal Plan'),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else if (_recommendations.isEmpty)
                    const _EmptyState(
                      icon: Icons.restaurant_menu_rounded,
                      message: 'No plan yet — ask the AI to plan your meals!',
                    )
                  else
                    ..._buildMealCards(),

                  const SizedBox(height: 8),

                  // Past Meals with scores
                  const _SectionHeader(title: 'Past Meals'),
                  if (_mealScores.isEmpty)
                    const _EmptyState(
                      icon: Icons.star_border_rounded,
                      message: 'Rate meals to improve future recommendations.',
                    )
                  else
                    ..._buildScoreItems(),

                  const SizedBox(height: 8),

                  // Integrations
                  const _SectionHeader(title: 'Integrations'),
                  _IntegrationTile(
                    icon: Icons.calendar_month_rounded,
                    title: 'Google Calendar',
                    subtitle: 'Schedule-aware meal timing',
                    onTap: () => _connectCalendar(context),
                  ),
                  _IntegrationTile(
                    icon: Icons.location_on_rounded,
                    title: 'Set Location',
                    subtitle: 'For nearby restaurant suggestions',
                    onTap: () => _setLocation(context),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),

            // Sign Out
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppPalette.border)),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.logout_rounded,
                  color: AppPalette.primary,
                ),
                title: Text(
                  'Sign Out',
                  style: context.appText.bodyStrong.copyWith(
                    color: AppPalette.primary,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await Supabase.instance.client.auth.signOut();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMealCards() {
    final rec = _recommendations.first;
    final recsJson = rec['recommendations_json'];
    List<dynamic> meals = [];
    if (recsJson is Map) {
      meals = (recsJson['recommendations'] as List?) ?? [];
    }
    return meals.take(5).map((meal) {
      if (meal is! Map) return const SizedBox.shrink();
      return _MealPlanCard(
        meal: Map<String, dynamic>.from(meal),
        recommendationId: rec['id'] as String?,
      );
    }).toList();
  }

  List<Widget> _buildScoreItems() {
    return _mealScores
        .take(8)
        .map((s) => _PastMealItem(score: s))
        .toList();
  }

  Future<void> _connectCalendar(BuildContext ctx) async {
    try {
      final data = await ApiService.connectCalendar();
      final url = data['oauth_url'] as String?;
      if (url != null && ctx.mounted) {
        showDialog(
          context: ctx,
          builder: (c) => AlertDialog(
            title: const Text('Connect Google Calendar'),
            content: SelectableText(
              'Open this URL in your browser to authorize:\n\n$url',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _setLocation(BuildContext ctx) async {
    final cityCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    await showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('Set Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cityCtrl,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Travel note (optional)',
                hintText: 'e.g. landing in Denver at 8pm',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (cityCtrl.text.trim().isNotEmpty) {
                await ApiService.setLocation(
                  city: cityCtrl.text.trim(),
                  travelNote: noteCtrl.text.trim().isEmpty
                      ? null
                      : noteCtrl.text.trim(),
                );
              }
              if (c.mounted) Navigator.pop(c);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  final String name;
  final String? email;
  final VoidCallback onRefresh;
  final bool isLoading;

  const _SidebarHeader({
    required this.name,
    this.email,
    required this.onRefresh,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: AppPalette.surfaceWhite,
        border: Border(bottom: BorderSide(color: AppPalette.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppPalette.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: context.appText.h3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: context.appText.bodyStrong.copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email != null)
                  Text(
                    email!,
                    style: context.appText.small.copyWith(
                      color: AppPalette.neutral500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: AppPalette.neutral500,
                  ),
                  onPressed: onRefresh,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
        ],
      ),
    );
  }
}

class _MealPlanCard extends StatelessWidget {
  final Map<String, dynamic> meal;
  final String? recommendationId;

  const _MealPlanCard({required this.meal, this.recommendationId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (meal['when_to_eat'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppPalette.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    meal['when_to_eat'] as String,
                    style: context.appText.caption.copyWith(
                      color: AppPalette.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              if (meal['calories'] != null) ...[
                const SizedBox(width: 8),
                Text(
                  '${meal['calories']} cal',
                  style: context.appText.caption.copyWith(
                    color: AppPalette.neutral500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            meal['name'] as String? ?? '',
            style: context.appText.bodyStrong.copyWith(fontSize: 14),
          ),
          if (meal['why'] != null) ...[
            const SizedBox(height: 4),
            Text(
              meal['why'] as String,
              style: context.appText.small.copyWith(
                color: AppPalette.neutral500,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 10),
          _StarRating(
            mealName: meal['name'] as String? ?? 'Meal',
            recommendationId: recommendationId,
          ),
        ],
      ),
    );
  }
}

class _StarRating extends StatefulWidget {
  final String mealName;
  final String? recommendationId;

  const _StarRating({required this.mealName, this.recommendationId});

  @override
  State<_StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<_StarRating> {
  int _selected = 0;
  bool _saved = false;

  Future<void> _rate(int score) async {
    setState(() => _selected = score);
    try {
      await ApiService.scoreMeal(
        mealName: widget.mealName,
        score: score,
        recommendationId: widget.recommendationId,
      );
      if (mounted) setState(() => _saved = true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_saved) {
      return Text(
        'Rated — thanks!',
        style: context.appText.caption.copyWith(color: AppPalette.successMint),
      );
    }
    return Row(
      children: [
        Text(
          'Rate: ',
          style: context.appText.caption.copyWith(color: AppPalette.neutral500),
        ),
        ...List.generate(
          5,
          (i) => GestureDetector(
            onTap: () => _rate(i + 1),
            child: Icon(
              _selected > i ? Icons.star_rounded : Icons.star_border_rounded,
              color: AppPalette.sunRewards,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class _PastMealItem extends StatelessWidget {
  final Map<String, dynamic> score;
  const _PastMealItem({required this.score});

  @override
  Widget build(BuildContext context) {
    final rating = score['score'] as int? ?? 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppPalette.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  score['meal_name'] as String? ?? '',
                  style: context.appText.small.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (score['notes'] != null)
                  Text(
                    score['notes'] as String,
                    style: context.appText.caption.copyWith(
                      color: AppPalette.neutral500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                color: AppPalette.sunRewards,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Text(
        title.toUpperCase(),
        style: context.appText.caption.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w800,
          color: AppPalette.neutral500,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppPalette.neutral400),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: context.appText.small.copyWith(
                color: AppPalette.neutral500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntegrationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _IntegrationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppPalette.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppPalette.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppPalette.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppPalette.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.appText.smallStrong),
                  Text(
                    subtitle,
                    style: context.appText.caption.copyWith(
                      color: AppPalette.neutral500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppPalette.neutral400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

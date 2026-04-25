import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/api_service.dart';

final _analyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await ApiService().get('/analytics');
  return response.data['data'];
});

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(_analyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Campus Insights', style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Inter')),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => ref.refresh(_analyticsProvider)),
        ],
      ),
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          return ListView(
            padding: const EdgeInsets.all(AppDimens.paddingMd),
            children: [
              // ─── Top Row: Leaderboard ───────────────────────────────────
              _ChartCard(
                title: 'Class Leaderboard',
                subtitle: 'Classes ranked by overall student activity points.',
                child: _ClassLeaderboard(data: data['studentActivityByClass'] as List? ?? []),
              ),
              const SizedBox(height: 20),

              // ─── Submission Progress ─────────────────────────────────────
              _ChartCard(
                title: 'Submission Progress',
                subtitle: 'Submissions vs Teacher Approvals across classes.',
                child: _AssignmentStatsList(data: data['assignmentStatsByClass'] as List? ?? []),
              ),
              const SizedBox(height: 20),

              // ─── Communication ──────────────────────────────────────────
              _ChartCard(
                title: 'Communication Success',
                subtitle: 'Percentage of notices actually read by students.',
                child: _NoticeReadRate(data: data['noticeReadRates'] as List? ?? []),
              ),
              const SizedBox(height: 20),

              // ─── Top Contributors ───────────────────────────────────────
              _ChartCard(
                title: 'Top Contributors',
                subtitle: 'Teachers most active in publishing academic content.',
                child: _TeacherList(data: data['topTeachers'] as List? ?? []),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _ChartCard({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontFamily: 'Inter')),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontFamily: 'Inter')),
        const SizedBox(height: 20),
        child,
      ]),
    );
  }
}

class _NoticeReadRate extends StatelessWidget {
  final List<dynamic> data;
  const _NoticeReadRate({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('Not enough data', style: TextStyle(color: AppColors.textHint, fontFamily: 'Inter')));
    return Column(children: data.map((item) {
      final rate = (item['readRate'] as num).toDouble() / 100.0;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(item['_id'] ?? 'General', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Inter')),
            Text('${item['readRate']}%', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate,
              backgroundColor: AppColors.primaryContainer,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ]),
      );
    }).toList());
  }
}

class _AssignmentStatsList extends StatelessWidget {
  final List<dynamic> data;
  const _AssignmentStatsList({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox(height: 100, child: Center(child: Text('No submission data yet', style: TextStyle(color: AppColors.textHint, fontFamily: 'Inter'))));

    return Column(children: data.map((item) {
      final className = item['_id'] as String? ?? 'Other';
      final submitted = item['submitted'] as int;
      final approved = item['approved'] as int;

      return InkWell(
        onTap: () => context.push('/admin-class-analytics/${Uri.encodeComponent(className)}'),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(className, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Inter')),
              Text('$submitted submitted • $approved approved', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Inter')),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: LinearProgressIndicator(
                  value: submitted > 0 ? approved / submitted : 0,
                  backgroundColor: AppColors.divider.withOpacity(0.5),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                ),
              ),
            ),
          ]),
        ),
      );
    }).toList());
  }
}

class _TeacherList extends StatelessWidget {
  final List<dynamic> data;
  const _TeacherList({required this.data});
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No data', style: TextStyle(color: AppColors.textHint, fontFamily: 'Inter')));
    return Column(children: data.take(5).map((t) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        CircleAvatar(radius: 18, backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=${Uri.encodeComponent(t['name'] ?? '')}&background=00897B&color=fff&size=64'), backgroundColor: AppColors.primaryContainer),
        const SizedBox(width: 12),
        Expanded(child: Text(t['name'] ?? '', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 13))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(AppDimens.radiusFull)),
          child: Text('${t['count']} sent', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary, fontFamily: 'Inter')),
        ),
      ]),
    )).toList());
  }
}

class _ClassLeaderboard extends StatelessWidget {
  final List<dynamic> data;
  const _ClassLeaderboard({required this.data});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> fullList = data.map((e) => {
      'name': e['_id'] as String? ?? 'Other',
      'count': (e['count'] as num).toInt(),
    }).toList();
    fullList.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    if (fullList.isEmpty) {
      return const SizedBox(height: 100, child: Center(child: Text('Awaiting first interactions...', style: TextStyle(color: AppColors.textHint, fontFamily: 'Inter'))));
    }

    return Column(children: fullList.asMap().entries.map((entry) {
      final idx = entry.key;
      final item = entry.value;
      final name = item['name'] as String;
      final count = item['count'] as int;

      Color rankColor = AppColors.textSecondary;
      IconData? rankIcon;
      if (idx == 0 && count > 0) { rankColor = const Color(0xFFFFD700); rankIcon = Icons.emoji_events_rounded; }
      else if (idx == 1 && count > 0) { rankColor = const Color(0xFFC0C0C0); rankIcon = Icons.emoji_events_rounded; }
      else if (idx == 2 && count > 0) { rankColor = const Color(0xFFCD7F32); rankIcon = Icons.emoji_events_rounded; }

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: idx < 3 && count > 0 ? rankColor.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: idx < 3 && count > 0 ? rankColor.withOpacity(0.2) : Colors.transparent),
        ),
        child: Row(children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: idx < 3 && count > 0 ? rankColor : AppColors.divider.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Text('${idx + 1}', style: TextStyle(color: idx < 3 && count > 0 ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Inter'))),
          if (rankIcon != null) Padding(padding: const EdgeInsets.only(right: 12), child: Icon(rankIcon, color: rankColor, size: 20)),
          Text('$count pts', style: TextStyle(fontWeight: FontWeight.w800, color: idx < 3 && count > 0 ? rankColor : AppColors.textHint, fontSize: 13)),
        ]),
      );
    }).toList());
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
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
      appBar: AppBar(
        title: const Text('Analytics'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => ref.invalidate(_analyticsProvider))],
      ),
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => ListView(
          padding: const EdgeInsets.all(AppDimens.paddingMd),
          children: [
            // ─── Summary Tiles ──────────────────────────────────────────
            Row(
              children: [
                Expanded(child: _SummaryTile(label: 'Total Users', value: '${data['totalUsers'] ?? 0}', icon: Icons.people_outline, color: AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: _SummaryTile(label: 'Total Notices', value: '${data['totalReminders'] ?? 0}', icon: Icons.campaign_outlined, color: AppColors.accent)),
              ],
            ),
            const SizedBox(height: 16),
            // ─── Notification Read Rate Pie ─────────────────────────────
            _ChartCard(
              title: 'Engagement: Read vs Unread',
              child: _ReadRatePie(data: data['notificationReadRate'] as List? ?? []),
            ),
            const SizedBox(height: 16),
            // ─── Reminders by Priority ──────────────────────────────────
            _ChartCard(
              title: 'Distribution by Priority',
              child: _PriorityBar(data: data['remindersByPriority'] as List? ?? []),
            ),
            const SizedBox(height: 16),
            // ─── Top Active Teachers ────────────────────────────────────
            _ChartCard(
              title: 'Most Active Teachers',
              child: _TeacherList(data: data['topActiveTeachers'] as List? ?? []),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppDimens.radiusLg), border: Border.all(color: AppColors.divider), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: AppColors.textPrimary)),
      const SizedBox(height: 20),
      child,
    ]),
  );
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryTile({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(AppDimens.radiusLg), border: Border.all(color: color.withOpacity(0.1))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 12),
      Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color, fontFamily: 'Inter')),
      Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8), fontWeight: FontWeight.w500, fontFamily: 'Inter')),
    ]),
  );
}

class _ReadRatePie extends StatelessWidget {
  final List<dynamic> data;
  const _ReadRatePie({required this.data});

  @override
  Widget build(BuildContext context) {
    int read = 0, unread = 0;
    for (final item in data) {
      if (item['_id'] == true) read = item['count'] ?? 0;
      else unread = item['count'] ?? 0;
    }
    final total = read + unread;
    if (total == 0) return const Center(child: Text('No data', style: TextStyle(color: AppColors.textHint, fontFamily: 'Inter')));

    return SizedBox(
      height: 180,
      child: Row(children: [
        Expanded(
          child: PieChart(PieChartData(
            sections: [
              PieChartSectionData(value: read.toDouble(), color: AppColors.success, title: '${(read / total * 100).toStringAsFixed(0)}%', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
              PieChartSectionData(value: unread.toDouble(), color: AppColors.divider, title: '${(unread / total * 100).toStringAsFixed(0)}%', titleStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
            ],
            centerSpaceRadius: 40,
          )),
        ),
        Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Legend(color: AppColors.success, label: 'Read: $read'),
          const SizedBox(height: 8),
          _Legend(color: AppColors.divider, label: 'Unread: $unread'),
        ]),
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(fontSize: 13, fontFamily: 'Inter')),
  ]);
}

class _PriorityBar extends StatelessWidget {
  final List<dynamic> data;
  const _PriorityBar({required this.data});

  @override
  Widget build(BuildContext context) {
    final priorities = {'normal': 0, 'important': 0, 'urgent': 0};
    for (final item in data) {
      priorities[item['_id']] = item['count'] ?? 0;
    }
    final maxVal = priorities.values.reduce((a, b) => a > b ? a : b).toDouble();

    return SizedBox(
      height: 140,
      child: BarChart(BarChartData(
        maxY: maxVal > 0 ? maxVal * 1.2 : 10,
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: priorities['normal']!.toDouble(), color: AppColors.primary, width: 32, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: priorities['important']!.toDouble(), color: AppColors.accent, width: 32, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: priorities['urgent']!.toDouble(), color: AppColors.error, width: 32, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
            final labels = ['Normal', 'Important', 'Urgent'];
            return Text(labels[v.toInt()], style: const TextStyle(fontSize: 10, fontFamily: 'Inter', color: AppColors.textHint));
          })),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10, fontFamily: 'Inter', color: AppColors.textHint)))),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
      )),
    );
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

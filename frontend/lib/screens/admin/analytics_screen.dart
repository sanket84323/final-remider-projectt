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
        title: const Text('Department Performance', style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Inter')),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => ref.refresh(_analyticsProvider)),
        ],
      ),
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => _AnalyticsBody(data: data),
      ),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AnalyticsBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final assignmentStats = (data['assignmentStatsByClass'] as List?) ?? [];
    final notificationStats = (data['classMostNotificationsRead'] as List?) ?? [];
    final teacherStats = (data['topTeachers'] as List?) ?? [];
    final globalStats = data['globalStats'] ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── Dual KPI Row ──────────────────────────────────────────
        Row(
          children: [
            Expanded(child: _buildKPI(context, 'Read Rate', '${globalStats['readRate'] ?? 0}%', Icons.mark_email_read_rounded, const Color(0xFF6366F1))),
            const SizedBox(width: 12),
            Expanded(child: _buildKPI(context, 'Submission', '${globalStats['submissionRate'] ?? 0}%', Icons.task_alt_rounded, const Color(0xFF10B981))),
          ],
        ),
        const SizedBox(height: 24),

        // ─── Submissions Bar Chart ──────────────────────────────────
        _buildChartCard(
          context,
          'Top Classes by Submissions',
          'Classes with highest assignment completion volume',
          _buildSubmissionsBarChart(context, assignmentStats),
        ),
        const SizedBox(height: 24),

        // ─── Notifications Pie Chart ────────────────────────────────
        _buildChartCard(
          context,
          'Engagement by Class',
          'Percentage of notifications read per class',
          _buildNotificationsPie(notificationStats),
        ),
        const SizedBox(height: 24),

        // ─── Teacher Activity Bar Chart ─────────────────────────────
        _buildChartCard(
          context,
          'Faculty Activity Leaderboard',
          'Teachers with most published academic content',
          _buildTeachersChart(context, teacherStats),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildKPI(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 12),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color, fontFamily: 'Inter')),
        Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodySmall?.color, letterSpacing: 0.5)),
      ]),
    );
  }

  Widget _buildChartCard(BuildContext context, String title, String subtitle, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.titleLarge?.color, fontFamily: 'Inter')),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color, fontFamily: 'Inter')),
          const SizedBox(height: 32),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _buildSubmissionsBarChart(BuildContext context, List stats) {
    if (stats.isEmpty) return const Center(child: Text('No data'));
    final allData = stats;
    final chartWidth = (allData.length * 60.0).clamp(MediaQuery.of(context).size.width - 64, 2000.0);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: chartWidth,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: allData.fold(0.0, (m, s) => (s['submitted'] as num).toDouble() > m ? (s['submitted'] as num).toDouble() : m) * 1.2,
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, m) {
                    if (v.toInt() < 0 || v.toInt() >= allData.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(allData[v.toInt()]['_id'] ?? '?', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                    );
                  },
                ),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: allData.asMap().entries.map((e) => BarChartGroupData(
              x: e.key,
              barRods: [BarChartRodData(toY: (e.value['submitted'] as num).toDouble(), color: const Color(0xFF6366F1), width: 20, borderRadius: BorderRadius.circular(4))],
            )).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsPie(List stats) {
    if (stats.isEmpty) return const Center(child: Text('No data'));
    final allData = stats;
    final colors = [
      const Color(0xFF6366F1), const Color(0xFFF59E0B), const Color(0xFF10B981), const Color(0xFFEC4899),
      const Color(0xFF8B5CF6), const Color(0xFF06B6D4), const Color(0xFFF43F5E), const Color(0xFF10B981)
    ];
    
    return Row(children: [
      Expanded(child: PieChart(PieChartData(
        sections: allData.asMap().entries.map((e) => PieChartSectionData(
          color: colors[e.key % colors.length],
          value: (e.value['readCount'] as num).toDouble(),
          radius: 40,
          title: '',
        )).toList(),
      ))),
      const SizedBox(width: 20),
      Expanded(child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: allData.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[e.key % colors.length], shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(e.value['_id'] ?? 'Other', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            ]),
          )).toList(),
        ),
      )),
    ]);
  }

  Widget _buildTeachersChart(BuildContext context, List stats) {
    if (stats.isEmpty) return const Center(child: Text('No data'));
    final allData = stats;
    final chartWidth = (allData.length * 80.0).clamp(MediaQuery.of(context).size.width - 64, 3000.0);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: chartWidth,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: allData.fold(0.0, (m, s) => (s['count'] as num).toDouble() > m ? (s['count'] as num).toDouble() : m) * 1.2,
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, m) {
                    if (v.toInt() < 0 || v.toInt() >= allData.length) return const SizedBox();
                    final name = allData[v.toInt()]['name'] ?? 'T';
                    return Padding(padding: const EdgeInsets.only(top: 8), child: Text(name.split(' ').first, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)));
                  },
                ),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: allData.asMap().entries.map((e) => BarChartGroupData(
              x: e.key,
              barRods: [BarChartRodData(toY: (e.value['count'] as num).toDouble(), color: const Color(0xFFF59E0B), width: 24, borderRadius: BorderRadius.circular(6))],
            )).toList(),
          ),
        ),
      ),
    );
  }
}

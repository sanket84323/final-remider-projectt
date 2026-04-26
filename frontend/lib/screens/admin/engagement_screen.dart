import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/api_service.dart';

final _engagementProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await ApiService().get('/analytics');
  return response.data['data'];
});

class EngagementScreen extends ConsumerWidget {
  const EngagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engagementAsync = ref.watch(_engagementProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('User Engagement', style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Inter')),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: engagementAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final readRate = data['noticeReadRates']?[0]?['readRate'] ?? 0;
          final activityByDay = data['activityByDay'] as List? ?? [];
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ─── Big Read Rate Circle ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF673AB7), Color(0xFF9575CD)]),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: const Color(0xFF673AB7).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Row(children: [
                  Stack(alignment: Alignment.center, children: [
                    SizedBox(
                      width: 80, height: 80,
                      child: CircularProgressIndicator(value: readRate / 100, strokeWidth: 8, backgroundColor: Colors.white.withOpacity(0.2), valueColor: const AlwaysStoppedAnimation(Colors.white)),
                    ),
                    Text('$readRate%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                  ]),
                  const SizedBox(width: 24),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Overall Engagement', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    const Text('Students are actively reading your announcements.', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500, height: 1.3)),
                  ])),
                ]),
              ),

              const SizedBox(height: 32),

              // ─── Activity Chart ────────────────────────────────────────
              const Text('Weekly Participation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Inter', color: Color(0xFF1A237E))),
              const SizedBox(height: 16),
              Container(
                height: 240,
                padding: const EdgeInsets.fromLTRB(10, 24, 24, 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.black.withOpacity(0.05), strokeWidth: 1)),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, meta) {
                        if (v.toInt() < 0 || v.toInt() >= activityByDay.length) return const Text('');
                        return Padding(padding: const EdgeInsets.only(top: 8), child: Text(activityByDay[v.toInt()]['_id'].toString().substring(8), style: const TextStyle(fontSize: 10, color: Colors.grey)));
                      })),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: activityByDay.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['count'] as num).toDouble())).toList(),
                        isCurved: true,
                        color: const Color(0xFF673AB7),
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: true, color: const Color(0xFF673AB7).withOpacity(0.1)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ─── Active Categories ──────────────────────────────────────
              const Text('Hot Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Inter', color: Color(0xFF1A237E))),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: [
                  _CategoryChip(label: 'Events', count: '12', color: Colors.blue),
                  _CategoryChip(label: 'Academic', count: '45', color: Colors.orange),
                  _CategoryChip(label: 'Urgent', count: '05', color: Colors.red),
                  _CategoryChip(label: 'Placement', count: '08', color: Colors.green),
                ],
              ),
              const SizedBox(height: 40),
            ]),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final String count;
  final Color color;
  const _CategoryChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2))),
    child: Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      Text(count, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: color)),
    ]),
  );
}

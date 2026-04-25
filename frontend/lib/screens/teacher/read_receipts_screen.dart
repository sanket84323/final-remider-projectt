import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../core/constants/app_constants.dart';
import '../../data/repositories/repositories.dart';

final _readReceiptsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, reminderId) async {
  return ReminderRepository().getReadReceipts(reminderId);
});

class ReadReceiptsScreen extends ConsumerWidget {
  final String reminderId;
  const ReadReceiptsScreen({super.key, required this.reminderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(_readReceiptsProvider(reminderId));
    return Scaffold(
      appBar: AppBar(title: const Text('Read Receipts'), leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop())),
      body: receiptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final receipts = data['receipts'] as List? ?? [];
          final readCount = data['readCount'] ?? 0;
          final total = data['totalTargeted'] ?? 0;
          final rate = double.tryParse(data['readRate']?.toString() ?? '0') ?? 0;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── Summary Card ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)]),
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                ),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _StatItem(label: 'Read', value: '$readCount', color: Colors.white),
                    _StatItem(label: 'Total', value: '$total', color: Colors.white70),
                    _StatItem(label: 'Rate', value: '$rate%', color: Colors.white),
                  ]),
                  const SizedBox(height: 16),
                  LinearPercentIndicator(
                    lineHeight: 8,
                    percent: (rate / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.white24,
                    progressColor: Colors.white,
                    barRadius: const Radius.circular(4),
                    padding: EdgeInsets.zero,
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              const Text('Students who read', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
              const SizedBox(height: 12),
              ...List.generate(receipts.length, (i) {
                final receipt = receipts[i];
                final user = receipt['userId'];
                final readAt = DateTime.tryParse(receipt['readAt'] ?? '');
                return ListTile(
                  leading: CircleAvatar(backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=${Uri.encodeComponent(user?['name'] ?? '')}&background=1565C0&color=fff'), radius: 20),
                  title: Text(user?['name'] ?? 'Unknown', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14)),
                  subtitle: Text('${user?['className'] ?? ''} · Sec ${user?['section'] ?? ''}', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textHint)),
                  trailing: readAt != null
                      ? Text(DateFormat('d MMM, h:mm a').format(readAt), style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontFamily: 'Inter'))
                      : null,
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color, fontFamily: 'Inter')),
    Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8), fontFamily: 'Inter')),
  ]);
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../../providers/task_provider.dart';
import '../../utils/constants.dart';
import '../../config/theme.dart';

class TaskDetailScreen extends ConsumerWidget {
  final int taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(taskProvider);
    final task = state.tasks.where((t) => t.id == taskId).firstOrNull;

    if (task == null) {
      return Scaffold(appBar: AppBar(title: const Text('任务详情')), body: const Center(child: Text('任务未找到')));
    }

    final statusLabel = statusLabels[task.status] ?? task.status;
    final statusColor = statusColors[task.status] ?? Colors.grey;
    final captcha = state.currentCaptcha;
    final isTrain = task.showName.contains('G') || task.showName.contains('D');

    return Scaffold(
      appBar: AppBar(
        title: const Text('任务详情'),
        actions: [
          if (task.status == 'pending' || task.status == 'scheduled' || task.status == 'monitoring')
            TextButton(
              onPressed: () => ref.read(taskProvider.notifier).cancelTask(task.id),
              child: const Text('取消', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF283593)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(isTrain ? Icons.train : Icons.confirmation_number, color: Colors.white70, size: 22),
                    const SizedBox(width: 8),
                    Expanded(child: Text(task.showName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                    child: Text(statusLabel, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
              ]),
              child: Column(
                children: [
                  _infoTile(Icons.confirmation_number, '票档/座位', task.ticketType),
                  const Divider(height: 20),
                  _infoTile(Icons.shopping_cart, '数量', '${task.quantity} 张'),
                  const Divider(height: 20),
                  _infoTile(Icons.date_range, '日期', task.targetDate ?? '-'),
                  const Divider(height: 20),
                  _infoTile(Icons.access_time, '开售时间', task.saleTime),
                  const Divider(height: 20),
                  _infoTile(Icons.person, '平台账号', task.platformAccount?.accountLabel ?? task.platformAccount?.accountUsername ?? '-'),
                ],
              ),
            ),
            if (isTrain) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _open12306(),
                icon: const Icon(Icons.open_in_browser, size: 18),
                label: const Text('前往 12306 购票', style: TextStyle(fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
            if (captcha != null && captcha['task_id'] == taskId) ...[
              const SizedBox(height: 16),
              _buildCaptchaSection(context, captcha, ref, taskId),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.deepPurple),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Future<void> _open12306() async {
    if (Platform.isAndroid) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: 'https://kyfw.12306.cn/otn/leftTicket/init',
          package: 'com.MobileTicket',
        );
        await intent.launch();
        return;
      } catch (_) {}
    }
    if (Platform.isIOS) {
      final appUri = Uri.parse('cn.12306.app://');
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    final uri = Uri.parse('https://kyfw.12306.cn/otn/leftTicket/init');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildCaptchaSection(BuildContext context, Map<String, dynamic> captcha, WidgetRef ref, int taskId) {
    final captchaId = captcha['captcha_id'] as int;
    final imageBase64 = captcha['captcha_image_base64'] as String? ?? '';
    final answerCtrl = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.shade300),
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Row(children: [
            Icon(Icons.security, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text('需要验证码', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          const SizedBox(height: 12),
          if (imageBase64.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                UriData.parse('data:image/png;base64,$imageBase64').contentAsBytes(),
                height: 80,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: answerCtrl,
                  decoration: InputDecoration(
                    hintText: '输入验证码',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  final answer = answerCtrl.text.trim();
                  if (answer.isNotEmpty) {
                    ref.read(taskProvider.notifier).solveCaptcha(taskId, captchaId, answer);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                child: const Text('提交验证'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

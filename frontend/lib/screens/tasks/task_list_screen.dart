import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:go_router/go_router.dart';
import '../../providers/task_provider.dart';
import '../../services/websocket_service.dart';
import '../../models/task.dart';
import '../../utils/constants.dart';
import '../../config/theme.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const TaskListScreen({super.key, this.embedded = false});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(taskProvider.notifier).loadTasks();
      _connectWs();
      ref.read(taskProvider.notifier).onTicketAlert = _onTicketAlert;
    });
  }

  void _connectWs() async {
    final ws = WebSocketService();
    await ws.connect('');
    ref.read(taskProvider.notifier).bindWebSocket(ws);
  }

  void _onTicketAlert(Map<String, dynamic> event) {
    FlutterRingtonePlayer().playNotification();
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.notifications_active, color: Colors.orange, size: 40),
          title: const Text('有票提醒'),
          content: Text(event['message'] ?? '车次有票了！'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(taskProvider.notifier).clearTicketAlert();
              },
              child: const Text('知道了'),
            ),
            if (event['task_id'] != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ref.read(taskProvider.notifier).clearTicketAlert();
                  context.push('/tasks/${event['task_id']}');
                },
                child: const Text('查看任务'),
              ),
          ],
        ),
      );
    }
  }

  IconData _statusIcon(String status) {
    return switch (status) {
      'pending' => Icons.schedule,
      'scheduled' => Icons.alarm,
      'monitoring' => Icons.visibility,
      'purchasing' => Icons.flash_on,
      'completed' => Icons.check_circle,
      'failed' => Icons.cancel,
      'cancelled' => Icons.remove_circle,
      _ => Icons.help_outline,
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'pending' => const Color(0xFF9E9E9E),
      'scheduled' => const Color(0xFF42A5F5),
      'monitoring' => const Color(0xFFFFA726),
      'purchasing' => const Color(0xFFE53935),
      'completed' => const Color(0xFF66BB6A),
      'failed' => const Color(0xFFD32F2F),
      'cancelled' => const Color(0xFF78909C),
      _ => const Color(0xFF9E9E9E),
    };
  }

  List<Color> _cardGradient(String status) {
    return switch (status) {
      'completed' => [const Color(0xFFE8F5E9), Colors.white],
      'purchasing' => [const Color(0xFFFFEBEE), Colors.white],
      'monitoring' => [const Color(0xFFFFF3E0), Colors.white],
      'failed' => [const Color(0xFFFFEBEE), const Color(0xFFFFCDD2)],
      _ => [Colors.white, Colors.white],
    };
  }

  String _statusLabel(String status) {
    return statusLabels[status] ?? status;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskProvider);
    final tasks = state.tasks;

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text('抢票任务'), actions: [
              IconButton(icon: const Icon(Icons.account_balance_wallet), onPressed: () => context.push('/platforms')),
            ]),

      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('暂无抢票任务', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                    Text('请在首页查询车次后点击"抢"来创建任务', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(taskProvider.notifier).loadTasks(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: tasks.length,
                    itemBuilder: (ctx, i) => _buildTaskCard(context, tasks[i]),
                  ),
                ),
    );
  }

  Widget _buildTaskCard(BuildContext context, TicketTask task) {
    final colors = _cardGradient(task.status);
    final statusColor = _statusColor(task.status);
    final isTrain = task.showName.contains('G') || task.showName.contains('D');

    return GestureDetector(
      onTap: () => context.push('/tasks/${task.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: statusColor.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_statusIcon(task.status), color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.showName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(children: [
                          if (isTrain) ...[
                            Icon(Icons.train, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                          ] else ...[
                            Icon(Icons.confirmation_number, size: 14, color: AppColors.purple),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            '${task.ticketType} x${task.quantity}',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_statusLabel(task.status),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              if (task.status == 'monitoring' || task.status == 'purchasing') ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: null,
                    backgroundColor: statusColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

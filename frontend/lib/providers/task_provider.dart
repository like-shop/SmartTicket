import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/websocket_service.dart';
import 'api_provider.dart';

class TaskState {
  final List<TicketTask> tasks;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? currentCaptcha;
  final Map<String, dynamic>? ticketAlert;

  TaskState({this.tasks = const [], this.isLoading = false, this.error, this.currentCaptcha, this.ticketAlert});

  TaskState copyWith({List<TicketTask>? tasks, bool? isLoading, String? error, Map<String, dynamic>? currentCaptcha, Map<String, dynamic>? ticketAlert}) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentCaptcha: currentCaptcha,
      ticketAlert: ticketAlert,
    );
  }
}

class TaskNotifier extends StateNotifier<TaskState> {
  final TaskService _taskService;
  StreamSubscription? _wsSubscription;
  WebSocketService? _wsService;
  void Function(Map<String, dynamic>)? onTicketAlert;

  TaskNotifier(this._taskService) : super(TaskState());

  void bindWebSocket(WebSocketService ws) {
    _wsService = ws;
    _wsSubscription = ws.eventStream.listen(_handleWsEvent);
  }

  void _handleWsEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    final taskId = event['task_id'] as int?;

    switch (type) {
      case 'task_status':
        if (taskId != null) {
          _updateTaskStatus(taskId, event['new_status'] as String? ?? '');
        }
        break;
      case 'captcha_require':
        state = state.copyWith(currentCaptcha: event);
        break;
      case 'order_success':
        state = state.copyWith(currentCaptcha: null);
        break;
      case 'ticket_available':
        state = state.copyWith(ticketAlert: event);
        if (taskId != null) {
          _updateTaskStatus(taskId, 'available');
        }
        onTicketAlert?.call(event);
        break;
    }
  }

  void _updateTaskStatus(int taskId, String newStatus) {
    final updated = state.tasks.map((t) {
      if (t.id == taskId) {
        return TicketTask(
          id: t.id,
          platformAccountId: t.platformAccountId,
          showName: t.showName,
          showUrl: t.showUrl,
          targetDate: t.targetDate,
          saleTime: t.saleTime,
          ticketType: t.ticketType,
          quantity: t.quantity,
          status: newStatus,
          platformAccount: t.platformAccount,
        );
      }
      return t;
    }).toList();
    state = state.copyWith(tasks: updated);
  }

  Future<void> loadTasks({String? status}) async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _taskService.getTasks(status: status);
      state = state.copyWith(
        tasks: data.map((j) => TicketTask.fromJson(j)).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<TicketTask?> createTask(Map<String, dynamic> data) async {
    try {
      final result = await _taskService.createTask(data);
      final task = TicketTask.fromJson(result);
      state = state.copyWith(tasks: [task, ...state.tasks]);
      if (_wsService != null) {
        _wsService!.subscribeTask(task.id);
      }
      return task;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> cancelTask(int id) async {
    await _taskService.cancelTask(id);
    await loadTasks();
  }

  Future<void> startTask(int id) async {
    await _taskService.startTask(id);
    _updateTaskStatus(id, 'monitoring');
  }

  Future<void> solveCaptcha(int taskId, int captchaId, String answer) async {
    await _taskService.solveCaptcha(taskId, captchaId, answer);
    state = state.copyWith(currentCaptcha: null);
  }

  void clearCaptcha() {
    state = state.copyWith(currentCaptcha: null);
  }

  void clearTicketAlert() {
    state = state.copyWith(ticketAlert: null);
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }
}

final taskProvider = StateNotifierProvider<TaskNotifier, TaskState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final service = TaskService(apiClient);
  final notifier = TaskNotifier(service);
  return notifier;
});

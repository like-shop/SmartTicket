import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();
  Timer? _heartbeatTimer;
  bool _shouldReconnect = true;

  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  Future<void> connect(String token) async {
    _shouldReconnect = true;
    final uri = Uri.parse('${ApiConfig.wsBaseUrl}/api/v1/ws?token=$token');
    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _channel!.stream.listen(
        (data) {
          final message = jsonDecode(data as String);
          _eventController.add(message);
        },
        onDone: () {
          if (_shouldReconnect) {
            Future.delayed(const Duration(seconds: 3), () => connect(token));
          }
        },
        onError: (_) {
          if (_shouldReconnect) {
            Future.delayed(const Duration(seconds: 3), () => connect(token));
          }
        },
      );

      _startHeartbeat();
    } catch (_) {}
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      send({'type': 'heartbeat_ping'});
    });
  }

  void send(Map<String, dynamic> message) {
    _channel?.sink.add(jsonEncode(message));
  }

  void subscribeTask(int taskId) {
    send({'type': 'subscribe_task', 'task_id': taskId});
  }

  Future<void> disconnect() async {
    _shouldReconnect = false;
    _heartbeatTimer?.cancel();
    await _channel?.sink.close();
  }
}

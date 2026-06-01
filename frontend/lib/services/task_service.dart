import 'api_client.dart';

class TaskService {
  final ApiClient _client;

  TaskService(this._client);

  Future<List<dynamic>> getTasks({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    final response = await _client.dio.get('/api/v1/tasks', queryParameters: params);
    return response.data;
  }

  Future<Map<String, dynamic>> getTask(int id) async {
    final response = await _client.dio.get('/api/v1/tasks/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> data) async {
    final response = await _client.dio.post('/api/v1/tasks', data: data);
    return response.data;
  }

  Future<void> cancelTask(int id) async {
    await _client.dio.post('/api/v1/tasks/$id/cancel');
  }

  Future<void> startTask(int id) async {
    await _client.dio.post('/api/v1/tasks/$id/start');
  }

  Future<void> deleteTask(int id) async {
    await _client.dio.delete('/api/v1/tasks/$id');
  }

  Future<void> solveCaptcha(int taskId, int captchaId, String answer) async {
    await _client.dio.post(
      '/api/v1/tasks/$taskId/captcha/$captchaId/solve',
      data: {'answer': answer},
    );
  }
}

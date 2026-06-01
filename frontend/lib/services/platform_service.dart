import 'api_client.dart';

class PlatformService {
  final ApiClient _client;

  PlatformService(this._client);

  Future<List<dynamic>> getPlatforms() async {
    final response = await _client.dio.get('/api/v1/platforms');
    return response.data;
  }

  Future<List<dynamic>> getAccounts({int? platformId}) async {
    final params = <String, dynamic>{};
    if (platformId != null) params['platform_id'] = platformId;
    final response = await _client.dio.get('/api/v1/accounts', queryParameters: params);
    return response.data;
  }

  Future<Map<String, dynamic>> createAccount(Map<String, dynamic> data) async {
    final response = await _client.dio.post('/api/v1/accounts', data: data);
    return response.data;
  }

  Future<void> deleteAccount(int id) async {
    await _client.dio.delete('/api/v1/accounts/$id');
  }

  Future<Map<String, dynamic>> verifyAccount(int id) async {
    final response = await _client.dio.post('/api/v1/accounts/$id/verify');
    return response.data;
  }
}

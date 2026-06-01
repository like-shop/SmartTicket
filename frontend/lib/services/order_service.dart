import 'api_client.dart';

class OrderService {
  final ApiClient _client;

  OrderService(this._client);

  Future<List<dynamic>> getOrders({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    final response = await _client.dio.get('/api/v1/orders', queryParameters: params);
    return response.data;
  }

  Future<Map<String, dynamic>> getOrder(int id) async {
    final response = await _client.dio.get('/api/v1/orders/$id');
    return response.data;
  }
}

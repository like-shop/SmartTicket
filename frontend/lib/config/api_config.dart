class ApiConfig {
  static const String baseUrl = 'https://sesame-deceiver-avalanche.ngrok-free.dev';
  static const String wsBaseUrl = 'wss://sesame-deceiver-avalanche.ngrok-free.dev';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

class AppConfig {
  static const defaultApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://smartcart-backend-bgt4.onrender.com',
  );

  static const defaultSocketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'https://smartcart-backend-bgt4.onrender.com',
  );
}

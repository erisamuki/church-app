class ApiConfig {
  // Your live Render backend base URL
  static const String baseUrl = 'https://church-app-mq1b.onrender.com/api';

  // API Endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String members = '$baseUrl/members';
  static const String events = '$baseUrl/events';
  static const String sermons = '$baseUrl/sermons';
  static const String health = 'https://church-app-mq1b.onrender.com/health';
}

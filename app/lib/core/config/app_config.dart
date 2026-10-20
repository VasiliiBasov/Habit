/// Конфигурация окружения.
///
/// BACKEND_URL можно переопределить при запуске:
///   flutter run --dart-define=BACKEND_URL=http://localhost:8080
///
/// По умолчанию — http://10.0.2.2:8080, т.к. это адрес localhost хост-машины
/// для Android-эмулятора (основная dev-цель).
abstract final class AppConfig {
  static const String backendUrl =
      String.fromEnvironment('BACKEND_URL', defaultValue: 'http://10.0.2.2:8080');

  /// Свободный лимит ИИ-сообщений совпадает с backend (app.ai.free-daily-limit).
  static const int freeDailyLimit = 5;
}

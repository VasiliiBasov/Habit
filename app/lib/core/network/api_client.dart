import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Центральный HTTP-клиент: base URL, Bearer-токен, маппинг ошибок сервера.
class ApiClient {
  final Dio dio;
  final TokenStorage tokenStorage;

  ApiClient(this.tokenStorage)
      : dio = Dio(BaseOptions(
          baseUrl: AppConfig.backendUrl,
          connectTimeout: const Duration(seconds: 10),
          // SSE-стрим ИИ может идти долго — не ограничиваем жёстко
          receiveTimeout: const Duration(minutes: 3),
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStorage.read();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) {
        // Достаём message из тела ErrorResponse бэкенда, чтобы показать его пользователю
        final data = e.response?.data;
        var message = e.message ?? 'Ошибка сети';
        if (data is Map<String, dynamic> && data['message'] is String) {
          message = data['message'] as String;
        }
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout) {
          message = 'Нет соединения с сервером. Проверьте, что бэкенд запущен.';
        }
        handler.reject(e.copyWith(
          error: ApiException(e.response?.statusCode ?? 0, message),
        ));
      },
    ));
  }
}

/// Извлекает [ApiException] из любой ошибки сетевого слоя.
ApiException asApiException(Object error) {
  if (error is ApiException) return error;
  if (error is DioException && error.error is ApiException) {
    return error.error! as ApiException;
  }
  return const ApiException(0, 'Неизвестная ошибка');
}

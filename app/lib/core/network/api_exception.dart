/// Единая ошибка API: код ответа + человекочитаемое сообщение.
/// Совпадает по смыслу с backend ErrorResponse {error, message, timestamp}.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  /// 402 — превышен freemium-лимит (нужна подписка).
  bool get isPaymentRequired => statusCode == 402;

  @override
  String toString() => message;
}

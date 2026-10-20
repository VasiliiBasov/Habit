import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

/// Одно событие Server-Sent Events.
class SseEvent {
  final String event; // 'message' по умолчанию, либо значение поля event:
  final String data;

  const SseEvent({this.event = 'message', required this.data});

  @override
  String toString() => 'SseEvent($event, $data)';
}

/// Потокобезопасный парсер SSE: склеивает строки, разорванные между
/// сетевыми чанками, собирает многострочный data:, игнорирует комментарии.
class SseDecoder {
  String _buffer = '';
  String _eventType = 'message';
  final List<String> _dataLines = [];

  /// Скармливает текстовый чанк; возвращает завершённые события.
  List<SseEvent> add(String chunk) {
    final events = <SseEvent>[];
    _buffer += chunk;
    int idx;
    while ((idx = _buffer.indexOf('\n')) >= 0) {
      var line = _buffer.substring(0, idx);
      _buffer = _buffer.substring(idx + 1);
      if (line.endsWith('\r')) line = line.substring(0, line.length - 1);

      if (line.isEmpty) {
        // Пустая строка — разделитель событий
        if (_dataLines.isNotEmpty) {
          events.add(SseEvent(event: _eventType, data: _dataLines.join('\n')));
        }
        _eventType = 'message';
        _dataLines.clear();
      } else if (line.startsWith(':')) {
        // keep-alive комментарий — пропускаем
      } else if (line.startsWith('data:')) {
        // Сервер (Spring SseEmitter) шлёт данные как есть, без
        // форматирующего пробела после "data:", поэтому ведущие пробелы
        // чанка сохраняем — иначе теряются пробелы между словами.
        _dataLines.add(line.substring(5));
      } else if (line.startsWith('event:')) {
        _eventType = line.substring(6).trim();
      }
      // id:, retry: нам не нужны
    }
    return events;
  }

  /// Форс-выгрузка при закрытии потока, если сервер не прислал финальный \n\n.
  List<SseEvent> flush() {
    final events = <SseEvent>[];
    if (_buffer.startsWith('data:')) {
      _dataLines.add(_buffer.substring(5));
    }
    _buffer = '';
    if (_dataLines.isNotEmpty) {
      events.add(SseEvent(event: _eventType, data: _dataLines.join('\n')));
      _dataLines.clear();
    }
    _eventType = 'message';
    return events;
  }
}

/// Превращает байтовый стрим ответа dio (ResponseType.stream) в поток событий.
Stream<SseEvent> decodeSseStream(ResponseBody body) {
  final decoder = SseDecoder();
  final controller = StreamController<SseEvent>();
  body.stream.cast<List<int>>().transform(utf8.decoder).listen(
    (text) {
      for (final event in decoder.add(text)) {
        controller.add(event);
      }
    },
    onError: controller.addError,
    onDone: () {
      for (final event in decoder.flush()) {
        controller.add(event);
      }
      controller.close();
    },
  );
  return controller.stream;
}

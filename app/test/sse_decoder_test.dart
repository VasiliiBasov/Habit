import 'package:flutter_test/flutter_test.dart';
import 'package:habit_app/core/network/sse_client.dart';

void main() {
  group('SseDecoder', () {
    test('собирает событие из data: и пустой строки-разделителя', () {
      final d = SseDecoder();
      expect(d.add('data: привет\n'), isEmpty);
      final events = d.add('\n');
      expect(events, hasLength(1));
      expect(events.single.data, 'привет');
      expect(events.single.event, 'message');
    });

    test('склеивает строку, разорванную между сетевыми чанками', () {
      final d = SseDecoder();
      expect(d.add('data: hel'), isEmpty);
      final events = d.add('lo\n\ndata: world\n\n');
      expect(events.map((e) => e.data), ['hello', 'world']);
    });

    test('понимает event: error и многострочный data', () {
      final d = SseDecoder();
      final events = d.add('event: error\ndata: пер\ndata: вона\n\n');
      expect(events.single.event, 'error');
      expect(events.single.data, 'пер\nвона');
    });

    test('flush доотдаёт хвост без финального разделителя', () {
      final d = SseDecoder();
      d.add('data: хвост');
      final events = d.flush();
      expect(events.single.data, 'хвост');
    });

    test('игнорирует keep-alive комментарии и CRLF', () {
      final d = SseDecoder();
      expect(d.add(': ping\r\n\r\n'), isEmpty);
      final events = d.add('data: ok\r\n\r\n');
      expect(events.single.data, 'ok');
    });
  });
}

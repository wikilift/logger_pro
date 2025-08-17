import 'package:logger_pro/logger_pro.dart';
import 'package:test/test.dart';

/// @file logger_pro_test.dart
/// @brief
/// @author Daniel Giménez- Wikilift
/// @date 17/08/25

/// A mock logger sink to capture log events for testing.
class MockLoggerSink implements LoggerPro {
  Map<String, dynamic>? lastEvent;
  List<Map<String, dynamic>> allEvents = [];

  @override
  void onLog(Map<String, dynamic> event) {
    lastEvent = event;
    allEvents.add(event);
  }

  void clear() {
    lastEvent = null;
    allEvents.clear();
  }
}

void main() {
  late MockLoggerSink mockSink;

  setUp(() {
    mockSink = MockLoggerSink();
    // register the mock sink before each test.
    registerLogSink(mockSink);
  });

  tearDown(() {
    // Unregister the sink after each test.
    unregisterLogSink();
    mockSink.clear();
  });

  group('Basic Logging', () {
    test('logi captures correct kind and message', () {
      logi('Hello, world!');

      expect(mockSink.lastEvent, isNotNull);
      expect(mockSink.lastEvent!['kind'], 'logi');
      expect(mockSink.lastEvent!['message'], 'Hello, world!');
      expect(mockSink.lastEvent!['name'], '');
    });

    test('loge captures error and stackTrace objects', () {
      final error = Exception('A test error');
      final stackTrace = StackTrace.current;

      loge('Something failed', error: error, stackTrace: stackTrace, name: 'TestProcess');

      expect(mockSink.lastEvent!['error'], error.toString());
      expect(mockSink.lastEvent!['stackTrace'], stackTrace.toString());
      expect(mockSink.lastEvent!['name'], 'TestProcess');
    });
  });

  group('Timestamping', () {
    test('time: true adds a valid timestamp prefix', () {
      final timestampRegex = RegExp(r'^\d{2}:\d{2}:\d{2}$');

      logi('Testing time prefix', time: true);

      final hhmmss = mockSink.lastEvent!['timeHHmmss'];
      expect(hhmmss, isNotNull);
      expect(timestampRegex.hasMatch(hhmmss!), isTrue);
    });

    test('msDiff works correctly for sequential logs', () async {
      logi('First call', msDiff: true);
      final firstDiff = mockSink.lastEvent!['msDiffPrinted'];
      expect(firstDiff, isTrue);

      await Future.delayed(const Duration(milliseconds: 50));
      logi('Second call', msDiff: true);

      final secondDiff = mockSink.lastEvent!['msDiffPrinted'];
      expect(secondDiff, isTrue);
      final t1 = DateTime.parse(mockSink.allEvents[0]['timestamp']);
      final t2 = DateTime.parse(mockSink.allEvents[1]['timestamp']);
      expect(t2.isAfter(t1), isTrue);
    });
  });

  group('Buffer Logging', () {
    final buffer = [0x44, 0x41, 0x52, 0x54];

    test('logBufHex formats bytes correctly', () {
      logBufHex(buffer);

      expect(mockSink.lastEvent!['kind'], 'hex');
      expect(mockSink.lastEvent!['message'], '(4 bytes) 44 41 52 54');
      expect(mockSink.lastEvent!['bytes'], buffer);
    });

    test('logBufChr formats bytes correctly', () {
      logBufChr(buffer);

      expect(mockSink.lastEvent!['kind'], 'chr');
      expect(mockSink.lastEvent!['message'], '(4 bytes) D A R T');
    });

    test('logBufAnsi converts bytes to string', () {
      final ansiBuffer = [27, 91, 51, 49, 109, ...'ANSI'.codeUnits];
      logBufAnsi(ansiBuffer);

      expect(mockSink.lastEvent!['kind'], 'ansi');
      expect(mockSink.lastEvent!['text'], '\x1B[31mANSI');
    });
  });
}

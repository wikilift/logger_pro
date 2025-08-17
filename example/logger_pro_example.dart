import 'dart:convert';
import 'package:logger_pro/logger_pro.dart';

class JsonSink extends LoggerPro {
  @override
  void onLog(Map<String, dynamic> event) {
    print("Sending to backend: ${jsonEncode(event).substring(0, 150)}... ");
  }
}

void main() async {
  ansiEnabled = true;
  registerLogSink(JsonSink());

  logi(' Basic Logging ', name: 'Example', color: AnsiColor.magenta);
  logi('Info message', name: 'Demo');
  logw('Warning message', name: 'Demo');
  loge(
    'Error with channel: Exception("hello, i\'m exception")',
    name: 'ExceptionChannel',
    stackTrace: StackTrace.current,
  );
  logd('Debug details', name: 'Demo');

  logi(' Timestamping  ', name: 'example', color: AnsiColor.magenta);
  logi('Message with [HH:mm:ss]', time: true, name: 'Demo');

  logi(' msDiff Demo ', name: 'example', color: AnsiColor.magenta);
  logi('First', msDiff: true, name: 'MSDIFF');
  await Future.delayed(const Duration(milliseconds: 80));
  logi('After ~80ms', msDiff: true, name: 'MSDIFF');
  await Future.delayed(const Duration(milliseconds: 1500));
  logi('After ~1.5s', msDiff: true, name: 'MSDIFF');

  logi(' Buffers (HEX/CHR) ', name: 'example', color: AnsiColor.magenta);
  final buf = [0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x21, 0x0A, 0x0D];
  logBufHex(buf, name: 'HEX');
  logBufChr(buf, name: 'CHR');

  logi(' ANSI sequences ', name: 'example', color: AnsiColor.magenta);
  final redHelloReset = <int>[27, 91, 51, 49, 109, ...'Hello, ANSI! (red)'.codeUnits, 27, 91, 48, 109];
  logBufAnsi(redHelloReset, name: 'ansi-Demo');

  logi(' JSON sink capture ', name: 'example', color: AnsiColor.magenta);
  loge('Captured by sink: CriticalFailure', name: 'MainProcess', stackTrace: StackTrace.current);

  unregisterLogSink();
  logi('Sink unregistered. Done.', name: 'example', color: AnsiColor.magenta);
}

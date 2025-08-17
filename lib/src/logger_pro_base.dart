import 'dart:async' show Zone;
import 'dart:developer' as dev;

/// @file logger_pro_base.dart
/// @brief
/// @author Daniel Giménez- Wikilift
/// @date 17/08/25
/// A sink for log events, allowing custom backends for logging.
///
/// Implement this class to send log outputs to a file, a remote server, or
/// any other custom destination.
abstract class LoggerPro {
  void onLog(Map<String, dynamic> event);
}

LoggerPro? _loggerPro;

/// Registers a global sink to receive all log events.
void registerLogSink(LoggerPro sink) => _loggerPro = sink;

/// Unregisters the current global sink.
void unregisterLogSink() => _loggerPro = null;

/// Globally enables or disables ANSI color codes in the output.
/// Defaults to `true`.
bool _ansiEnabled = true;
set ansiEnabled(bool v) => _ansiEnabled = v;
bool get ansiEnabled => _ansiEnabled;

// Stores the timestamp of the last log for msDiff calculation.
DateTime? _lastLogTimestamp;

/// Enumeration of ANSI colors for terminal output.
enum AnsiColor {
  black,
  red,
  green,
  yellow,
  blue,
  magenta,
  cyan,
  white,
  brightBlack,
  brightRed,
  brightGreen,
  brightYellow,
  brightBlue,
  brightMagenta,
  brightCyan,
  brightWhite,
}

// --- Internal ANSI constants and helpers ---
const _rst = '\x1B[0m';
const _k = '\x1B[30m';
const _r = '\x1B[31m';
const _g = '\x1B[32m';
const _y = '\x1B[33m';
const _b = '\x1B[34m';
const _m = '\x1B[35m';
const _c = '\x1B[36m';
const _w = '\x1B[37m';
const _bk = '\x1B[90m';
const _br = '\x1B[91m';
const _bg = '\x1B[92m';
const _by = '\x1B[93m';
const _bb = '\x1B[94m';
const _bm = '\x1B[95m';
const _bc = '\x1B[96m';
const _bw = '\x1B[97m';

String _codeOf(AnsiColor c) {
  switch (c) {
    case AnsiColor.black:
      return _k;
    case AnsiColor.red:
      return _r;
    case AnsiColor.green:
      return _g;
    case AnsiColor.yellow:
      return _y;
    case AnsiColor.blue:
      return _b;
    case AnsiColor.magenta:
      return _m;
    case AnsiColor.cyan:
      return _c;
    case AnsiColor.white:
      return _w;
    case AnsiColor.brightBlack:
      return _bk;
    case AnsiColor.brightRed:
      return _br;
    case AnsiColor.brightGreen:
      return _bg;
    case AnsiColor.brightYellow:
      return _by;
    case AnsiColor.brightBlue:
      return _bb;
    case AnsiColor.brightMagenta:
      return _bm;
    case AnsiColor.brightCyan:
      return _bc;
    case AnsiColor.brightWhite:
      return _bw;
  }
}

String _nowHHmmss() {
  final n = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(n.hour)}:${two(n.minute)}:${two(n.second)}';
}

void _emitSink(String kind, Map<String, dynamic> payload) {
  final sink = _loggerPro;
  if (sink == null) return;
  final now = DateTime.now();
  sink.onLog({'kind': kind, 'timestamp': now.toIso8601String(), ...payload});
}

// The core logging function that handles all logic.
void _coreLog(
  String message, {
  required String kind,
  required String colorCode,
  AnsiColor? color,
  bool time = false,
  bool msDiff = false,
  int? sequenceNumber,
  int level = 0,
  String name = '',
  Zone? zone,
  Object? error,
  StackTrace? stackTrace,
  Map<String, dynamic>? extraPayload,
}) {
  assert(!(time && msDiff), 'Cannot provide both time and msDiff.');

  final now = DateTime.now();

  String tsPrefix = '';
  if (time) {
    tsPrefix = '[${_nowHHmmss()}] ';
  } else if (msDiff) {
    final last = _lastLogTimestamp;
    final diffMs = last == null
        ? 0.0
        : now.difference(last).inMicroseconds / 1000.0;
    _lastLogTimestamp = now;
    final timeStr = _nowHHmmss();
    final diffFormatted = diffMs >= 1000
        ? '+${(diffMs / 1000.0).toStringAsFixed(3)}s'
        : '+${diffMs.toStringAsFixed(2)}ms';
    tsPrefix = '[$timeStr] [$diffFormatted] ';
  }

  final baseMsg = '$tsPrefix$message';
  final coloredMsg = _ansiEnabled ? '$colorCode$baseMsg$_rst' : baseMsg;
  final coloredName = name.isEmpty
      ? ''
      : (_ansiEnabled ? '$colorCode$name$_rst' : name);

  dev.log(
    coloredMsg,
    time: now,
    sequenceNumber: sequenceNumber,
    level: level,
    name: coloredName,
    zone: zone,
    error: error,
    stackTrace: stackTrace,
  );

  _emitSink(kind, {
    'message': message,
    'timePrinted': time,
    'msDiffPrinted': msDiff,
    'timeHHmmss': (time || msDiff) ? _nowHHmmss() : null,
    'sequenceNumber': sequenceNumber,
    'level': level,
    'name': name,
    'zone': zone?.toString(),
    'error': error?.toString(),
    'stackTrace': stackTrace?.toString(),
    'ansiEnabled': _ansiEnabled,
    'color': (color ?? _defaultColorFor(kind)).toString().split('.').last,
    if (extraPayload != null) ...extraPayload,
  });
}

AnsiColor _defaultColorFor(String kind) {
  switch (kind) {
    case 'logi':
      return AnsiColor.green;
    case 'logw':
      return AnsiColor.yellow;
    case 'loge':
      return AnsiColor.red;
    case 'logd':
      return AnsiColor.cyan;
    case 'hex':
      return AnsiColor.cyan;
    case 'chr':
      return AnsiColor.cyan;
    case 'ansi':
      return AnsiColor.white;
    default:
      return AnsiColor.white;
  }
}

/// Logs an informational message (level: info).
///
/// - [message]: The message to be logged.
/// - [time]: If true, prefixes the log with `[HH:mm:ss]`.
/// - [msDiff]: If true, prefixes with current time and diff from the last log.
/// - [sequenceNumber]: Optional sequence identifier.
/// - [level]: Severity level (default 0).
/// - [name]: Optional name/tag for the log.
/// - [zone]: The zone associated with this log.
/// - [error]: Optional error object to log.
/// - [stackTrace]: Optional stack trace to log.
/// - [color]: ANSI color override for the message.
void logi(
  String message, {
  bool time = false,
  bool msDiff = false,
  int? sequenceNumber,
  int level = 0,
  String name = '',
  Zone? zone,
  Object? error,
  StackTrace? stackTrace,
  AnsiColor? color,
}) {
  final c = color ?? AnsiColor.green;
  _coreLog(
    message,
    kind: 'logi',
    colorCode: _codeOf(c),
    color: c,
    time: time,
    sequenceNumber: sequenceNumber,
    level: level,
    msDiff: msDiff,
    name: name,
    zone: zone,
    error: error,
    stackTrace: stackTrace,
  );
}

/// Logs a warning message (level: warning).
///
/// - [message]: The message to be logged.
/// - [time]: If true, prefixes the log with `[HH:mm:ss]`.
/// - [msDiff]: If true, prefixes with current time and diff from the last log.
/// - [sequenceNumber]: Optional sequence identifier.
/// - [level]: Severity level (default 0).
/// - [name]: Optional name/tag for the log.
/// - [zone]: The zone associated with this log.
/// - [error]: Optional error object to log.
/// - [stackTrace]: Optional stack trace to log.
/// - [color]: ANSI color override for the message.
void logw(
  String message, {
  bool time = false,
  int? sequenceNumber,
  int level = 0,
  String name = '',
  Zone? zone,
  Object? error,
  StackTrace? stackTrace,
  bool msDiff = false,
  AnsiColor? color,
}) {
  final c = color ?? AnsiColor.yellow;
  _coreLog(
    message,
    kind: 'logw',
    colorCode: _codeOf(c),
    color: c,
    time: time,
    sequenceNumber: sequenceNumber,
    level: level,
    name: name,
    zone: zone,
    error: error,
    msDiff: msDiff,
    stackTrace: stackTrace,
  );
}

/// Logs an error message (level: error).
///
/// - [message]: The message to be logged.
/// - [time]: If true, prefixes the log with `[HH:mm:ss]`.
/// - [msDiff]: If true, prefixes with current time and diff from the last log.
/// - [sequenceNumber]: Optional sequence identifier.
/// - [level]: Severity level (default 0).
/// - [name]: Optional name/tag for the log.
/// - [zone]: The zone associated with this log.
/// - [error]: Optional error object to log.
/// - [stackTrace]: Optional stack trace to log.
/// - [color]: ANSI color override for the message.
void loge(
  String message, {
  bool time = false,
  int? sequenceNumber,
  int level = 0,
  String name = '',
  Zone? zone,
  Object? error,
  bool msDiff = false,
  StackTrace? stackTrace,
  AnsiColor? color,
}) {
  final c = color ?? AnsiColor.red;
  _coreLog(
    message,
    kind: 'loge',
    colorCode: _codeOf(c),
    color: c,
    time: time,
    sequenceNumber: sequenceNumber,
    level: level,
    name: name,
    zone: zone,
    msDiff: msDiff,
    error: error,
    stackTrace: stackTrace,
  );
}

/// Logs a debug message (level: debug).
///
/// - [message]: The message to be logged.
/// - [time]: If true, prefixes the log with `[HH:mm:ss]`.
/// - [msDiff]: If true, prefixes with current time and diff from the last log.
/// - [sequenceNumber]: Optional sequence identifier.
/// - [level]: Severity level (default 0).
/// - [name]: Optional name/tag for the log.
/// - [zone]: The zone associated with this log.
/// - [error]: Optional error object to log.
/// - [stackTrace]: Optional stack trace to log.
/// - [color]: ANSI color override for the message.
void logd(
  String message, {
  bool time = false,
  int? sequenceNumber,
  int level = 0,
  String name = '',
  Zone? zone,
  bool msDiff = false,
  Object? error,
  StackTrace? stackTrace,
  AnsiColor? color,
}) {
  final c = color ?? AnsiColor.cyan;
  _coreLog(
    message,
    kind: 'logd',
    colorCode: _codeOf(c),
    color: c,
    time: time,
    msDiff: msDiff,
    sequenceNumber: sequenceNumber,
    level: level,
    name: name,
    zone: zone,
    error: error,
    stackTrace: stackTrace,
  );
}

/// Logs a buffer of bytes as a hexadecimal string.
///
/// Example: `[10, 11]` → `(2 bytes) 0A 0B`
///
/// - [buf]: List of numbers (bytes) to render in hex.
/// - [time]: If true, prefixes the log with `[HH:mm:ss]`.
/// - [msDiff]: If true, prefixes with current time and diff from the last log.
/// - [sequenceNumber]: Optional sequence identifier.
/// - [level]: Severity level (default 0).
/// - [name]: Optional name/tag for the log.
/// - [zone]: The zone associated with this log.
/// - [error]: Optional error object to log.
/// - [stackTrace]: Optional stack trace to log.
/// - [color]: ANSI color override for the message.
void logBufHex(
  List<num> buf, {
  bool time = false,
  int? sequenceNumber,
  int level = 0,
  bool msDiff = false,
  String name = '',
  Zone? zone,
  Object? error,
  StackTrace? stackTrace,
  AnsiColor? color,
}) {
  final bytes = buf.map((b) => (b.toInt() & 0xFF)).toList(growable: false);
  final hexParts = bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(' ');
  final msg = '(${bytes.length} bytes) $hexParts';
  final c = color ?? AnsiColor.cyan;
  _coreLog(
    msg,
    kind: 'hex',
    colorCode: _codeOf(c),
    color: c,
    time: time,
    sequenceNumber: sequenceNumber,
    msDiff: msDiff,
    level: level,
    name: name,
    zone: zone,
    error: error,
    stackTrace: stackTrace,
    extraPayload: {'bytes': bytes, 'render': 'hex', 'text': hexParts},
  );
}

/// Logs a buffer of bytes as characters if printable, otherwise as hex.
///
/// Example: `[72, 101, 108, 108, 111, 10]` → `(6 bytes) H e l l o 0x0A`
///
/// - [buf]: List of numbers (bytes) to render as characters.
/// - [time]: If true, prefixes the log with `[HH:mm:ss]`.
/// - [msDiff]: If true, prefixes with current time and diff from the last log.
/// - [sequenceNumber]: Optional sequence identifier.
/// - [level]: Severity level (default 0).
/// - [name]: Optional name/tag for the log.
/// - [zone]: The zone associated with this log.
/// - [error]: Optional error object to log.
/// - [stackTrace]: Optional stack trace to log.
/// - [color]: ANSI color override for the message.
void logBufChr(
  List<num> buf, {
  bool time = false,
  int? sequenceNumber,
  int level = 0,
  String name = '',
  Zone? zone,
  bool msDiff = false,
  Object? error,
  StackTrace? stackTrace,
  AnsiColor? color,
}) {
  final bytes = buf.map((b) => (b.toInt() & 0xFF)).toList(growable: false);
  final parts = <String>[];
  for (final b in bytes) {
    if (b >= 32 && b <= 126) {
      parts.add(String.fromCharCode(b));
    } else {
      parts.add('0x${b.toRadixString(16).padLeft(2, '0').toUpperCase()}');
    }
  }
  final body = parts.join(' ');
  final msg = '(${bytes.length} bytes) $body';
  final c = color ?? AnsiColor.cyan;
  _coreLog(
    msg,
    kind: 'chr',
    colorCode: _codeOf(c),
    color: c,
    time: time,
    sequenceNumber: sequenceNumber,
    level: level,
    name: name,
    msDiff: msDiff,
    zone: zone,
    error: error,
    stackTrace: stackTrace,
    extraPayload: {'bytes': bytes, 'render': 'chr', 'text': body},
  );
}

/// Logs a buffer of bytes as an ANSI escape sequence.
///
/// The sequence is interpreted by the terminal, allowing for
/// cursor movement, clearing the screen, colors, etc.
///
/// Example: `[27, 91, 72]` (ESC [ H) moves the cursor home.
///
/// - [buf]: List of numbers (bytes) to render as ANSI sequence.
/// - [time]: If true, prefixes the log with `[HH:mm:ss]`.
/// - [msDiff]: If true, prefixes with current time and diff from the last log.
/// - [sequenceNumber]: Optional sequence identifier.
/// - [level]: Severity level (default 0).
/// - [name]: Optional name/tag for the log.
/// - [zone]: The zone associated with this log.
/// - [error]: Optional error object to log.
/// - [stackTrace]: Optional stack trace to log.
/// - [color]: ANSI color override for the message.
void logBufAnsi(
  List<num> buf, {
  bool time = false,
  bool msDiff = false,
  int? sequenceNumber,
  int level = 0,
  String name = '',
  Zone? zone,
  Object? error,
  StackTrace? stackTrace,
  AnsiColor? color,
}) {
  final bytes = buf.map((b) => b.toInt() & 0xFF).toList(growable: false);

  final ansiString = String.fromCharCodes(bytes);

  final c = color ?? AnsiColor.white;

  _coreLog(
    ansiString,
    kind: 'ansi',
    colorCode: _codeOf(c),
    color: c,
    time: time,
    msDiff: msDiff,
    sequenceNumber: sequenceNumber,
    level: level,
    name: name,
    zone: zone,
    error: error,
    stackTrace: stackTrace,
    extraPayload: {'bytes': bytes, 'render': 'ansi', 'text': ansiString},
  );
}

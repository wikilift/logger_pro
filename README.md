# logger_pro

[![Buy Me A Coffee](https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png)](https://buymeacoffee.com/wikilift)

[![pub.dev](https://img.shields.io/pub/v/logger_pro.svg)](https://pub.dev/packages/logger_pro) [![Dart](https://img.shields.io/badge/dart-%3E%3D3.0.0-blue.svg)](https://dart.dev) [![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE) [![GitHub stars](https://img.shields.io/github/stars/wikilift/logger_pro.svg?style=social)](https://github.com/wikilift/logger_pro)


A modern, developer-first logger for Dart & Flutter that gets out of your way. It provides beautiful, readable console output with zero-config ANSI colors, while offering powerful features for complex debugging—like performance profiling with millisecond diffs, structured JSON sinks, and unique handlers for inspecting raw data like **HEX** strings and **ANSI** terminal sequences.

With zero dependencies and seamless DevTools integration, it's the perfect companion for your next CLI, Flutter app, or server-side project.

> Works great for CLI tools, Flutter apps, and test environments. No dependencies.

---

---

## Platform Support

| Android | iOS | Linux | macOS | Web | Windows |
| :---: | :---: | :---: | :---: | :---: | :---: |
|   ✅   |  ✅  |   ✅   |   ✅  |  ✅  |    ✅    |


## ✨ Features

- **Zero‑dependency.** Pure Dart. Usable in both Dart VM and Flutter.
- **Colorful by default.** ANSI colors with an `AnsiColor` enum and a global `ansiEnabled` switch.
- **Readable channels.** The `name` parameter acts like a tag/channel: `[network]`, `[auth]`, etc.
- **Timestamps & perf.** Use `time: true` for `[HH:mm:ss]` or `msDiff: true` to see deltas between logs.
- **Pluggable sinks.** Implement `LoggerPlus` to forward each structured log event (JSON) anywhere.
- **Binary‑friendly.** `logBufHex`, `logBufChr` and `logBufAnsi` for protocol debugging and terminal control.
- **DevTools‑friendly.** Uses `dev.log` under the hood; `level`, `zone`, and `sequenceNumber` are preserved.

---

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  logger_pro: ^0.0.1
```
or run this command with Dart : 
```bash 
dart pub add logger_pro
```

Then import:

```dart
import 'package:logger_pro/logger_pro.dart';
```

---

## 🚀 Quick start

```dart
import 'package:logger_pro/logger_pro.dart';

void main() {
  ansiEnabled = true; // Turn off if your console doesn't support ANSI

  logi('App started', name: 'bootstrap');
  logw('Careful here', name: 'config');
  loge('Something failed', name: 'io', error: Exception('disk full'));
  logd('Debug details', name: 'debug');
}
```

**Output (sample):**
```
[bootstrap] App started 
[config] Careful here 
[io] Something failed 
[debug] Debug details
```

---

## 🧪 Sinks (structured logs to anywhere)

Every log goes through a **single global sink** if registered. You receive a `Map<String, dynamic>` (JSON‑ready) with fields like `kind`, `timestamp`, `message`, `name`, `error`, etc.

```dart
import 'dart:convert';
import 'package:logger_pro/logger_pro.dart';

class JsonSink extends LoggerPlus {
  final encoder = const JsonEncoder.withIndent('  ');
  @override
  void onLog(Map<String, dynamic> event) {
    // Send to a file, HTTP endpoint, analytics pipeline, etc.
    print(encoder.convert(event));
  }
}

void main() {
  registerLogSink(JsonSink());
  logi('Ship it!', name: 'release');
}
```

**Event shape (example):**
```json
{
  "kind": "logi",
  "timestamp": "2025-08-17T12:34:56.789012",
  "message": "Ship it!",
  "timePrinted": false,
  "msDiffPrinted": false,
  "timeHHmmss": null,
  "sequenceNumber": null,
  "level": 0,
  "name": "release",
  "zone": null,
  "error": null,
  "stackTrace": null,
  "ansiEnabled": true,
  "color": "green"
}
```

_Unregister the sink when you’re done:_

```dart
unregisterLogSink();
```

---

## ⏱️ Time 

### `time: true`
Prefix the message with `[HH:mm:ss]`:

```dart
logi('Tick', time: true, name: 'clock');  // [12:04:33]
```

### `msDiff: true`
Show the current time and the delta since the **previous** log in milliseconds/seconds:

```dart
logi('First',  msDiff: true, name: 'perf');
logi('Second', msDiff: true, name: 'perf'); // [HH:mm:ss] [+12.34ms] Second
```

> `time` and `msDiff` are **mutually exclusive**; the logger will assert if both are set.

---

## Colors & channels

```dart
logi('Saved', name: 'db', color: AnsiColor.green);
logw('Retrying', name: 'network', color: AnsiColor.yellow);
loge('Boom', name: 'auth', color: AnsiColor.red);
logd('Trace', name: 'debug', color: AnsiColor.cyan);
```

Disable colors globally:

```dart
ansiEnabled = false;
```

---

## 🔧 Working with buffers

### Hex
```dart
logBufHex([0xDE, 0xAD, 0xBE, 0xEF], name: 'pkt');
// (4 bytes) DE AD BE EF
```

### Chr (ASCII if printable, hex otherwise)
```dart
logBufChr([72, 101, 108, 108, 111, 10], name: 'pkt');
// (6 bytes) H e l l o 0x0A
```

### Raw ANSI escape sequences
Send terminal control directly (color, cursor movement, clear screen, …):

```dart
final redHello = <int>[
  27, 91, 51, 49, 109,         // ESC[31m  -> red
  ...'Hello, ANSI!'.codeUnits,
  27, 91, 48, 109,             // ESC[0m   -> reset
];
logBufAnsi(redHello, name: 'ansi-demo');
```

> Some IDE consoles ignore cursor movement/clear operations. Use a real terminal for full effect.

---

## API overview

```dart
void logi(String message, { bool time, bool msDiff, int? sequenceNumber, int level, String name, Zone? zone, Object? error, StackTrace? stackTrace, AnsiColor? color });
void logw(String message, { ...same params... });
void loge(String message, { ...same params... });
void logd(String message, { ...same params... });

void logBufHex(List<num> buf, { ...same params... });
void logBufChr(List<num> buf, { ...same params... });
void logBufAnsi(List<num> buf, { ...same params... });

void registerLogSink(LoggerPlus sink);
void unregisterLogSink();

bool get ansiEnabled;
set ansiEnabled(bool value);
```

**Kinds :** `logi`, `logw`, `loge`, `logd`, `hex`, `chr`, `ansi`.

---


## 🔍 Example project

A complete example is included under `/example` showing basic logging, timestamps, diffs, buffers, and ANSI control sequences.

Run it:
```bash
dart run example/main.dart
```

---

## 🤝 Contributing

Issues and pull requests are welcome. If you find a bug or want a feature, open an issue with a clear repro or use‑case.

---

## 📄 License

This project is licensed under the **MIT License**.

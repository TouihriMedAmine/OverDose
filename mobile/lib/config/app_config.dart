import 'package:flutter/foundation.dart';

/// Backend base URL (no trailing slash). Override with `--dart-define=API_BASE=http://...`
class AppConfig {
  AppConfig._();

  static const String _fromEnv = String.fromEnvironment(
    'API_BASE',
    defaultValue: '',
  );

  /// Android emulator → host machine: [10.0.2.2]. iOS simulator → [127.0.0.1].
  static String get apiBaseUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv.replaceAll(RegExp(r'/$'), '');
    if (kIsWeb) return 'http://localhost:8000';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      default:
        return 'http://127.0.0.1:8000';
    }
  }
}

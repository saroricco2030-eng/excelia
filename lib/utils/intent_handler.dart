import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 파일 매니저 / iOS Files 앱에서 VIEW intent로 전달된 파일 경로를
/// Android·iOS native 측에서 받아오는 다리(bridge).
///
/// Web 등 비지원 플랫폼에서는 모든 메서드가 no-op.
///
/// Channel contract (native ↔ Dart 공통):
/// - `getInitialPath` (Dart → native): 콜드 스타트 경로 1회 pull.
///   1회만 반환 — native 측에서 즉시 null로 클리어한다.
/// - `onNewFile`      (native → Dart): 핫 스타트 경로 push.
class IntentHandler {
  IntentHandler._();

  static const MethodChannel _channel = MethodChannel('excelia/intent');

  static Future<String?> getInitialPath() async {
    if (!_isSupportedPlatform()) return null;
    try {
      return await _channel.invokeMethod<String>('getInitialPath');
    } catch (e) {
      debugPrint('IntentHandler.getInitialPath failed: $e');
      return null;
    }
  }

  static void setOnNewFile(void Function(String path) callback) {
    if (!_isSupportedPlatform()) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNewFile') {
        final arg = call.arguments;
        if (arg is String && arg.isNotEmpty) callback(arg);
      }
    });
  }

  static void clearOnNewFile() {
    if (!_isSupportedPlatform()) return;
    _channel.setMethodCallHandler(null);
  }

  static bool _isSupportedPlatform() {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }
}

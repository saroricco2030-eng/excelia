import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// 파일 접근에 필요한 스토리지 권한을 요청한다.
/// 권한이 허용되면 true, 거부되면 false를 반환한다.
Future<bool> requestStoragePermission() async {
  // iOS / 데스크톱은 SAF 방식이므로 별도 권한 불필요
  if (!Platform.isAndroid) return true;

  final deviceInfo = DeviceInfoPlugin();
  final androidInfo = await deviceInfo.androidInfo;
  final sdkInt = androidInfo.version.sdkInt;

  if (sdkInt >= 33) {
    // Android 13+ : 미디어 권한만 필요 (파일 피커는 SAF로 동작)
    // file_picker가 SAF를 사용하므로 대부분 권한 없이 동작하지만,
    // 일부 기기에서 캐시 파일 접근 시 필요할 수 있음
    return true;
  } else if (sdkInt >= 30) {
    // Android 11~12 : MANAGE_EXTERNAL_STORAGE 필요
    final status = await Permission.manageExternalStorage.status;
    if (status.isGranted) return true;
    final result = await Permission.manageExternalStorage.request();
    return result.isGranted;
  } else {
    // Android 10 이하 : READ_EXTERNAL_STORAGE
    final status = await Permission.storage.status;
    if (status.isGranted) return true;
    final result = await Permission.storage.request();
    return result.isGranted;
  }
}

/// 파일이 실제로 존재하고 읽기 가능한지 검증한다.
Future<bool> validateFileAccess(String path) async {
  try {
    final file = File(path);
    if (!await file.exists()) return false;
    // 읽기 가능 여부 확인 (첫 바이트만 읽어봄)
    final raf = await file.open(mode: FileMode.read);
    await raf.close();
    return true;
  } catch (e) {
    debugPrint('File access validation failed: $e');
    return false;
  }
}

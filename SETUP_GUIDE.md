# Excelia 설정 및 실행 가이드

## 🔧 개발 환경 설정

### 필수 요구사항
- Flutter 3.10.8 이상
- Dart 3.0 이상
- Windows 10 이상 (또는 macOS, Linux)

### 설치 단계

#### 1. Flutter 설치
```bash
# 공식 사이트에서 Flutter SDK 다운로드
https://flutter.dev/docs/get-started/install

# 환경변수 설정
set PATH=%PATH%;C:\path\to\flutter\bin
```

#### 2. 프로젝트 의존성 설치
```bash
cd c:\Users\saror\Desktop\excelia
flutter pub get
```

#### 3. 특정 플랫폼 설정

**Windows:**
```bash
flutter run -d windows
```

**Mac:**
```bash
flutter run -d macos
```

**Android:**
```bash
flutter run -d android
```

**iOS:**
```bash
flutter run -d ios
```

## 🎮 실행 방법

### 방법 1: IDE에서 실행 (권장)
```bash
# VS Code
- F5 키 또는 디버그 시작
- 또는 터미널에서 'flutter run'

# Android Studio
- 메뉴 Run > Run 선택
```

### 방법 2: 터미널에서 실행
```bash
cd c:\Users\saror\Desktop\excelia
flutter run

# 디버그 모드
flutter run

# 릴리즈 모드
flutter run --release
```

### 방법 3: 수동 빌드 후 실행
```bash
# Windows EXE 생성
flutter build windows

# 생성된 exe 실행
.\build\windows\x64\runner\Release\excelia.exe
```

## 📋 구성 파일 설명

### pubspec.yaml
프로젝트의 메타데이터 및 의존성 정의

```yaml
dependencies:
  excel: ^2.1.0              # 엑셀 파일 처리
  file_picker: ^6.1.1        # 파일 선택 대화상자
  provider: ^6.1.0           # 상태 관리
```

### analysis_options.yaml
Dart 코드 분석 규칙

## 🔥 핫 리로드 & 핫 리스타트

### 핫 리로드 (Hot Reload)
changes를 유지하면서 UI 즉시 반영

```bash
flutter run
# 실행 중 'r' 입력 또는 Ctrl+S (IDE)
```

### 핫 리스타트 (Hot Restart)
상태를 초기화하고 앱 재시작

```bash
flutter run
# 실행 중 'R' 입력
```

## 📦 빌드 및 배포

### 개발 빌드
```bash
flutter build [windows|android|ios|macos|linux]
```

### 릴리즈 빌드
```bash
flutter build [windows|android|ios|macos|linux] --release
```

### 빌드 출력 위치
```
windows: build/windows/x64/runner/Release/
android: build/app/outputs/flutter-apk/
ios:     build/ios/iphoneos/Runner.app
macos:   build/macos/Build/Products/Release/
```

## 🐛 디버깅 팁

### 콘솔 로그 확인
```bash
flutter logs
```

### 특정 에러 확인
```bash
flutter clean
flutter pub get
flutter run -v
```

### 메모리 문제
```bash
# 메모리 사용량 확인
flutter run --profile
```

## 📱 테스트

### 유닛 테스트 실행
```bash
flutter test
```

### 통합 테스트 실행
```bash
flutter drive --target=test_driver/app.dart
```

## ⚙️ 환경 변수

Windows 환경에서 필요한 설정:

```bash
SET ANDROID_HOME=C:\Users\%USERNAME%\AppData\Local\Android\sdk
SET JAVA_HOME=C:\Program Files\Java\jdk-17
```

## 🆘 문제 해결

### 1. "Not connected to the Internet" 에러
```bash
flutter doctor
flutter pub get --offline
```

### 2. 의존성 충돌
```bash
flutter pub upgrade
flutter pub get
```

### 3. 캐시 문제
```bash
flutter clean
flutter pub get
```

### 4. 포트 충돌 (Android)
```bash
adb devices
adb kill-server
flutter run
```

## 📊 프로젝트 헬스 체크

```bash
# 설치 상태 확인
flutter doctor

# 의존성 최신화 확인
flutter pub outdated

# 패키지 보안 확인
flutter pub audit
```

## 🎯 개발 워크플로우

1. **코드 수정** → Ctrl+S 저장
2. **핫 리로드** → 변경사항 즉시 반영
3. **테스트** → 기능 확인
4. **Git 커밋** → 변경사항 저장
5. **릴리즈** → 빌드 및 배포

---

문제가 해결되지 않으면 공식 문서를 참고하세요:
https://flutter.dev/docs

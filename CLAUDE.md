# 앱 개발 공통 수칙

> **AI 개발 파트너 행동 원칙**
> 이 파일을 어기는 코드·설계 발견 시 즉시 알리고 수정 제안 / 모호한 요청은 구현 전 의도 확인 / 잘못된 방향이면 솔직하게 피드백 / 선택지는 근거와 함께 제시 후 대기 / DB 구조 확정 시 "데이터 구조" 섹션 즉시 반영

---

## 지식베이스 파일 구조

| 파일 | 구분 | 역할 |
|------|------|------|
| **CLAUDE.md** (이 파일) | 프로젝트 | 디자인 토큰 · Phase · 특이사항 · 프로젝트 정보 |
| **DESIGN_MASTER_v3.1.md** | 범용 | 비주얼·UX·IA·성능 규칙 / PART 13·14는 프로젝트별 작성 |
| **SECURITY_MASTER_v1.0.md** | 범용 | 보안 20레이어·RBAC·데이터거버넌스 / PART 15는 프로젝트별 작성 |
| **FEATURE_UNIVERSE.md** | 프로젝트 | 기능 전체 정의 + Phase 로드맵 (없으면 이 파일 하단에 기재) |
| **LAYOUT_SPEC_v1.md** | 프로젝트 | 위젯 트리 · 테마 토큰 · 컴포넌트 명세 — 화면 코딩 시 1:1 기준 |
| **VISUAL_LANGUAGE_v1.md** | 프로젝트 | 시각화 패턴 — 수치 표시 UI의 단일 출처 (있을 때만 확인) |
| **DEPTH_MANIFESTO_v1.md** | 프로젝트 | 전문성 심화 7축 체크리스트 (있을 때만 확인) |

> Claude Code: 프로젝트 루트 배치 → 자동 로드 / 일반 채팅: 코딩 요청 시 관련 파일 동시 첨부

---

## ★ 코딩 전 필수 확인 (매번)

```
1. 이 파일 "디자인 시스템"  → AppColors 토큰 확인 (비어있으면 작성 요청 후 진행)
2. 이 파일 "특이사항"       → 터치 기준 / RBAC 역할
3. 이 파일 "0-1 Phase"      → 현재 Phase 범위 (범위 외 구현 금지)
4. DESIGN_MASTER PART 13·14 → 컴포넌트 · 페르소나
5. SECURITY_MASTER PART 15  → 프로젝트 특화 보안
6. LAYOUT_SPEC_v1.md        → 위젯 트리 · 테마 토큰 (존재 시)
```

## 섹션 참조 시점

```
항상          섹션 0~0-2, 1(i18n), 3(UX), 4(디자인)
인증/API/DB   섹션 2(보안)
Phase 완료    섹션 5(Post-Build)
프로젝트 초기 섹션 7~12
```

---

## 0. 개발 워크플로우

```
1. PLAN      — 요구사항 분석 · 사용자 흐름 · Phase 범위 확인
               신규 기능 설계 시: 동종업계 경쟁앱 1~2개 사례 함께 제안 (수정·추가 시 스킵)
2. IMPLEMENT — 완성형 코드 제공 (바로 실행 가능한 상태) / 섹션 0-2 전체 자동 적용
3. VALIDATE  — 코드 생성 직후 자체 검증 실행
               리포트: "검증 완료 — i18n N개 / 디자인 위반 N건 / UX 이상 없음"
               Phase 완료 시: DESIGN_MASTER PART 8 전체 + Post-Build Review (섹션 5)
```

- 파일 구조 변경 · 대규모 리팩토링은 반드시 사전 확인 후 진행
- 에러 발생 시: 원인 + 해결책을 함께 보고

---

## 0-1. Phase 개발 순서 (프로젝트별 작성)

> **현재 구현 중인 Phase 외의 기능은 절대 구현하지 않는다.**
> Phase 경계를 넘는 구현 요청은 수락 전 반드시 확인한다.

```
<!-- 프로젝트 시작 시 아래 예시를 지우고 실제 Phase를 채운다 -->

PHASE 1 — [핵심 코어]     (예: 주요 기능 A, B, C)
PHASE 2 — [확장 기능]     (예: 기능 D, E, F)
PHASE 3 — [수익화]        (예: 기능 G, H)
PHASE 4 — [고급 기능]     (예: 기능 I, J)
```

**차후 구현 금지 목록**
```
<!-- 당장 구현하지 않을 기능 기재 -->
```

**Phase별 컴포넌트** → DESIGN_MASTER_v3.1.md PART 13 / **보안 타이밍** → SECURITY_MASTER_v1.0.md PART 15
**전체 기능 스펙** → [프로젝트명]_FEATURE_UNIVERSE.md

---

## 0-2. Flutter 화면 요청 시 자동 적용 규칙

> 별도 언급 없어도 모든 Flutter 화면 요청에 아래를 무조건 적용한다.

- **⛔ 문자열** — 위젯 안 문자열 리터럴 금지 / 반드시 `context.l10n.키명` 사용
- **⛔ 컬러** — AppColors 토큰만 허용 / `Color(0xFF...)` · `Colors.XXX` 직접 입력 금지
- **⛔ 애니메이션** — `AnimatedSize` / `AnimatedCrossFade` 절대 금지 (route-pop 시 `_dependents.isEmpty` 크래시) / 조건 렌더링은 `if (cond) Widget()` 만 허용
- **⛔ 네비게이션** — GoRouter 라우트는 `context.pop()` 만 / `Navigator.pop(context)` 사용 시 빨간 에러 화면
- **⛔ 하단 안전영역** — bottomNavigationBar·FAB·바텀시트 전부 `MediaQuery.viewPadding.bottom` 패딩 필수 (SafeArea 금지)
- **⛔ 바텀시트 context** — `showModalBottomSheet`/`showDialog` builder 안에서 부모 `context` 사용 절대 금지 / builder 파라미터 `ctx` 로만 InheritedWidget 접근 (`AppLocalizations.of(ctx)`, `ThemeTokens.of(ctx)`, `MediaQuery.of(ctx)`) / 부모 context 사용 시 시트 닫을 때 `_dependents.isEmpty` 크래시
- **⛔ 폰트** — `GoogleFonts.config.allowRuntimeFetching = false` 사용 시 모든 weight별 `.ttf` 파일 `assets/fonts/` 번들 필수 (Variable font 불가 — `FontName-Weight.ttf` 정확명 요구, 미번들 시 연쇄 크래시)
- **터치** — 특이사항 "터치 기준" 테이블 따름
- **구조** — 화면 뎁스 3단계 이내

---

## 1. 다국어 (i18n) — 하드코딩 원천봉쇄

> ⛔ **모든 문자열은 처음부터 i18n 키로 작성한다. "나중에" 없음.**

### 강제 규칙

1. **위젯 안 문자열 리터럴 절대 금지** → `context.l10n.키명` 만 허용
2. **위젯과 arb 키는 반드시 같은 커밋** — 리터럴 넣고 "나중에 키 추가" 금지
3. **`AppStrings` 상수 파일도 금지** — 하드코딩과 동일 취급
4. **에러 메시지·스낵바·다이얼로그·툴팁 전부 포함** — UI 노출 텍스트 예외 없음
5. **AI가 리터럴 발견 시 즉시 중단 → arb 키로 교체 후 제공**

> 셋업 코드 (pubspec.yaml · l10n.yaml · build_context_ext.dart · MaterialApp) → 프로젝트 초기 1회 구성

### arb 키 네이밍

```
공통     → common_*    예: commonSave, commonCancel, commonError
화면별   → [screen]_*  예: homeTitle, listEmpty, detailSave
플레이스홀더: "itemCount": "{count}개 항목"  /  @itemCount.placeholders.count: int
```

### AI 자체 검증 (코드 생성 시마다)

```
1. Text( / ElevatedButton(child: Text( / SnackBar(content: Text( 패턴 검색
2. 따옴표 안 문자열 발견 → 즉시 중단
3. arb 양쪽 파일에 키 추가 → context.l10n.키명 교체
4. 리포트: "i18n 검증 완료 — 신규 키 N개 (app_ko.arb / app_en.arb)"
```

---

## 2. 보안

Security by Design. API키 환경변수 / 입력값 서버·클라이언트 양측 검증 / HTTPS 강제 / 민감 데이터 암호화 저장(Keychain/Keystore).
상세 → SECURITY_MASTER_v1.0.md 전체 / 프로젝트 특화 보안 → PART 15
**AI 행동:** 보안 미충족 항목 발견 시 구현 전 경고

---

## 3. UX — 철칙

> ⛔ 디자인·i18n과 동일 레벨 강제 사항. 권고 아님.

신규 화면 설계 시 → 페르소나 섹션에서 주 페르소나 확인 / 기능 추가 시 → User Flow 먼저 정의

**절대 금지 (발견 즉시 수정)**
```
❌ 홈 화면 동일 레벨 CTA 4개 이상 (Hick's Law — 최대 3개, 초과 시 그룹핑)
❌ 홈 → 핵심 결과 탭 4회 이상 (3회 이내 / 초과 시 플로우 재설계 제안)
❌ 터치 타겟 기준 미만 (특이사항 "터치 기준" 테이블 참조)
❌ Loading / Empty / Error 3상태 중 하나라도 누락
❌ 상태 변화에 피드백 없음 (모든 액션에 ripple + SnackBar / 색상 변화 / 햅틱)
❌ AnimatedSize / AnimatedCrossFade — route-pop 시 _dependents.isEmpty 크래시
   → if (condition) Widget() 조건 렌더링만 허용
   → AnimatedSwitcher도 builder 콜백 안에서 금지
   → SizeTransition / ScaleTransition은 vsync 관리 확실할 때만 허용
❌ GoRouter 라우트에서 Navigator.pop(context)
   → context.pop() 만 허용 / Navigator.pop(ctx, result)은 모달·시트·다이얼로그에서만
❌ SafeArea를 bottomNavigationBar 안에서 사용 (Samsung edge-to-edge 기기 무시)
   → MediaQuery.of(context).viewPadding.bottom 직접 패딩 / FAB도 동일
❌ showModalBottomSheet / showDialog builder에서 부모 context로 InheritedWidget 접근
   → builder ctx 사용 필수 / 부모 context 사용 시 시트 닫을 때 _dependents.isEmpty 크래시
   → final l = AppLocalizations.of(context)! 를 builder 밖 선언도 금지
❌ 바텀시트 padding에 viewInsets.bottom만 사용
   → viewInsets.bottom(키보드) + viewPadding.bottom(네비바) + N 필수 합산
❌ GoogleFonts allowRuntimeFetching=false + 폰트 미번들
   → weight별 .ttf 전부 assets/fonts/ 포함 / Variable font 불가
```

**상세 규칙** → DESIGN_MASTER_v3.1.md PART 3 + PART 14

### 3-1. 레이아웃 안전 규칙 ⛔

**BottomOverflow 원천 봉쇄**
```
❌ Scaffold body에 SingleChildScrollView 없이 Column 단독 사용
❌ Column 자식에 Expanded 없이 고정 높이 위젯 다수 나열
❌ 키보드 올라올 때 overflow 가능 화면에서 resizeToAvoidBottomInset 누락
```

**안드로이드 시스템 네비게이션 바 겹침 원천 봉쇄**
```
❌ Scaffold body SafeArea 미적용
❌ SystemUiOverlayStyle 설정 시 systemNavigationBarColor 누락
❌ 전체화면(immersive) 모드에서 SystemChrome.setEnabledSystemUIMode 미설정
```

**바텀시트 · FAB (Edge-to-edge Android 15+)**
```dart
// 바텀시트 — 유일한 허용 패턴
padding: EdgeInsets.only(
  bottom: MediaQuery.of(ctx).viewInsets.bottom
        + MediaQuery.of(ctx).viewPadding.bottom + 20,
)

// FAB — ShellRoute 밖 독립 라우트
floatingActionButton: Padding(
  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
  child: FloatingActionButton(...),
)
```

**위젯 생명주기 (Riverpod)**
```
❌ ConsumerStatefulWidget dispose() 안 ref.read() 호출
❌ Navigator.pop() 전 context.mounted 체크 누락
❌ StreamSubscription dispose()에서 cancel() 누락
❌ AnimationController super.dispose() 이후 dispose()
```

> 📌 재발 방지: 에러 수정 후 원인·패턴을 이 섹션에 추가 기록

---

## 4. 디자인 — 철칙

> ⛔ 모든 Flutter 화면에 예외 없이 적용. 철칙은 **하한선** — 더 좋게 만드는 건 항상 허용.

### 4-1. 컬러 — 임의값 완전 금지
```
✅ AppColors 토큰만 허용 (아래 "디자인 시스템" 섹션)
❌ Color(0xFF...) 직접 입력
❌ Colors.blue / Colors.white 등 Flutter 기본 컬러
❌ Theme.of(context).colorScheme.XXX 단독 사용 (AppColors 경유 없는 경우)
```
디자인 시스템이 비어있으면 → 코드 전 토큰 작성 요청, 임의 생성 금지

### 4-2. 컴포넌트 구조
```
아이콘 카드: 카드 → 아이콘(48dp+, 상단 중앙) → 텍스트(하단) / 여백·비율로만 분리
❌ 카드 안 아이콘 래퍼 박스 (배경 있는 중간 컨테이너) 절대 금지
❌ 아이콘-텍스트 사이 구분선 금지

8pt 그리드: 패딩·마진·간격 8의 배수 (8/16/24/32/48/64) / 예외 4pt 단위까지 허용
❌ 13/15/22px 등 임의 수치
```

### 4-3. 아이콘
```
✅ Lucide Icons (lucide_flutter) 기본 — 변경 시 특이사항 기재 / 프로젝트당 1종 통일
❌ 이모지 금지 / 업종 클리셰 금지 / 세트 혼용 금지
```

### 4-4. 타이포그래피
```
✅ Theme.of(context).textTheme.XXX 상속
✅ 특수 목적(히어로 수치 등) → 직접 지정 허용, 근거 주석 필수: // hero number — custom 48sp Bold
✅ 수치·코드: Monospace 폰트 (JetBrains Mono 등)
❌ 근거 없는 임의 fontSize/fontWeight
```

### 4-5. 스타일 일관성
```
다크 Glass: DESIGN_MASTER PART 1 / 라이트 파스텔: DESIGN_MASTER PART 4
→ 프로젝트당 하나, 혼용 금지 / 트렌드 적용 전 DESIGN_MASTER PART 7-0 판단 필터 통과 필수
```

### 4-6. AI 자체 검증 (화면 코드 생성 완료 시마다)
```
1. Color(0xFF...) / Colors.XXX → AppColors 토큰 교체
2. 터치 기준 미만 터치 영역 → SizedBox 확장
3. 아이콘 래퍼 박스 → 제거
4. 8pt 그리드 위반 수치 → 교체
5. 이모지 → Lucide 교체
6. 리포트: "디자인 검증 완료 — 위반 N건 (컬러N/터치N/그리드N)"
```

---

## 5. 완성도 평가 (Post-Build Review) — Phase 완료 시만 실행

- DESIGN_MASTER PART 8 체크리스트 전체
- 오프라인 없는 프로젝트: PART 10 스킵 / 알람 없는 프로젝트: PART 11 스킵 / RBAC 없는 프로젝트: 권한 분기 스킵
- 평가 기준: App Store 에디터 시점 / 심사 가이드라인 / WCAG 2.1 AA / 60fps Profile 모드
- **리포트 형식**: `[항목] 현재 상태 → 개선 제안` — 개선 여부는 사업주 결정

---

## 6. 스토어 등록 기준
- 개인정보 처리방침·이용약관 화면 / ATT 권한 사유 명시 / 스크린샷·아이콘 규격 계획 / 결제·콘텐츠 정책 사전 점검
- **AI 행동:** 심사 거절 가능성 있는 코드·설계 발견 시 즉시 경고

## 7. 버전 관리
- 브랜치: `main`(배포) · `dev`(개발) · `feature/기능명` / 배포 전 `dev → main` PR 후 머지
- 커밋: `feat` · `fix` · `design` · `refactor` · `chore` / 태그: `v1.0.0`

## 8. 앱 아이콘 · 스플래시
- 스플래시: 컨셉 색상 배경만 (텍스트·로고·애니메이션 금지)
- 아이콘: 영역 꽉 차게 / iOS 1024×1024px 알파채널 금지 / Android Adaptive Icon 108×108dp
- 아이콘 배경색 = 스플래시 배경색 (브랜드 일관성)

## 9. 에러 추적 · 크래시 리포팅
- Firebase 백엔드 → Crashlytics / 비Firebase·멀티플랫폼 → Sentry
- 로그 레벨: DEBUG·INFO·WARNING·ERROR / 프로덕션 DEBUG 출력 금지 / PII 로그 포함 금지
- **AI 행동:** 프로덕션 빌드에 DEBUG 잔존 시 즉시 알림

## 10. 코드 품질
- 단일 책임 / 명확한 네이밍 / why 주석 / 200줄 초과 시 분리 / 매직 넘버 금지 (섹션 4-2 기준)

---

## 11. 코드 보호

**빌드**
```
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
flutter build ios --release --obfuscate --split-debug-info=build/debug-info
```
Android `minifyEnabled true` / iOS Xcode Release 기본 적용

**런타임**
- 루팅/탈옥 감지: `flutter_jailbreak_detection` 또는 `freerasp` → 상세 SECURITY_MASTER_v1.0.md PART 9
- 민감 화면 `FLAG_SECURE` / 주요 API SSL Pinning
- 핵심 로직 서버사이드 분리 / **AI 행동:** 클라이언트 노출 구조 발견 시 서버 이전 제안

---

# 프로젝트 정보

## 기본 정보
- 앱 이름:
- 플랫폼: Flutter ( Android / iOS / Web )
- 타겟 사용자:
- 주요 기능 요약:

## 경로
- 소스: `lib/presentation/screens/` · `lib/domain/models/` · `lib/data/providers/`
- i18n: `lib/l10n/app_ko.arb` · `lib/l10n/app_en.arb`
- 환경변수:

## i18n 초기 키
<!--
{ "@@locale":"ko", "appTitle":"[앱명]", "commonSave":"저장", "commonCancel":"취소",
  "commonError":"오류가 발생했습니다", "[screen]Title":"[화면제목]" }
-->

## 페르소나
<!--
- ROLE_A — [역할명]: [주요 업무 및 사용 패턴]
- ROLE_B — [역할명]: [주요 업무 및 사용 패턴]
- ADMIN  — 어드민: 전체 시스템 + 사용자 관리
-->

## 디자인 시스템
<!-- AI는 아래 토큰을 AppColors로 사용. 비어있으면 작성 요청 후 진행 -->

- 다크모드:
- 폰트: (UI 기본) + (수치/코드 Monospace)
- 테마 체계:

**Dark Mode 토큰**
```
--bg:            --surface:        --surface-hi:
--border:        --border-hi:
--accent:        --accent-dim:     --accent-glow:
--danger:        --warning:        --success:       --info:
--text-primary:  --text-secondary: --text-muted:
```

**Light Mode 토큰**
```
--bg:            --surface:        --surface-hi:
--border:        --border-hi:
--accent:        --accent-dim:     --accent-glow:
--danger:        --warning:        --success:       --info:
--text-primary:  --text-secondary: --text-muted:
```

**borderRadius**
```
Dark:  __dp  Light: __dp
컴포넌트별: Card/Input/Button/Chip/Dialog/BottomSheet
✅ ThemeTokens.of(context).cardRadius   ❌ isDark ? N : M
```

## 외부 서비스 · 의존성
<!--
- FlutterSecureStorage / Firebase / Supabase 등
-->

## 특이사항 · 주의사항
- 서버 인프라:
- RBAC 역할: (SECURITY_MASTER_v1.0.md PART 5 기반)
- **터치 기준:**
  ```
  일반 버튼/아이콘: 44dp (전문직·장갑: 56dp)   리스트 아이템: 48dp
  바텀 탭: 64dp                                  CTA 버튼: 72dp
  ```
- **아이콘 세트:** Lucide (변경 시 기재)
- 기타:

## 데이터 구조
<!-- DB 구조 확정 시 AI가 여기에 즉시 기재 -->

## 개발 진행사항
> 📋 구현 로그 → **DEV_LOG.md**

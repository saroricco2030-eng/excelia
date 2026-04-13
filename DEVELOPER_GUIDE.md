# 📚 Excelia 개발자 문서

## 코드 아키텍처

### 1. ExcelProvider (상태 관리)

**역할**: 엑셀 데이터와 UI 상태를 관리하는 ChangeNotifier

```dart
class ExcelProvider extends ChangeNotifier {
  Excel? excel;
  late String currentSheet;
  String? filePath;
}
```

**주요 메서드**:
- `createNewExcel()`: 새 Excel 객체 생성
- `loadExcel(File file)`: 파일에서 Excel 로드
- `switchSheet(String name)`: 시트 전환
- `addSheet(String name)`: 새 시트 추가
- `getCurrentSheet()`: 현재 시트 반환
- `setCellValue(int row, int col, String value)`: 셀 값 설정

### 2. MyApp (루트 위젯)

**역할**: 애플리케이션 설정 및 테마 정의

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ExcelProvider(),
      child: MaterialApp(
        title: 'Excelia',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0078D4),
          ),
        ),
      ),
    );
  }
}
```

**특징**:
- Microsoft Blue (#0078D4) 기반 Material 3 테마
- Provider를 통한 상태 관리 설정
- 전역 UI 테마 정의

### 3. MyHomePage (메인 화면)

**역할**: 메인 UI 레이아웃 및 사용자 상호작용 관리

**주요 UI 요소**:
```
┌─────────────────────────────────┐
│  [파일열기][저장]  Excelia 메뉴  │
├─────────────────────────────────┤
│[모두선택][B I U][색상][셀주소]   │ <- 포맷팅 도구바
├─────────────────────────────────┤
│ Sheet1 | Sheet2 | Sheet3 | [+]  │ <- 시트 탭
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────┐    │
│  │ A | B | C | D | E | ... │    │
│  ├─────────────────────────┤    │
│  │1│ a │ b │ c │ ...      │    │
│  │2│   │   │   │ ...      │    │
│  │3│   │   │   │ ...      │    │
│  └─────────────────────────┘    │ <- 스프레드시트
│                                 │
└─────────────────────────────────┘
```

**주요 메서드**:
- `_buildToolbar()`: 포맷팅 도구바 생성
- `_buildSheetTabs()`: 시트 탭 생성
- `_openFile()`: 파일 열기 대화상자
- `_saveFile()`: 파일 저장

### 4. SpreadsheetViewer (스프레드시트 표시)

**역할**: 엑셀 데이터를 그리드로 표시하고 편집

```dart
class SpreadsheetViewer extends StatefulWidget {
  final ExcelProvider provider;
}
```

**구조**:
```
Row
├─ Column (Row Headers)
│  ├─ CornerCell
│  └─ RowHeader x N
└─ Column (Data)
   ├─ Row (Column Headers)
   │  └─ ColumnHeader x M
   └─ Row (Data Rows)
      └─ DataCell x (N×M)
```

**주요 메서드**:
- `_getMaxColumns()`: 최대 열 개수 계산
- `_getColumnName()`: 열 이름 (A, B, C...) 생성
- `_buildDataCell()`: 데이터 셀 위젯 생성
- `_editCell()`: 셀 편집 다이얼로그 표시

---

## 데이터 흐름

### 1. 파일 열기 흐름
```
FilePicker.pickFiles()
    ↓
_openFile()
    ↓
context.read<ExcelProvider>().loadExcel(file)
    ↓
ExcelProvider.loadExcel()
    ↓
Excel.decodeBytes()
    ↓
notifyListeners() → UI 업데이트
```

### 2. 셀 편집 흐름
```
User clicks cell
    ↓
_editCell()
    ↓
showDialog() → EditDialog
    ↓
User enters value
    ↓
provider.setCellValue()
    ↓
sheet.updateCell()
    ↓
notifyListeners() → SpreadsheetViewer rebuild
```

### 3. 파일 저장 흐름
```
User clicks save icon
    ↓
_saveFile()
    ↓
provider.excel.save()
    ↓
file.writeAsBytes()
    ↓
Documents folder save
    ↓
Show success SnackBar
```

---

## 스타일 및 색상 체계 (Polaris Design)

### 색상 팔레트
```dart
// 주색 (Microsoft Blue)
const Color primaryColor = Color(0xFF0078D4);

// 배경색
const Color backgroundColor = Color(0xFFF3F3F3);
const Color cellBackground = Colors.white;

// 테두리
const Color borderColor = Color(0xFFD0D0D0); // Colors.grey.shade300
```

### 타이포그래피
```dart
// 제목
TextStyle(fontSize: 32, fontWeight: FontWeight.bold)

// 셀 데이터
TextStyle(fontSize: 12)

// 헤더
TextStyle(fontSize: 12, fontWeight: FontWeight.bold)

// 설명글
TextStyle(fontSize: 16, color: Colors.grey)
```

---

## 주요 UI 컴포넌트

### 1. 포맷팅 도구바
```dart
// 구성: 선택 | 텍스트 스타일 | 색상 | 셀주소
Row(
  children: [
    SelectAllButton(),
    VerticalDivider(),
    BoldButton(),
    ItalicButton(),
    UnderlineButton(),
    VerticalDivider(),
    BackgroundColorButton(),
    TextColorButton(),
    CellAddressField(),
  ],
)
```

### 2. 시트 탭
```dart
// 활성 시트: 파란색 밑줄, 굵은 글자
// 비활성 시트: 회색 밑줄, 일반 글자
GestureDetector(
  onTap: () => switchSheet(sheetName),
  child: Container(
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: isActive ? primaryColor : Colors.grey,
        ),
      ),
    ),
  ),
)
```

### 3. 셀 편집 다이얼로그
```dart
AlertDialog(
  title: Text('${columnName}${rowIndex + 1} 편집'),
  content: TextField(
    maxLines: null,
    decoration: InputDecoration(
      hintText: '셀 값을 입력하세요',
      border: OutlineInputBorder(),
    ),
  ),
  actions: [CancelButton(), SaveButton()],
)
```

---

## 주요 라이브러리 API

### excel 패키지
```dart
// 새 엑셀 생성
Excel excel = Excel.createExcel();

// 파일에서 로드
var bytes = await file.readAsBytes();
Excel excel = Excel.decodeBytes(bytes);

// 현재 시트 접근
var sheet = excel.sheets['Sheet1'];

// 셀 값 설정
sheet.updateCell(
  CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
  'Hello'
);

// 파일 저장
var bytes = excel.save();
```

### file_picker 패키지
```dart
// 파일 선택
final result = await FilePicker.platform.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['xlsx', 'xls'],
);

if (result != null) {
  final file = File(result.files.first.path!);
}
```

### provider 패키지
```dart
// ChangeNotifier 정의
class MyProvider extends ChangeNotifier {
  void update() {
    notifyListeners(); // UI 업데이트 트리거
  }
}

// UI에서 사용
Consumer<MyProvider>(
  builder: (context, provider, _) {
    return Text(provider.data);
  },
)

// 프로그래매틱 접근
context.read<MyProvider>().update();
```

---

## 향후 개발 가이드

### 기능 추가: 셀 서식 적용

**1단계**: ExcelProvider에 메서드 추가
```dart
void setCellFormat(int row, int col, CellStyle style) {
  final sheet = getCurrentSheet();
  final cellIndex = CellIndex.indexByColumnRow(
    columnIndex: col,
    rowIndex: row,
  );
  final cell = sheet?.cell(cellIndex);
  cell?.cellStyle = style;
  notifyListeners();
}
```

**2단계**: UI에서 호출
```dart
context.read<ExcelProvider>().setCellFormat(
  rowIndex,
  colIndex,
  CellStyle(bold: true),
);
```

### 기능 추가: 수식 지원

**1단계**: 수식 해석기 추가
```dart
class FormulaEngine {
  double evaluate(String formula, Sheet sheet) {
    // SUM(A1:A10) 같은 수식 분석
    // 결과 계산 및 반환
  }
}
```

**2단계**: 셀에서 감지 및 계산
```dart
void setCellValue(int row, int col, String value) {
  if (value.startsWith('=')) {
    final result = formulaEngine.evaluate(value);
    // 결과 저장
  } else {
    // 일반 텍스트 저장
  }
}
```

---

## 성능 최적화 팁

1. **대용량 파일 처리**
   - 한 번에 작은 청크 단위로 처리
   - 가상 스크롤링 구현

2. **메모리 관리**
   - 불필요한 위젯 재빌드 최소화
   - StatefulWidget 활용

3. **UI 반응성**
   - 비동기 작업에 async/await 사용
   - Heavy 작업은 isolate에서 실행

---

## 테스트 작성 예제

```dart
void main() {
  group('ExcelProvider Tests', () {
    test('Create new excel', () {
      final provider = ExcelProvider();
      provider.createNewExcel();
      expect(provider.excel, isNotNull);
      expect(provider.currentSheet, equals('Sheet1'));
    });

    test('Set cell value', () {
      final provider = ExcelProvider();
      provider.createNewExcel();
      provider.setCellValue(0, 0, 'Test');
      // Assertion 추가
    });
  });
}
```

---

## 디버깅 팁

```dart
// 구간 로깅
print('DEBUG: Excel loaded at ${DateTime.now()}');

// 객체 상태 확인
print('DEBUG: Current sheet = ${provider.currentSheet}');
print('DEBUG: Cell value = ${sheet.cell(...).value}');

// 성능 측정
final stopwatch = Stopwatch()..start();
// 코드 실행
stopwatch.stop();
print('Elapsed: ${stopwatch.elapsedMilliseconds}ms');
```

---

## 참고 자료

- **Flutter 공식 문서**: https://flutter.dev/docs
- **Excel 패키지 문서**: https://pub.dev/packages/excel
- **Provider 패키지**: https://pub.dev/packages/provider
- **File Picker 문서**: https://pub.dev/packages/file_picker

---

**Happy Coding! 🚀**

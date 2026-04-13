import 'dart:math' as math;

/// Excel 호환 수식 엔진 — 재귀 하강 파서 + 150개 내장 함수
///
/// 지원: 산술(+,-,*,/), 비교(>,<,>=,<=,=,<>), 문자열("..."),
///       셀 참조(A1), 범위(A1:C5), 중첩 함수, 음수(-A1)
class FormulaEngine {
  /// 셀 값 조회 콜백: (row, col) → raw value (String? or num?)
  final dynamic Function(int row, int col) getCellValue;

  /// 셀 표시 값 조회 (수식 결과 포함)
  final String Function(int row, int col) getCellDisplay;

  /// 셀 참조 파싱
  final (int, int)? Function(String ref) parseCellRef;

  /// Tracks cells currently being evaluated to detect circular references.
  final Set<String> _evaluatingCells = {};

  FormulaEngine({
    required this.getCellValue,
    required this.getCellDisplay,
    required this.parseCellRef,
  });

  /// 순환 참조 감지를 포함하는 셀 수식 평가.
  /// [cellRef] 는 평가 중인 셀의 참조(예: "A1").
  String evaluateCell(String cellRef, String formula) {
    if (_evaluatingCells.contains(cellRef)) {
      return '!REF'; // 순환 참조 감지
    }
    _evaluatingCells.add(cellRef);
    try {
      return evaluate(formula);
    } finally {
      _evaluatingCells.remove(cellRef);
    }
  }

  /// 수식 문자열(= 포함) 평가 → 결과 문자열
  String evaluate(String formula) {
    try {
      final expr = formula.substring(1).trim(); // '=' 제거
      if (expr.isEmpty) return '';
      final tokens = _tokenize(expr);
      if (tokens.isEmpty) return '';
      final parser = _Parser(tokens, this);
      final result = parser.parseExpression();
      if (parser.pos < tokens.length) return '!ERR';
      return _formatResult(result);
    } catch (e) {
      if (e is FormulaError) return e.message;
      return '!ERR';
    }
  }

  String _formatResult(dynamic value) {
    if (value == null) return '';
    if (value is bool) return value ? 'TRUE' : 'FALSE';
    if (value is num) {
      if (value.isNaN || value.isInfinite) return '!ERR';
      if (value == value.toInt()) return value.toInt().toString();
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }

  // ─── Tokenizer ───────────────────────────────────────────

  List<_Token> _tokenize(String input) {
    final tokens = <_Token>[];
    int i = 0;
    while (i < input.length) {
      final c = input[i];

      // 공백 건너뛰기
      if (c == ' ' || c == '\t') {
        i++;
        continue;
      }

      // 숫자 리터럴
      if (_isDigit(c) || (c == '.' && i + 1 < input.length && _isDigit(input[i + 1]))) {
        final start = i;
        while (i < input.length && (_isDigit(input[i]) || input[i] == '.')) {
          i++;
        }
        // 1E+5 형식 (과학 표기)
        if (i < input.length && (input[i] == 'E' || input[i] == 'e')) {
          i++;
          if (i < input.length && (input[i] == '+' || input[i] == '-')) i++;
          while (i < input.length && _isDigit(input[i])) {
            i++;
          }
        }
        tokens.add(_Token(_TType.number, input.substring(start, i)));
        continue;
      }

      // 문자열 리터럴 "..."
      if (c == '"') {
        i++;
        final sb = StringBuffer();
        while (i < input.length && input[i] != '"') {
          if (input[i] == '\\' && i + 1 < input.length) {
            i++;
            sb.write(input[i]);
          } else {
            sb.write(input[i]);
          }
          i++;
        }
        if (i < input.length) i++; // closing "
        tokens.add(_Token(_TType.string, sb.toString()));
        continue;
      }

      // 연산자 & 비교
      if (c == '+') {
        tokens.add(_Token(_TType.op, '+'));
        i++;
        continue;
      }
      if (c == '-') {
        tokens.add(_Token(_TType.op, '-'));
        i++;
        continue;
      }
      if (c == '*') {
        tokens.add(_Token(_TType.op, '*'));
        i++;
        continue;
      }
      if (c == '/') {
        tokens.add(_Token(_TType.op, '/'));
        i++;
        continue;
      }
      if (c == '^') {
        tokens.add(_Token(_TType.op, '^'));
        i++;
        continue;
      }
      if (c == '&') {
        tokens.add(_Token(_TType.op, '&'));
        i++;
        continue;
      }
      if (c == '%') {
        tokens.add(_Token(_TType.op, '%'));
        i++;
        continue;
      }

      // 비교 연산자
      if (c == '<') {
        if (i + 1 < input.length && input[i + 1] == '=') {
          tokens.add(_Token(_TType.cmp, '<='));
          i += 2;
        } else if (i + 1 < input.length && input[i + 1] == '>') {
          tokens.add(_Token(_TType.cmp, '<>'));
          i += 2;
        } else {
          tokens.add(_Token(_TType.cmp, '<'));
          i++;
        }
        continue;
      }
      if (c == '>') {
        if (i + 1 < input.length && input[i + 1] == '=') {
          tokens.add(_Token(_TType.cmp, '>='));
          i += 2;
        } else {
          tokens.add(_Token(_TType.cmp, '>'));
          i++;
        }
        continue;
      }
      if (c == '=') {
        tokens.add(_Token(_TType.cmp, '='));
        i++;
        continue;
      }

      // 괄호, 쉼표, 콜론
      if (c == '(') {
        tokens.add(_Token(_TType.lparen, '('));
        i++;
        continue;
      }
      if (c == ')') {
        tokens.add(_Token(_TType.rparen, ')'));
        i++;
        continue;
      }
      if (c == ',') {
        tokens.add(_Token(_TType.comma, ','));
        i++;
        continue;
      }
      if (c == ':') {
        tokens.add(_Token(_TType.colon, ':'));
        i++;
        continue;
      }

      // 식별자 (함수명 또는 셀 참조)
      if (_isAlpha(c)) {
        final start = i;
        while (i < input.length && (_isAlpha(input[i]) || _isDigit(input[i]) || input[i] == '_' || input[i] == '\$')) {
          i++;
        }
        final word = input.substring(start, i);
        final upper = word.toUpperCase();

        // TRUE/FALSE 리터럴
        if (upper == 'TRUE') {
          tokens.add(_Token(_TType.boolean, 'TRUE'));
          continue;
        }
        if (upper == 'FALSE') {
          tokens.add(_Token(_TType.boolean, 'FALSE'));
          continue;
        }

        // 다음이 '(' → 함수
        if (i < input.length && input[i] == '(') {
          tokens.add(_Token(_TType.func, upper));
          continue;
        }

        // 셀 참조 (A1, $A$1, AA10 등)
        final cleaned = upper.replaceAll('\$', '');
        if (RegExp(r'^[A-Z]+\d+$').hasMatch(cleaned)) {
          tokens.add(_Token(_TType.cellRef, cleaned));
          continue;
        }

        // 그 외 → 알 수 없는 식별자 (함수명일 수 있음)
        tokens.add(_Token(_TType.func, upper));
        continue;
      }

      // 알 수 없는 문자 → 건너뛰기
      i++;
    }
    return tokens;
  }

  bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
  bool _isAlpha(String c) {
    final code = c.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122) || c == '_' || c == '\$';
  }
}

// ─── Token Types ─────────────────────────────────────────

enum _TType { number, string, boolean, cellRef, func, op, cmp, lparen, rparen, comma, colon }

class _Token {
  final _TType type;
  final String value;
  const _Token(this.type, this.value);
  @override
  String toString() => '${type.name}:$value';
}

class FormulaError implements Exception {
  final String message;
  const FormulaError(this.message);
}

// ─── Recursive Descent Parser ────────────────────────────

class _Parser {
  final List<_Token> tokens;
  final FormulaEngine engine;
  int pos = 0;

  _Parser(this.tokens, this.engine);

  _Token? peek() => pos < tokens.length ? tokens[pos] : null;
  _Token consume() => tokens[pos++];
  bool check(_TType type) => peek()?.type == type;
  bool checkValue(String value) => peek()?.value == value;

  _Token expect(_TType type) {
    if (!check(type)) throw const FormulaError('!ERR');
    return consume();
  }

  // expression → comparison
  dynamic parseExpression() => _parseConcat();

  // 문자열 연결 (&)
  dynamic _parseConcat() {
    var left = _parseComparison();
    while (check(_TType.op) && peek()!.value == '&') {
      consume();
      final right = _parseComparison();
      left = '${_toStr(left)}${_toStr(right)}';
    }
    return left;
  }

  // comparison → addition ((>,<,>=,<=,=,<>) addition)?
  dynamic _parseComparison() {
    var left = _parseAddition();
    if (check(_TType.cmp)) {
      final op = consume().value;
      final right = _parseAddition();
      return _compare(left, right, op);
    }
    return left;
  }

  // addition → multiply ((+|-) multiply)*
  dynamic _parseAddition() {
    var left = _parseMultiply();
    while (check(_TType.op) && (peek()!.value == '+' || peek()!.value == '-')) {
      final op = consume().value;
      final right = _parseMultiply();
      final l = _toNum(left);
      final r = _toNum(right);
      left = op == '+' ? l + r : l - r;
    }
    return left;
  }

  // multiply → power ((*|/) power)*
  dynamic _parseMultiply() {
    var left = _parsePower();
    while (check(_TType.op) && (peek()!.value == '*' || peek()!.value == '/')) {
      final op = consume().value;
      final right = _parsePower();
      final l = _toNum(left);
      final r = _toNum(right);
      if (op == '/' && r == 0) throw const FormulaError('!DIV/0');
      left = op == '*' ? l * r : l / r;
    }
    return left;
  }

  // power → unary (^ unary)*
  dynamic _parsePower() {
    var left = _parseUnary();
    while (check(_TType.op) && peek()!.value == '^') {
      consume();
      final right = _parseUnary();
      left = math.pow(_toNum(left), _toNum(right));
    }
    return left;
  }

  // unary → (- unary) | postfix
  dynamic _parseUnary() {
    if (check(_TType.op) && peek()!.value == '-') {
      consume();
      final val = _parseUnary();
      return -_toNum(val);
    }
    if (check(_TType.op) && peek()!.value == '+') {
      consume();
      return _parseUnary();
    }
    return _parsePostfix();
  }

  // postfix → primary (%)?
  dynamic _parsePostfix() {
    var val = _parsePrimary();
    if (check(_TType.op) && peek()!.value == '%') {
      consume();
      val = _toNum(val) / 100;
    }
    return val;
  }

  // primary → NUMBER | STRING | BOOLEAN | CELL_REF(:CELL_REF)? | func_call | (expression)
  dynamic _parsePrimary() {
    final t = peek();
    if (t == null) throw const FormulaError('!ERR');

    // 숫자 리터럴
    if (t.type == _TType.number) {
      consume();
      return num.parse(t.value);
    }

    // 문자열 리터럴
    if (t.type == _TType.string) {
      consume();
      return t.value;
    }

    // 불린
    if (t.type == _TType.boolean) {
      consume();
      return t.value == 'TRUE';
    }

    // 셀 참조 (범위 또는 단일)
    if (t.type == _TType.cellRef) {
      consume();
      // 범위 A1:C5
      if (check(_TType.colon)) {
        consume();
        final end = expect(_TType.cellRef);
        return _CellRange(t.value, end.value);
      }
      // 단일 셀 → 값 해석
      return _resolveCellValue(t.value);
    }

    // 함수 호출
    if (t.type == _TType.func) {
      final funcName = consume().value;
      expect(_TType.lparen);
      final args = <dynamic>[];
      if (!check(_TType.rparen)) {
        args.add(_parseArg());
        while (check(_TType.comma)) {
          consume();
          args.add(_parseArg());
        }
      }
      expect(_TType.rparen);
      return _callFunction(funcName, args);
    }

    // 괄호
    if (t.type == _TType.lparen) {
      consume();
      final val = parseExpression();
      expect(_TType.rparen);
      return val;
    }

    throw const FormulaError('!ERR');
  }

  // 함수 인자: 범위(A1:C5) 또는 expression
  dynamic _parseArg() {
    // 범위 패턴 감지: CELL_REF : CELL_REF
    if (check(_TType.cellRef) && pos + 1 < tokens.length && tokens[pos + 1].type == _TType.colon) {
      final start = consume();
      consume(); // :
      final end = expect(_TType.cellRef);
      return _CellRange(start.value, end.value);
    }
    return parseExpression();
  }

  // ─── Cell Resolution ───────────────────────────────────

  dynamic _resolveCellValue(String ref) {
    final parsed = engine.parseCellRef(ref);
    if (parsed == null) throw const FormulaError('!REF');
    final raw = engine.getCellValue(parsed.$1, parsed.$2);
    if (raw == null) return 0;
    final s = raw.toString();
    if (s.isEmpty) return 0;
    if (s.startsWith('=')) {
      // 다른 셀의 수식 결과 참조
      final display = engine.getCellDisplay(parsed.$1, parsed.$2);
      final n = num.tryParse(display);
      return n ?? display;
    }
    final n = num.tryParse(s);
    return n ?? s;
  }

  /// 범위를 값 리스트로 풀기
  List<dynamic> _expandRange(_CellRange range) {
    final s = engine.parseCellRef(range.start);
    final e = engine.parseCellRef(range.end);
    if (s == null || e == null) throw const FormulaError('!REF');
    final vals = <dynamic>[];
    for (int r = s.$1; r <= e.$1; r++) {
      for (int c = s.$2; c <= e.$2; c++) {
        final raw = engine.getCellValue(r, c);
        if (raw == null || raw.toString().isEmpty) {
          vals.add(null);
        } else {
          final str = raw.toString();
          if (str.startsWith('=')) {
            final display = engine.getCellDisplay(r, c);
            final n = num.tryParse(display);
            vals.add(n ?? display);
          } else {
            final n = num.tryParse(str);
            vals.add(n ?? str);
          }
        }
      }
    }
    return vals;
  }

  /// 인자를 숫자 리스트로 변환 (범위 자동 확장)
  List<num> _flattenNums(List<dynamic> args) {
    final nums = <num>[];
    for (final a in args) {
      if (a is _CellRange) {
        for (final v in _expandRange(a)) {
          final n = _tryNum(v);
          if (n != null) nums.add(n);
        }
      } else if (a is num) {
        nums.add(a);
      } else if (a is String) {
        final n = num.tryParse(a);
        if (n != null) nums.add(n);
      }
    }
    return nums;
  }

  /// 인자를 전체 값 리스트로 변환 (null 포함)
  List<dynamic> _flattenAll(List<dynamic> args) {
    final vals = <dynamic>[];
    for (final a in args) {
      if (a is _CellRange) {
        vals.addAll(_expandRange(a));
      } else {
        vals.add(a);
      }
    }
    return vals;
  }

  // ══════════════════════════════════════════════════════════
  // ═══ Function Dispatch (150+ built-in functions) ═══════
  // ══════════════════════════════════════════════════════════

  dynamic _callFunction(String name, List<dynamic> args) {
    switch (name) {
      // ── 수학 (38) ──────────────────────────────────────────
      case 'ABS':
        return (_toNum(_evalArg(args, 0))).abs();
      case 'CEILING':
        final v = _toNum(_evalArg(args, 0)).toDouble();
        final s = args.length > 1 ? _toNum(_evalArg(args, 1)).toDouble() : 1.0;
        if (s == 0) return 0;
        return (v / s).ceil() * s;
      case 'FLOOR':
        final v = _toNum(_evalArg(args, 0)).toDouble();
        final s = args.length > 1 ? _toNum(_evalArg(args, 1)).toDouble() : 1.0;
        if (s == 0) return 0;
        return (v / s).floor() * s;
      case 'INT':
        return _toNum(_evalArg(args, 0)).toInt();
      case 'MOD':
        final a = _toNum(_evalArg(args, 0));
        final b = _toNum(_evalArg(args, 1));
        if (b == 0) throw const FormulaError('!DIV/0');
        return a % b;
      case 'POWER':
        return math.pow(_toNum(_evalArg(args, 0)), _toNum(_evalArg(args, 1)));
      case 'ROUND':
        final v = _toNum(_evalArg(args, 0)).toDouble();
        final d = args.length > 1 ? _toNum(_evalArg(args, 1)).toInt() : 0;
        final f = math.pow(10, d);
        return (v * f).roundToDouble() / f;
      case 'ROUNDUP':
        final v = _toNum(_evalArg(args, 0)).toDouble();
        final d = args.length > 1 ? _toNum(_evalArg(args, 1)).toInt() : 0;
        final f = math.pow(10, d);
        return (v.isNegative ? (v * f).floor() : (v * f).ceil()) / f;
      case 'ROUNDDOWN':
        final v = _toNum(_evalArg(args, 0)).toDouble();
        final d = args.length > 1 ? _toNum(_evalArg(args, 1)).toInt() : 0;
        final f = math.pow(10, d);
        return (v.isNegative ? (v * f).ceil() : (v * f).floor()) / f;
      case 'SQRT':
        final v = _toNum(_evalArg(args, 0)).toDouble();
        if (v < 0) throw const FormulaError('!NUM');
        return math.sqrt(v);
      case 'RAND':
        return math.Random().nextDouble();
      case 'RANDBETWEEN':
        final lo = _toNum(_evalArg(args, 0)).toInt();
        final hi = _toNum(_evalArg(args, 1)).toInt();
        return lo + math.Random().nextInt(hi - lo + 1);
      case 'PI':
        return math.pi;
      case 'SIGN':
        final v = _toNum(_evalArg(args, 0));
        return v > 0 ? 1 : (v < 0 ? -1 : 0);
      // ── 수학 (신규 24) ─────────────────────────────────────
      case 'LOG':
        final v = _toNum(_evalArg(args, 0)).toDouble();
        final base = args.length > 1 ? _toNum(_evalArg(args, 1)).toDouble() : 10.0;
        if (v <= 0 || base <= 0 || base == 1) throw const FormulaError('!NUM');
        return math.log(v) / math.log(base);
      case 'LOG10':
        final v = _toNum(_evalArg(args, 0)).toDouble();
        if (v <= 0) throw const FormulaError('!NUM');
        return math.log(v) / math.ln10;
      case 'LN':
        final v = _toNum(_evalArg(args, 0)).toDouble();
        if (v <= 0) throw const FormulaError('!NUM');
        return math.log(v);
      case 'EXP':
        return math.exp(_toNum(_evalArg(args, 0)).toDouble());
      case 'FACT':
        final n = _toNum(_evalArg(args, 0)).toInt();
        if (n < 0) throw const FormulaError('!NUM');
        return _factorial(n);
      case 'COMBIN':
        final n = _toNum(_evalArg(args, 0)).toInt();
        final k = _toNum(_evalArg(args, 1)).toInt();
        if (n < 0 || k < 0 || k > n) throw const FormulaError('!NUM');
        return _factorial(n) ~/ (_factorial(k) * _factorial(n - k));
      case 'PERMUT':
        final n = _toNum(_evalArg(args, 0)).toInt();
        final k = _toNum(_evalArg(args, 1)).toInt();
        if (n < 0 || k < 0 || k > n) throw const FormulaError('!NUM');
        return _factorial(n) ~/ _factorial(n - k);
      case 'GCD':
        final nums = _flattenNums(args).map((n) => n.toInt().abs()).toList();
        if (nums.isEmpty) return 0;
        return nums.reduce(_gcd);
      case 'LCM':
        final nums = _flattenNums(args).map((n) => n.toInt().abs()).toList();
        if (nums.isEmpty) return 0;
        return nums.reduce((a, b) => b == 0 ? 0 : (a * b) ~/ _gcd(a, b));
      case 'RADIANS':
        return _toNum(_evalArg(args, 0)).toDouble() * math.pi / 180;
      case 'DEGREES':
        return _toNum(_evalArg(args, 0)).toDouble() * 180 / math.pi;
      case 'SIN':
        return math.sin(_toNum(_evalArg(args, 0)).toDouble());
      case 'COS':
        return math.cos(_toNum(_evalArg(args, 0)).toDouble());
      case 'TAN':
        return math.tan(_toNum(_evalArg(args, 0)).toDouble());
      case 'ASIN':
        final v = _toNum(_evalArg(args, 0)).toDouble();
        if (v < -1 || v > 1) throw const FormulaError('!NUM');
        return math.asin(v);
      case 'ACOS':
        final v = _toNum(_evalArg(args, 0)).toDouble();
        if (v < -1 || v > 1) throw const FormulaError('!NUM');
        return math.acos(v);
      case 'ATAN':
        return math.atan(_toNum(_evalArg(args, 0)).toDouble());
      case 'ATAN2':
        final y = _toNum(_evalArg(args, 0)).toDouble();
        final x = _toNum(_evalArg(args, 1)).toDouble();
        return math.atan2(y, x);
      case 'PRODUCT':
        final nums = _flattenNums(args);
        return nums.isEmpty ? 0 : nums.fold<num>(1, (a, b) => a * b);
      case 'SUMSQ':
        final nums = _flattenNums(args);
        return nums.fold<num>(0, (a, b) => a + b * b);
      case 'TRUNC':
        final v = _toNum(_evalArg(args, 0)).toDouble();
        final d = args.length > 1 ? _toNum(_evalArg(args, 1)).toInt() : 0;
        final f = math.pow(10, d);
        return (v * f).truncateToDouble() / f;
      case 'EVEN':
        final v = _toNum(_evalArg(args, 0)).toDouble();
        final c = v >= 0 ? v.ceil() : v.floor();
        return c.isEven ? c : (v >= 0 ? c + 1 : c - 1);
      case 'ODD':
        final v = _toNum(_evalArg(args, 0)).toDouble();
        final c = v >= 0 ? v.ceil() : v.floor();
        return c.isOdd ? c : (v >= 0 ? c + 1 : c - 1);
      case 'MROUND':
        final v = _toNum(_evalArg(args, 0)).toDouble();
        final m = _toNum(_evalArg(args, 1)).toDouble();
        if (m == 0) return 0;
        return (v / m).round() * m;
      case 'QUOTIENT':
        final n = _toNum(_evalArg(args, 0));
        final d = _toNum(_evalArg(args, 1));
        if (d == 0) throw const FormulaError('!DIV/0');
        return (n / d).truncate();
      case 'SQRTPI':
        final v = _toNum(_evalArg(args, 0)).toDouble();
        if (v < 0) throw const FormulaError('!NUM');
        return math.sqrt(v * math.pi);
      case 'MULTINOMIAL':
        final nums = _flattenNums(args).map((n) => n.toInt()).toList();
        final total = nums.fold<int>(0, (a, b) => a + b);
        int denom = 1;
        for (final n in nums) {
          denom *= _factorial(n);
        }
        return _factorial(total) ~/ denom;
      case 'SINH':
        final v = _toNum(_evalArg(args, 0)).toDouble();
        return (math.exp(v) - math.exp(-v)) / 2;
      case 'COSH':
        final v = _toNum(_evalArg(args, 0)).toDouble();
        return (math.exp(v) + math.exp(-v)) / 2;
      case 'TANH':
        final v = _toNum(_evalArg(args, 0)).toDouble();
        final ev = math.exp(v);
        final emv = math.exp(-v);
        return (ev - emv) / (ev + emv);

      // ── 통계 (32) ──────────────────────────────────────────
      case 'SUM':
        final nums = _flattenNums(args);
        return nums.isEmpty ? 0 : nums.fold<num>(0, (a, b) => a + b);
      case 'AVERAGE':
        final nums = _flattenNums(args);
        if (nums.isEmpty) throw const FormulaError('!DIV/0');
        return nums.fold<num>(0, (a, b) => a + b) / nums.length;
      case 'MIN':
        final nums = _flattenNums(args);
        return nums.isEmpty ? 0 : nums.reduce(math.min);
      case 'MAX':
        final nums = _flattenNums(args);
        return nums.isEmpty ? 0 : nums.reduce(math.max);
      case 'COUNT':
        final all = _flattenAll(args);
        return all.where((v) => v != null && _tryNum(v) != null).length;
      case 'COUNTA':
        final all = _flattenAll(args);
        return all.where((v) => v != null && v.toString().isNotEmpty).length;
      case 'COUNTBLANK':
        final all = _flattenAll(args);
        return all.where((v) => v == null || v.toString().isEmpty).length;
      case 'COUNTIF':
        return _countif(args);
      case 'SUMIF':
        return _sumif(args);
      case 'AVERAGEIF':
        final sum = _sumif(args);
        final cnt = _countif(args);
        if (cnt == 0) throw const FormulaError('!DIV/0');
        return sum / cnt;
      case 'MEDIAN':
        final nums = _flattenNums(args);
        if (nums.isEmpty) throw const FormulaError('!NUM');
        nums.sort();
        final mid = nums.length ~/ 2;
        return nums.length.isOdd ? nums[mid] : (nums[mid - 1] + nums[mid]) / 2;
      case 'LARGE':
        final nums = _flattenNums([args[0]]);
        final k = _toNum(_evalArg(args, 1)).toInt();
        if (k < 1 || k > nums.length) throw const FormulaError('!NUM');
        nums.sort((a, b) => b.compareTo(a));
        return nums[k - 1];
      case 'SMALL':
        final nums = _flattenNums([args[0]]);
        final k = _toNum(_evalArg(args, 1)).toInt();
        if (k < 1 || k > nums.length) throw const FormulaError('!NUM');
        nums.sort();
        return nums[k - 1];
      // ── 통계 (신규 19) ─────────────────────────────────────
      case 'SUMPRODUCT':
        return _sumproduct(args);
      case 'COUNTIFS':
        return _countifs(args);
      case 'SUMIFS':
        return _sumifs(args);
      case 'AVERAGEIFS':
        final sArgs = [args[0], ...args.skip(1)];
        final sSum = _sumifs(sArgs);
        final cArgs = args.skip(1).toList();
        final cCnt = _countifs(cArgs);
        if (cCnt == 0) throw const FormulaError('!DIV/0');
        return sSum / cCnt;
      case 'MAXIFS':
        return _condExtreme(args, true);
      case 'MINIFS':
        return _condExtreme(args, false);
      case 'STDEV':
        final nums = _flattenNums(args);
        if (nums.length < 2) throw const FormulaError('!DIV/0');
        final avg = nums.fold<num>(0, (a, b) => a + b) / nums.length;
        final variance = nums.fold<num>(0, (a, b) => a + (b - avg) * (b - avg)) / (nums.length - 1);
        return math.sqrt(variance.toDouble());
      case 'STDEVP':
        final nums = _flattenNums(args);
        if (nums.isEmpty) throw const FormulaError('!DIV/0');
        final avg = nums.fold<num>(0, (a, b) => a + b) / nums.length;
        final variance = nums.fold<num>(0, (a, b) => a + (b - avg) * (b - avg)) / nums.length;
        return math.sqrt(variance.toDouble());
      case 'VAR':
        final nums = _flattenNums(args);
        if (nums.length < 2) throw const FormulaError('!DIV/0');
        final avg = nums.fold<num>(0, (a, b) => a + b) / nums.length;
        return nums.fold<num>(0, (a, b) => a + (b - avg) * (b - avg)) / (nums.length - 1);
      case 'VARP':
        final nums = _flattenNums(args);
        if (nums.isEmpty) throw const FormulaError('!DIV/0');
        final avg = nums.fold<num>(0, (a, b) => a + b) / nums.length;
        return nums.fold<num>(0, (a, b) => a + (b - avg) * (b - avg)) / nums.length;
      case 'CORREL':
        return _correl(args);
      case 'RANK':
        return _rank(args);
      case 'PERCENTILE':
        final nums = _flattenNums([args[0]]);
        final k = _toNum(_evalArg(args, 1)).toDouble();
        if (k < 0 || k > 1 || nums.isEmpty) throw const FormulaError('!NUM');
        nums.sort();
        final index = k * (nums.length - 1);
        final lower = index.floor();
        final upper = index.ceil();
        if (lower == upper) return nums[lower];
        return nums[lower] + (nums[upper] - nums[lower]) * (index - lower);
      case 'QUARTILE':
        final nums = _flattenNums([args[0]]);
        final q = _toNum(_evalArg(args, 1)).toInt();
        if (q < 0 || q > 4 || nums.isEmpty) throw const FormulaError('!NUM');
        nums.sort();
        final qk = q / 4.0;
        final qIndex = qk * (nums.length - 1);
        final qLower = qIndex.floor();
        final qUpper = qIndex.ceil();
        if (qLower == qUpper) return nums[qLower];
        return nums[qLower] + (nums[qUpper] - nums[qLower]) * (qIndex - qLower);
      case 'MODE':
        final nums = _flattenNums(args);
        if (nums.isEmpty) throw const FormulaError('!N/A');
        final freq = <num, int>{};
        for (final n in nums) {
          freq[n] = (freq[n] ?? 0) + 1;
        }
        final maxFreq = freq.values.reduce(math.max);
        if (maxFreq == 1) throw const FormulaError('!N/A');
        return freq.entries.firstWhere((e) => e.value == maxFreq).key;
      case 'AVEDEV':
        final nums = _flattenNums(args);
        if (nums.isEmpty) throw const FormulaError('!NUM');
        final avg = nums.fold<num>(0, (a, b) => a + b) / nums.length;
        return nums.fold<num>(0, (a, b) => a + (b - avg).abs()) / nums.length;
      case 'FORECAST':
        return _forecast(args);
      case 'SLOPE':
        return _slope(args);
      case 'INTERCEPT':
        return _intercept(args);
      case 'GEOMEAN':
        final nums = _flattenNums(args);
        if (nums.isEmpty) throw const FormulaError('!NUM');
        for (final n in nums) {
          if (n <= 0) throw const FormulaError('!NUM');
        }
        final logSum = nums.fold<double>(0, (a, b) => a + math.log(b.toDouble()));
        return math.exp(logSum / nums.length);
      case 'HARMEAN':
        final nums = _flattenNums(args);
        if (nums.isEmpty) throw const FormulaError('!NUM');
        for (final n in nums) {
          if (n <= 0) throw const FormulaError('!NUM');
        }
        final recipSum = nums.fold<double>(0, (a, b) => a + 1.0 / b.toDouble());
        return nums.length / recipSum;

      // ── 텍스트 (22) ────────────────────────────────────────
      case 'LEFT':
        final s = _toStr(_evalArg(args, 0));
        final n = args.length > 1 ? _toNum(_evalArg(args, 1)).toInt() : 1;
        return s.length >= n ? s.substring(0, n) : s;
      case 'RIGHT':
        final s = _toStr(_evalArg(args, 0));
        final n = args.length > 1 ? _toNum(_evalArg(args, 1)).toInt() : 1;
        return s.length >= n ? s.substring(s.length - n) : s;
      case 'MID':
        final s = _toStr(_evalArg(args, 0));
        final start = _toNum(_evalArg(args, 1)).toInt() - 1;
        final len = _toNum(_evalArg(args, 2)).toInt();
        if (start < 0 || start >= s.length) return '';
        final end = (start + len).clamp(0, s.length);
        return s.substring(start, end);
      case 'LEN':
        return _toStr(_evalArg(args, 0)).length;
      case 'UPPER':
        return _toStr(_evalArg(args, 0)).toUpperCase();
      case 'LOWER':
        return _toStr(_evalArg(args, 0)).toLowerCase();
      case 'TRIM':
        return _toStr(_evalArg(args, 0)).trim().replaceAll(RegExp(r'\s+'), ' ');
      case 'CONCATENATE':
      case 'CONCAT':
        return args.map((a) => _toStr(a is _CellRange ? _expandRange(a).join('') : _evalDynamic(a))).join('');
      case 'SUBSTITUTE':
        final s = _toStr(_evalArg(args, 0));
        final old = _toStr(_evalArg(args, 1));
        final rep = _toStr(_evalArg(args, 2));
        if (args.length > 3) {
          final n = _toNum(_evalArg(args, 3)).toInt();
          int count = 0;
          return s.replaceAllMapped(old, (m) {
            count++;
            return count == n ? rep : m[0]!;
          });
        }
        return s.replaceAll(old, rep);
      case 'REPT':
        final s = _toStr(_evalArg(args, 0));
        final n = _toNum(_evalArg(args, 1)).toInt();
        if (n < 0) throw const FormulaError('!VALUE');
        return s * n;
      case 'TEXT':
        final v = _toNum(_evalArg(args, 0));
        final fmt = _toStr(_evalArg(args, 1));
        return _textFormat(v, fmt);
      case 'VALUE':
        final s = _toStr(_evalArg(args, 0)).replaceAll(',', '');
        final n = num.tryParse(s);
        if (n == null) throw const FormulaError('!VALUE');
        return n;
      case 'FIND':
      case 'SEARCH':
        final needle = _toStr(_evalArg(args, 0));
        final haystack = _toStr(_evalArg(args, 1));
        final start = args.length > 2 ? _toNum(_evalArg(args, 2)).toInt() - 1 : 0;
        final idx = name == 'FIND'
            ? haystack.indexOf(needle, start)
            : haystack.toLowerCase().indexOf(needle.toLowerCase(), start);
        if (idx < 0) throw const FormulaError('!VALUE');
        return idx + 1;
      case 'EXACT':
        return _toStr(_evalArg(args, 0)) == _toStr(_evalArg(args, 1));
      // ── 텍스트 (신규 11) ───────────────────────────────────
      case 'TEXTJOIN':
        final delimiter = _toStr(_evalArg(args, 0));
        final ignoreEmpty = _toBool(_evalArg(args, 1));
        final texts = <String>[];
        for (int i = 2; i < args.length; i++) {
          if (args[i] is _CellRange) {
            for (final v in _expandRange(args[i] as _CellRange)) {
              final sv = _toStr(v);
              if (!ignoreEmpty || sv.isNotEmpty) texts.add(sv);
            }
          } else {
            final sv = _toStr(_evalDynamic(args[i]));
            if (!ignoreEmpty || sv.isNotEmpty) texts.add(sv);
          }
        }
        return texts.join(delimiter);
      case 'NUMBERVALUE':
        final s = _toStr(_evalArg(args, 0));
        final decimal = args.length > 1 ? _toStr(_evalArg(args, 1)) : '.';
        final group = args.length > 2 ? _toStr(_evalArg(args, 2)) : ',';
        final cleaned = s.replaceAll(group, '').replaceAll(decimal, '.');
        final nv = num.tryParse(cleaned);
        if (nv == null) throw const FormulaError('!VALUE');
        return nv;
      case 'PROPER':
        final s = _toStr(_evalArg(args, 0));
        return s.splitMapJoin(
          RegExp(r'\b\w'),
          onMatch: (m) => m[0]!.toUpperCase(),
          onNonMatch: (s) => s.toLowerCase(),
        );
      case 'CLEAN':
        return _toStr(_evalArg(args, 0)).replaceAll(RegExp(r'[\x00-\x1F]'), '');
      case 'CHAR':
        final code = _toNum(_evalArg(args, 0)).toInt();
        if (code < 1 || code > 65535) throw const FormulaError('!VALUE');
        return String.fromCharCode(code);
      case 'CODE':
        final s = _toStr(_evalArg(args, 0));
        if (s.isEmpty) throw const FormulaError('!VALUE');
        return s.codeUnitAt(0);
      case 'UNICHAR':
        final code = _toNum(_evalArg(args, 0)).toInt();
        if (code < 0 || code > 1114111) throw const FormulaError('!VALUE');
        return String.fromCharCode(code);
      case 'UNICODE':
        final s = _toStr(_evalArg(args, 0));
        if (s.isEmpty) throw const FormulaError('!VALUE');
        return s.codeUnitAt(0);
      case 'REPLACE':
        final s = _toStr(_evalArg(args, 0));
        final rStart = _toNum(_evalArg(args, 1)).toInt() - 1;
        final rCount = _toNum(_evalArg(args, 2)).toInt();
        final rep = _toStr(_evalArg(args, 3));
        if (rStart < 0) throw const FormulaError('!VALUE');
        final rEnd = (rStart + rCount).clamp(0, s.length);
        return s.substring(0, rStart) + rep + s.substring(rEnd);
      case 'FIXED':
        final v = _toNum(_evalArg(args, 0)).toDouble();
        final d = args.length > 1 ? _toNum(_evalArg(args, 1)).toInt() : 2;
        final noCommas = args.length > 2 ? _toBool(_evalArg(args, 2)) : false;
        var result = v.toStringAsFixed(d);
        if (!noCommas) {
          final parts = result.split('.');
          parts[0] = parts[0].replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+$)'),
            (m) => '${m[1]},',
          );
          result = parts.join('.');
        }
        return result;
      case 'DOLLAR':
        final v = _toNum(_evalArg(args, 0)).toDouble();
        final d = args.length > 1 ? _toNum(_evalArg(args, 1)).toInt() : 2;
        final formatted = v.toStringAsFixed(d);
        final dollarParts = formatted.split('.');
        dollarParts[0] = dollarParts[0].replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]},',
        );
        return '\$${dollarParts.join('.')}';

      // ── 논리 (8) ───────────────────────────────────────────
      case 'IF':
        final cond = _toBool(_evalArg(args, 0));
        if (cond) return args.length > 1 ? _evalArg(args, 1) : true;
        return args.length > 2 ? _evalArg(args, 2) : false;
      case 'AND':
        for (final a in args) {
          if (a is _CellRange) {
            for (final v in _expandRange(a)) {
              if (!_toBool(v)) return false;
            }
          } else {
            if (!_toBool(_evalDynamic(a))) return false;
          }
        }
        return true;
      case 'OR':
        for (final a in args) {
          if (a is _CellRange) {
            for (final v in _expandRange(a)) {
              if (_toBool(v)) return true;
            }
          } else {
            if (_toBool(_evalDynamic(a))) return true;
          }
        }
        return false;
      case 'NOT':
        return !_toBool(_evalArg(args, 0));
      case 'IFERROR':
        try {
          return _evalArg(args, 0);
        } catch (_) { // Excel IFERROR: intentionally catches all formula errors
          return args.length > 1 ? _evalArg(args, 1) : '';
        }
      case 'IFS':
        for (int i = 0; i < args.length - 1; i += 2) {
          if (_toBool(_evalArg(args, i))) return _evalArg(args, i + 1);
        }
        throw const FormulaError('!N/A');
      // ── 논리 (신규 2) ──────────────────────────────────────
      case 'XOR':
        int trueCount = 0;
        for (final a in args) {
          if (a is _CellRange) {
            for (final v in _expandRange(a)) {
              if (_toBool(v)) trueCount++;
            }
          } else {
            if (_toBool(_evalDynamic(a))) trueCount++;
          }
        }
        return trueCount.isOdd;
      case 'IFNA':
        try {
          final result = _evalArg(args, 0);
          return result;
        } catch (e) {
          if (e is FormulaError && e.message == '!N/A') {
            return args.length > 1 ? _evalArg(args, 1) : '';
          }
          rethrow;
        }

      // ── 날짜 (14) ──────────────────────────────────────────
      case 'TODAY':
        final now = DateTime.now();
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      case 'NOW':
        final now = DateTime.now();
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      case 'YEAR':
        final yDate = _parseDate(_evalArg(args, 0));
        if (yDate == null) throw const FormulaError('!VALUE');
        return yDate.year;
      case 'MONTH':
        final mDate = _parseDate(_evalArg(args, 0));
        if (mDate == null) throw const FormulaError('!VALUE');
        return mDate.month;
      case 'DAY':
        final dDate = _parseDate(_evalArg(args, 0));
        if (dDate == null) throw const FormulaError('!VALUE');
        return dDate.day;
      case 'DATE':
        final y = _toNum(_evalArg(args, 0)).toInt();
        final m = _toNum(_evalArg(args, 1)).toInt();
        final d = _toNum(_evalArg(args, 2)).toInt();
        return '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      // ── 날짜 (신규 8) ──────────────────────────────────────
      case 'HOUR':
        final s = _toStr(_evalArg(args, 0));
        final timeParts = s.contains(' ') ? s.split(' ').last.split(':') : s.split(':');
        if (timeParts.isEmpty) throw const FormulaError('!VALUE');
        return int.tryParse(timeParts[0]) ?? 0;
      case 'MINUTE':
        final s = _toStr(_evalArg(args, 0));
        final timeParts = s.contains(' ') ? s.split(' ').last.split(':') : s.split(':');
        if (timeParts.length < 2) throw const FormulaError('!VALUE');
        return int.tryParse(timeParts[1]) ?? 0;
      case 'SECOND':
        final s = _toStr(_evalArg(args, 0));
        final timeParts = s.contains(' ') ? s.split(' ').last.split(':') : s.split(':');
        if (timeParts.length < 3) return 0;
        return int.tryParse(timeParts[2]) ?? 0;
      case 'DATEDIF':
        final startDate = _parseDate(_evalArg(args, 0));
        final endDate = _parseDate(_evalArg(args, 1));
        final unit = _toStr(_evalArg(args, 2)).toUpperCase();
        if (startDate == null || endDate == null) throw const FormulaError('!VALUE');
        switch (unit) {
          case 'Y':
            return endDate.year - startDate.year - (endDate.month < startDate.month || (endDate.month == startDate.month && endDate.day < startDate.day) ? 1 : 0);
          case 'M':
            return (endDate.year - startDate.year) * 12 + endDate.month - startDate.month - (endDate.day < startDate.day ? 1 : 0);
          case 'D':
            return endDate.difference(startDate).inDays;
          default:
            throw const FormulaError('!VALUE');
        }
      case 'EDATE':
        final baseDate = _parseDate(_evalArg(args, 0));
        if (baseDate == null) throw const FormulaError('!VALUE');
        final months = _toNum(_evalArg(args, 1)).toInt();
        final result = DateTime(baseDate.year, baseDate.month + months, baseDate.day);
        return '${result.year}-${result.month.toString().padLeft(2, '0')}-${result.day.toString().padLeft(2, '0')}';
      case 'EOMONTH':
        final baseDate = _parseDate(_evalArg(args, 0));
        if (baseDate == null) throw const FormulaError('!VALUE');
        final months = _toNum(_evalArg(args, 1)).toInt();
        final target = DateTime(baseDate.year, baseDate.month + months + 1, 0);
        return '${target.year}-${target.month.toString().padLeft(2, '0')}-${target.day.toString().padLeft(2, '0')}';
      case 'WEEKDAY':
        final wDate = _parseDate(_evalArg(args, 0));
        if (wDate == null) throw const FormulaError('!VALUE');
        final returnType = args.length > 1 ? _toNum(_evalArg(args, 1)).toInt() : 1;
        final dow = wDate.weekday; // 1=Mon, 7=Sun
        if (returnType == 1) return dow == 7 ? 1 : dow + 1; // 1=Sun, 7=Sat
        if (returnType == 2) return dow; // 1=Mon, 7=Sun
        return dow == 7 ? 0 : dow; // 0=Sun, 6=Sat
      case 'NETWORKDAYS':
        final startDate = _parseDate(_evalArg(args, 0));
        final endDate = _parseDate(_evalArg(args, 1));
        if (startDate == null || endDate == null) throw const FormulaError('!VALUE');
        int count = 0;
        var current = startDate;
        final step = endDate.isAfter(startDate) ? 1 : -1;
        while (step > 0 ? !current.isAfter(endDate) : !current.isBefore(endDate)) {
          if (current.weekday <= 5) count++;
          current = current.add(Duration(days: step));
        }
        return count;
      case 'DATEVALUE':
        final dvDate = _parseDate(_evalArg(args, 0));
        if (dvDate == null) throw const FormulaError('!VALUE');
        return dvDate.difference(DateTime(1899, 12, 30)).inDays;

      // ── 찾기/참조 (15) ─────────────────────────────────────
      case 'VLOOKUP':
        return _vlookup(args);
      case 'INDEX':
        return _index(args);
      case 'MATCH':
        return _match(args);
      case 'HLOOKUP':
        return _hlookup(args);
      // ── 찾기/참조 (신규 11) ────────────────────────────────
      case 'CHOOSE':
        final idx = _toNum(_evalArg(args, 0)).toInt();
        if (idx < 1 || idx >= args.length) throw const FormulaError('!VALUE');
        return _evalArg(args, idx);
      case 'SWITCH':
        final expr = _evalArg(args, 0);
        for (int i = 1; i < args.length - 1; i += 2) {
          if (_isEqual(expr, _evalArg(args, i))) return _evalArg(args, i + 1);
        }
        if (args.length.isEven) return _evalArg(args, args.length - 1);
        throw const FormulaError('!N/A');
      case 'XLOOKUP':
        return _xlookup(args);
      case 'XMATCH':
        return _xmatch(args);
      case 'ROW':
        if (args.isEmpty) return 1;
        if (args[0] is _CellRange) {
          final s = engine.parseCellRef((args[0] as _CellRange).start);
          if (s == null) throw const FormulaError('!REF');
          return s.$1 + 1;
        }
        return 1;
      case 'COLUMN':
        if (args.isEmpty) return 1;
        if (args[0] is _CellRange) {
          final s = engine.parseCellRef((args[0] as _CellRange).start);
          if (s == null) throw const FormulaError('!REF');
          return s.$2 + 1;
        }
        return 1;
      case 'ROWS':
        if (args.isEmpty) throw const FormulaError('!VALUE');
        if (args[0] is _CellRange) {
          final s = engine.parseCellRef((args[0] as _CellRange).start);
          final e = engine.parseCellRef((args[0] as _CellRange).end);
          if (s == null || e == null) throw const FormulaError('!REF');
          return e.$1 - s.$1 + 1;
        }
        return 1;
      case 'COLUMNS':
        if (args.isEmpty) throw const FormulaError('!VALUE');
        if (args[0] is _CellRange) {
          final s = engine.parseCellRef((args[0] as _CellRange).start);
          final e = engine.parseCellRef((args[0] as _CellRange).end);
          if (s == null || e == null) throw const FormulaError('!REF');
          return e.$2 - s.$2 + 1;
        }
        return 1;
      case 'ADDRESS':
        final row = _toNum(_evalArg(args, 0)).toInt();
        final col = _toNum(_evalArg(args, 1)).toInt();
        final absType = args.length > 2 ? _toNum(_evalArg(args, 2)).toInt() : 1;
        String colLetter = '';
        int cc = col;
        while (cc > 0) {
          cc--;
          colLetter = String.fromCharCode(65 + cc % 26) + colLetter;
          cc ~/= 26;
        }
        switch (absType) {
          case 1:
            return '\$$colLetter\$$row';
          case 2:
            return '$colLetter\$$row';
          case 3:
            return '\$$colLetter$row';
          default:
            return '$colLetter$row';
        }
      case 'INDIRECT':
        final ref = _toStr(_evalArg(args, 0)).replaceAll('\$', '');
        final parsed = engine.parseCellRef(ref);
        if (parsed == null) throw const FormulaError('!REF');
        return _resolveCellValue(ref);
      case 'OFFSET':
        return _offset(args);

      // ── 정보 (12) ──────────────────────────────────────────
      case 'ISNUMBER':
        try {
          final v = _evalArg(args, 0);
          return v is num || (v is String && num.tryParse(v) != null);
        } catch (_) { // Excel IS*: error means false per spec
          return false;
        }
      case 'ISBLANK':
        try {
          final v = _evalArg(args, 0);
          return v == null || (v is String && v.isEmpty) || v == 0;
        } catch (_) { // Excel ISBLANK: error treated as blank
          return true;
        }
      case 'ISTEXT':
        try {
          final v = _evalArg(args, 0);
          return v is String && num.tryParse(v) == null;
        } catch (_) { // Excel ISTEXT: error means not text
          return false;
        }
      case 'ISERROR':
        try {
          _evalArg(args, 0);
          return false;
        } catch (_) { // Excel ISERROR: intentionally catches to return true
          return true;
        }
      case 'TYPE':
        try {
          final v = _evalArg(args, 0);
          if (v is num) return 1;
          if (v is String) return 2;
          if (v is bool) return 4;
          return 1;
        } catch (_) { // Excel TYPE: error type = 16
          return 16;
        }
      // ── 정보 (신규 7) ──────────────────────────────────────
      case 'ISODD':
        return _toNum(_evalArg(args, 0)).toInt().isOdd;
      case 'ISEVEN':
        return _toNum(_evalArg(args, 0)).toInt().isEven;
      case 'ISLOGICAL':
        try {
          final v = _evalArg(args, 0);
          return v is bool;
        } catch (_) { // Excel ISLOGICAL: error means not logical
          return false;
        }
      case 'ISNONTEXT':
        try {
          final v = _evalArg(args, 0);
          return v is! String || num.tryParse(v) != null;
        } catch (_) { // Excel ISNONTEXT: error means non-text
          return true;
        }
      case 'ISNA':
        try {
          _evalArg(args, 0);
          return false;
        } catch (e) {
          return e is FormulaError && e.message == '!N/A';
        }
      case 'N':
        try {
          final v = _evalArg(args, 0);
          if (v is num) return v;
          if (v is bool) return v ? 1 : 0;
          return 0;
        } catch (_) { // Excel N: error returns 0
          return 0;
        }
      case 'T':
        try {
          final v = _evalArg(args, 0);
          return v is String ? v : '';
        } catch (_) { // Excel T: error returns empty string
          return '';
        }
      case 'NA':
        throw const FormulaError('!N/A');

      default:
        throw const FormulaError('!NAME');
    }
  }

  // ─── Helper: Evaluate argument ─────────────────────────

  dynamic _evalArg(List<dynamic> args, int index) {
    if (index >= args.length) throw const FormulaError('!ERR');
    return _evalDynamic(args[index]);
  }

  dynamic _evalDynamic(dynamic val) {
    if (val is _CellRange) {
      // 단일 셀 범위 → 값 반환, 다중 → 첫 번째 값
      final expanded = _expandRange(val);
      return expanded.isNotEmpty ? expanded.first : null;
    }
    return val;
  }

  // ─── Type Coercion ─────────────────────────────────────

  num _toNum(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val;
    if (val is bool) return val ? 1 : 0;
    if (val is String) {
      if (val.isEmpty) return 0;
      final n = num.tryParse(val);
      if (n != null) return n;
      throw const FormulaError('!VALUE');
    }
    return 0;
  }

  String _toStr(dynamic val) {
    if (val == null) return '';
    if (val is num) {
      if (val == val.toInt()) return val.toInt().toString();
      return val.toString();
    }
    if (val is bool) return val ? 'TRUE' : 'FALSE';
    return val.toString();
  }

  bool _toBool(dynamic val) {
    if (val == null) return false;
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) {
      if (val.toUpperCase() == 'TRUE') return true;
      if (val.toUpperCase() == 'FALSE') return false;
      return val.isNotEmpty;
    }
    return false;
  }

  num? _tryNum(dynamic val) {
    if (val is num) return val;
    if (val is String) return num.tryParse(val);
    return null;
  }

  bool _compare(dynamic left, dynamic right, String op) {
    // 숫자 비교
    final ln = _tryNum(left);
    final rn = _tryNum(right);
    if (ln != null && rn != null) {
      switch (op) {
        case '>':  return ln > rn;
        case '<':  return ln < rn;
        case '>=': return ln >= rn;
        case '<=': return ln <= rn;
        case '=':  return ln == rn;
        case '<>': return ln != rn;
      }
    }
    // 문자열 비교
    final ls = _toStr(left).toUpperCase();
    final rs = _toStr(right).toUpperCase();
    switch (op) {
      case '>':  return ls.compareTo(rs) > 0;
      case '<':  return ls.compareTo(rs) < 0;
      case '>=': return ls.compareTo(rs) >= 0;
      case '<=': return ls.compareTo(rs) <= 0;
      case '=':  return ls == rs;
      case '<>': return ls != rs;
    }
    return false;
  }

  // ─── Math Helpers ─────────────────────────────────────

  int _factorial(int n) {
    if (n <= 1) return 1;
    int result = 1;
    for (int i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }

  int _gcd(int a, int b) {
    a = a.abs();
    b = b.abs();
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

  // ─── COUNTIF / SUMIF ──────────────────────────────────

  bool _matchCriteria(dynamic value, String criteria) {
    final c = criteria.trim();
    // 비교 연산자가 포함된 경우
    if (c.startsWith('>=') || c.startsWith('<=') || c.startsWith('<>') || c.startsWith('>') || c.startsWith('<') || c.startsWith('=')) {
      String op;
      String val;
      if (c.startsWith('>=')) {
        op = '>=';
        val = c.substring(2);
      } else if (c.startsWith('<=')) {
        op = '<=';
        val = c.substring(2);
      } else if (c.startsWith('<>')) {
        op = '<>';
        val = c.substring(2);
      } else if (c.startsWith('>')) {
        op = '>';
        val = c.substring(1);
      } else if (c.startsWith('<')) {
        op = '<';
        val = c.substring(1);
      } else {
        op = '=';
        val = c.substring(1);
      }
      final numVal = num.tryParse(val);
      if (numVal != null) {
        final numCell = _tryNum(value);
        if (numCell == null) return false;
        return _compare(numCell, numVal, op);
      }
      return _compare(value, val, op);
    }
    // 와일드카드 (* ?)
    if (c.contains('*') || c.contains('?')) {
      final pattern = c.replaceAll('*', '.*').replaceAll('?', '.');
      return RegExp('^$pattern\$', caseSensitive: false).hasMatch(_toStr(value));
    }
    // 숫자 비교
    final numCrit = num.tryParse(c);
    if (numCrit != null) {
      final numVal = _tryNum(value);
      return numVal != null && numVal == numCrit;
    }
    // 문자열 일치 (대소문자 무시)
    return _toStr(value).toUpperCase() == c.toUpperCase();
  }

  int _countif(List<dynamic> args) {
    final range = args[0];
    final criteria = _toStr(_evalArg(args, 1));
    final values = range is _CellRange ? _expandRange(range) : [_evalDynamic(range)];
    return values.where((v) => v != null && _matchCriteria(v, criteria)).length;
  }

  num _sumif(List<dynamic> args) {
    final range = args[0];
    final criteria = _toStr(_evalArg(args, 1));
    final sumRange = args.length > 2 ? args[2] : args[0];

    final values = range is _CellRange ? _expandRange(range) : [_evalDynamic(range)];
    final sumValues = sumRange is _CellRange ? _expandRange(sumRange) : [_evalDynamic(sumRange)];

    num total = 0;
    for (int i = 0; i < values.length; i++) {
      if (values[i] != null && _matchCriteria(values[i], criteria)) {
        if (i < sumValues.length) {
          final n = _tryNum(sumValues[i]);
          if (n != null) total += n;
        }
      }
    }
    return total;
  }

  // ─── COUNTIFS / SUMIFS / AVERAGEIFS (Multi-criteria) ──

  /// COUNTIFS: 다중 조건 카운트
  int _countifs(List<dynamic> args) {
    if (args.length < 2 || args.length.isOdd) throw const FormulaError('!VALUE');

    final pairs = <(List<dynamic>, String)>[];
    for (int i = 0; i < args.length; i += 2) {
      final range = args[i];
      final criteria = _toStr(_evalArg(args, i + 1));
      final values = range is _CellRange ? _expandRange(range) : [_evalDynamic(range)];
      pairs.add((values, criteria));
    }

    final length = pairs[0].$1.length;
    int count = 0;
    for (int i = 0; i < length; i++) {
      bool allMatch = true;
      for (final pair in pairs) {
        if (i >= pair.$1.length || pair.$1[i] == null || !_matchCriteria(pair.$1[i], pair.$2)) {
          allMatch = false;
          break;
        }
      }
      if (allMatch) count++;
    }
    return count;
  }

  /// SUMIFS: 다중 조건 합계
  num _sumifs(List<dynamic> args) {
    if (args.length < 3 || args.length.isEven) throw const FormulaError('!VALUE');

    final sumRange = args[0];
    final sumValues = sumRange is _CellRange ? _expandRange(sumRange) : [_evalDynamic(sumRange)];

    final pairs = <(List<dynamic>, String)>[];
    for (int i = 1; i < args.length; i += 2) {
      final range = args[i];
      final criteria = _toStr(_evalArg(args, i + 1));
      final values = range is _CellRange ? _expandRange(range) : [_evalDynamic(range)];
      pairs.add((values, criteria));
    }

    num total = 0;
    for (int i = 0; i < sumValues.length; i++) {
      bool allMatch = true;
      for (final pair in pairs) {
        if (i >= pair.$1.length || pair.$1[i] == null || !_matchCriteria(pair.$1[i], pair.$2)) {
          allMatch = false;
          break;
        }
      }
      if (allMatch) {
        final n = _tryNum(sumValues[i]);
        if (n != null) total += n;
      }
    }
    return total;
  }

  /// MAXIFS/MINIFS: 조건부 최대/최소
  num _condExtreme(List<dynamic> args, bool isMax) {
    if (args.length < 3 || args.length.isEven) throw const FormulaError('!VALUE');

    final targetRange = args[0];
    final targetValues = targetRange is _CellRange ? _expandRange(targetRange) : [_evalDynamic(targetRange)];

    final pairs = <(List<dynamic>, String)>[];
    for (int i = 1; i < args.length; i += 2) {
      final range = args[i];
      final criteria = _toStr(_evalArg(args, i + 1));
      final values = range is _CellRange ? _expandRange(range) : [_evalDynamic(range)];
      pairs.add((values, criteria));
    }

    num? result;
    for (int i = 0; i < targetValues.length; i++) {
      bool allMatch = true;
      for (final pair in pairs) {
        if (i >= pair.$1.length || pair.$1[i] == null || !_matchCriteria(pair.$1[i], pair.$2)) {
          allMatch = false;
          break;
        }
      }
      if (allMatch) {
        final n = _tryNum(targetValues[i]);
        if (n != null) {
          if (result == null || (isMax ? n > result : n < result)) result = n;
        }
      }
    }
    return result ?? 0;
  }

  /// SUMPRODUCT: 배열 곱의 합
  num _sumproduct(List<dynamic> args) {
    if (args.isEmpty) throw const FormulaError('!VALUE');
    final ranges = <List<num>>[];
    for (final a in args) {
      if (a is _CellRange) {
        ranges.add(_expandRange(a).map((v) => (_tryNum(v) ?? 0).toDouble()).cast<num>().toList());
      } else {
        ranges.add([_toNum(_evalDynamic(a))]);
      }
    }
    final length = ranges[0].length;
    for (final r in ranges) {
      if (r.length != length) throw const FormulaError('!VALUE');
    }
    num total = 0;
    for (int i = 0; i < length; i++) {
      num product = 1;
      for (final r in ranges) {
        product *= r[i];
      }
      total += product;
    }
    return total;
  }

  // ─── Statistics Helpers ────────────────────────────────

  /// CORREL: 상관 계수
  num _correl(List<dynamic> args) {
    if (args.length < 2) throw const FormulaError('!VALUE');
    final xVals = _flattenNums([args[0]]);
    final yVals = _flattenNums([args[1]]);
    if (xVals.length != yVals.length || xVals.length < 2) throw const FormulaError('!N/A');

    final n = xVals.length;
    final xAvg = xVals.fold<num>(0, (a, b) => a + b) / n;
    final yAvg = yVals.fold<num>(0, (a, b) => a + b) / n;

    num sumXY = 0, sumX2 = 0, sumY2 = 0;
    for (int i = 0; i < n; i++) {
      final dx = xVals[i] - xAvg;
      final dy = yVals[i] - yAvg;
      sumXY += dx * dy;
      sumX2 += dx * dx;
      sumY2 += dy * dy;
    }
    if (sumX2 == 0 || sumY2 == 0) throw const FormulaError('!DIV/0');
    return sumXY / math.sqrt(sumX2.toDouble() * sumY2.toDouble());
  }

  /// RANK: 순위
  int _rank(List<dynamic> args) {
    final val = _toNum(_evalArg(args, 0));
    final nums = _flattenNums([args[1]]);
    final order = args.length > 2 ? _toNum(_evalArg(args, 2)).toInt() : 0;

    int rank = 1;
    for (final n in nums) {
      if (order == 0) {
        if (n > val) rank++;
      } else {
        if (n < val) rank++;
      }
    }
    return rank;
  }

  /// SLOPE: 기울기
  num _slope(List<dynamic> args) {
    final yVals = _flattenNums([args[0]]);
    final xVals = _flattenNums([args[1]]);
    if (xVals.length != yVals.length || xVals.length < 2) throw const FormulaError('!N/A');

    final n = xVals.length;
    final xAvg = xVals.fold<num>(0, (a, b) => a + b) / n;
    final yAvg = yVals.fold<num>(0, (a, b) => a + b) / n;

    num sumXY = 0, sumX2 = 0;
    for (int i = 0; i < n; i++) {
      sumXY += (xVals[i] - xAvg) * (yVals[i] - yAvg);
      sumX2 += (xVals[i] - xAvg) * (xVals[i] - xAvg);
    }
    if (sumX2 == 0) throw const FormulaError('!DIV/0');
    return sumXY / sumX2;
  }

  /// INTERCEPT: 절편
  num _intercept(List<dynamic> args) {
    final yVals = _flattenNums([args[0]]);
    final xVals = _flattenNums([args[1]]);
    if (xVals.length != yVals.length || xVals.length < 2) throw const FormulaError('!N/A');

    final n = xVals.length;
    final xAvg = xVals.fold<num>(0, (a, b) => a + b) / n;
    final yAvg = yVals.fold<num>(0, (a, b) => a + b) / n;

    num sumXY = 0, sumX2 = 0;
    for (int i = 0; i < n; i++) {
      sumXY += (xVals[i] - xAvg) * (yVals[i] - yAvg);
      sumX2 += (xVals[i] - xAvg) * (xVals[i] - xAvg);
    }
    if (sumX2 == 0) throw const FormulaError('!DIV/0');
    return yAvg - (sumXY / sumX2) * xAvg;
  }

  /// FORECAST: 예측
  num _forecast(List<dynamic> args) {
    final x = _toNum(_evalArg(args, 0));
    final yVals = _flattenNums([args[1]]);
    final xVals = _flattenNums([args[2]]);
    if (xVals.length != yVals.length || xVals.length < 2) throw const FormulaError('!N/A');

    final n = xVals.length;
    final xAvg = xVals.fold<num>(0, (a, b) => a + b) / n;
    final yAvg = yVals.fold<num>(0, (a, b) => a + b) / n;

    num sumXY = 0, sumX2 = 0;
    for (int i = 0; i < n; i++) {
      sumXY += (xVals[i] - xAvg) * (yVals[i] - yAvg);
      sumX2 += (xVals[i] - xAvg) * (xVals[i] - xAvg);
    }
    if (sumX2 == 0) throw const FormulaError('!DIV/0');
    final slope = sumXY / sumX2;
    final intercept = yAvg - slope * xAvg;
    return slope * x + intercept;
  }

  // ─── VLOOKUP / HLOOKUP / INDEX / MATCH ────────────────

  dynamic _vlookup(List<dynamic> args) {
    final lookupVal = _evalArg(args, 0);
    final range = args[1];
    if (range is! _CellRange) throw const FormulaError('!VALUE');
    final colIndex = _toNum(_evalArg(args, 2)).toInt();
    final exactMatch = args.length > 3 ? !_toBool(_evalArg(args, 3)) : false;

    final s = engine.parseCellRef(range.start);
    final e = engine.parseCellRef(range.end);
    if (s == null || e == null) throw const FormulaError('!REF');

    final numCols = e.$2 - s.$2 + 1;
    if (colIndex < 1 || colIndex > numCols) throw const FormulaError('!REF');

    for (int r = s.$1; r <= e.$1; r++) {
      final cellVal = _getCellParsed(r, s.$2);
      if (exactMatch) {
        if (_isEqual(cellVal, lookupVal)) {
          return _getCellParsed(r, s.$2 + colIndex - 1);
        }
      } else {
        // 근사 일치: 정렬된 데이터 가정, 가장 가까운 작은 값
        final n1 = _tryNum(cellVal);
        final n2 = _tryNum(lookupVal);
        if (n1 != null && n2 != null && n1 <= n2) {
          // 다음 행 값이 더 크거나 마지막 행이면 현재 행 반환
          if (r == e.$1) return _getCellParsed(r, s.$2 + colIndex - 1);
          final nextVal = _tryNum(_getCellParsed(r + 1, s.$2));
          if (nextVal == null || nextVal > n2) return _getCellParsed(r, s.$2 + colIndex - 1);
        }
      }
    }
    throw const FormulaError('!N/A');
  }

  dynamic _hlookup(List<dynamic> args) {
    final lookupVal = _evalArg(args, 0);
    final range = args[1];
    if (range is! _CellRange) throw const FormulaError('!VALUE');
    final rowIndex = _toNum(_evalArg(args, 2)).toInt();
    final exactMatch = args.length > 3 ? !_toBool(_evalArg(args, 3)) : false;

    final s = engine.parseCellRef(range.start);
    final e = engine.parseCellRef(range.end);
    if (s == null || e == null) throw const FormulaError('!REF');

    final numRows = e.$1 - s.$1 + 1;
    if (rowIndex < 1 || rowIndex > numRows) throw const FormulaError('!REF');

    for (int c = s.$2; c <= e.$2; c++) {
      final cellVal = _getCellParsed(s.$1, c);
      if (exactMatch || _isEqual(cellVal, lookupVal)) {
        if (_isEqual(cellVal, lookupVal)) {
          return _getCellParsed(s.$1 + rowIndex - 1, c);
        }
      }
    }
    throw const FormulaError('!N/A');
  }

  dynamic _index(List<dynamic> args) {
    final range = args[0];
    if (range is! _CellRange) throw const FormulaError('!VALUE');
    final rowNum = _toNum(_evalArg(args, 1)).toInt();
    final colNum = args.length > 2 ? _toNum(_evalArg(args, 2)).toInt() : 1;

    final s = engine.parseCellRef(range.start);
    final e = engine.parseCellRef(range.end);
    if (s == null || e == null) throw const FormulaError('!REF');

    final targetRow = s.$1 + rowNum - 1;
    final targetCol = s.$2 + colNum - 1;
    if (targetRow < s.$1 || targetRow > e.$1 || targetCol < s.$2 || targetCol > e.$2) {
      throw const FormulaError('!REF');
    }
    return _getCellParsed(targetRow, targetCol);
  }

  dynamic _match(List<dynamic> args) {
    final lookupVal = _evalArg(args, 0);
    final range = args[1];
    if (range is! _CellRange) throw const FormulaError('!VALUE');
    final matchType = args.length > 2 ? _toNum(_evalArg(args, 2)).toInt() : 1;

    final s = engine.parseCellRef(range.start);
    final e = engine.parseCellRef(range.end);
    if (s == null || e == null) throw const FormulaError('!REF');

    // 1행 또는 1열 범위
    final isRow = s.$1 == e.$1;
    final count = isRow ? (e.$2 - s.$2 + 1) : (e.$1 - s.$1 + 1);

    int? lastMatch;
    for (int i = 0; i < count; i++) {
      final r = isRow ? s.$1 : s.$1 + i;
      final c = isRow ? s.$2 + i : s.$2;
      final cellVal = _getCellParsed(r, c);

      if (matchType == 0) {
        // 정확 일치
        if (_isEqual(cellVal, lookupVal)) return i + 1;
      } else if (matchType == 1) {
        // 가장 큰 값 (오름차순 정렬 가정)
        final n1 = _tryNum(cellVal);
        final n2 = _tryNum(lookupVal);
        if (n1 != null && n2 != null && n1 <= n2) lastMatch = i + 1;
      } else {
        // 가장 작은 값 (내림차순 정렬 가정)
        final n1 = _tryNum(cellVal);
        final n2 = _tryNum(lookupVal);
        if (n1 != null && n2 != null && n1 >= n2) lastMatch = i + 1;
      }
    }
    if (matchType != 0 && lastMatch != null) return lastMatch;
    throw const FormulaError('!N/A');
  }

  // ─── XLOOKUP / XMATCH / OFFSET ────────────────────────

  /// XLOOKUP: 확장 조회
  dynamic _xlookup(List<dynamic> args) {
    final lookupVal = _evalArg(args, 0);
    final lookupRange = args[1];
    final returnRange = args[2];

    if (lookupRange is! _CellRange || returnRange is! _CellRange) {
      throw const FormulaError('!VALUE');
    }

    final lookupValues = _expandRange(lookupRange);
    final returnValues = _expandRange(returnRange);
    final ifNotFound = args.length > 3 ? args[3] : null;
    final matchMode = args.length > 4 ? _toNum(_evalArg(args, 4)).toInt() : 0;

    for (int i = 0; i < lookupValues.length; i++) {
      bool matches = false;
      if (matchMode == 0 || matchMode == -1 || matchMode == 1) {
        matches = _isEqual(lookupValues[i], lookupVal);
      } else if (matchMode == 2) {
        matches = _matchCriteria(lookupValues[i], _toStr(lookupVal));
      }
      if (matches && i < returnValues.length) return returnValues[i];
    }

    if (ifNotFound != null) return _evalDynamic(ifNotFound);
    throw const FormulaError('!N/A');
  }

  /// XMATCH: 확장 매치
  int _xmatch(List<dynamic> args) {
    final lookupVal = _evalArg(args, 0);
    final lookupRange = args[1];
    if (lookupRange is! _CellRange) throw const FormulaError('!VALUE');
    final matchMode = args.length > 2 ? _toNum(_evalArg(args, 2)).toInt() : 0;

    final lookupValues = _expandRange(lookupRange);

    for (int i = 0; i < lookupValues.length; i++) {
      bool matches = false;
      if (matchMode == 0) {
        matches = _isEqual(lookupValues[i], lookupVal);
      } else if (matchMode == 2) {
        matches = _matchCriteria(lookupValues[i], _toStr(lookupVal));
      }
      if (matches) return i + 1;
    }
    throw const FormulaError('!N/A');
  }

  /// OFFSET: 기준 셀에서 오프셋
  dynamic _offset(List<dynamic> args) {
    final baseRef = args[0];
    if (baseRef is! _CellRange) throw const FormulaError('!VALUE');

    final rowOffset = _toNum(_evalArg(args, 1)).toInt();
    final colOffset = _toNum(_evalArg(args, 2)).toInt();

    final s = engine.parseCellRef(baseRef.start);
    if (s == null) throw const FormulaError('!REF');

    final targetRow = s.$1 + rowOffset;
    final targetCol = s.$2 + colOffset;
    if (targetRow < 0 || targetCol < 0) throw const FormulaError('!REF');

    return _getCellParsed(targetRow, targetCol);
  }

  // ─── Cell Parse Helper ────────────────────────────────

  dynamic _getCellParsed(int row, int col) {
    final raw = engine.getCellValue(row, col);
    if (raw == null) return null;
    final s = raw.toString();
    if (s.isEmpty) return null;
    if (s.startsWith('=')) {
      final display = engine.getCellDisplay(row, col);
      final n = num.tryParse(display);
      return n ?? display;
    }
    final n = num.tryParse(s);
    return n ?? s;
  }

  bool _isEqual(dynamic a, dynamic b) {
    if (a == null && b == null) return true;
    final na = _tryNum(a);
    final nb = _tryNum(b);
    if (na != null && nb != null) return na == nb;
    return _toStr(a).toUpperCase() == _toStr(b).toUpperCase();
  }

  // ─── TEXT Format Helper ────────────────────────────────

  String _textFormat(num value, String format) {
    final f = format.toUpperCase();
    if (f.contains('0') || f.contains('#')) {
      // 소수점 자릿수
      final dotIndex = f.indexOf('.');
      if (dotIndex >= 0) {
        final decimals = f.length - dotIndex - 1;
        return value.toStringAsFixed(decimals);
      }
      return value.toStringAsFixed(0);
    }
    if (f.contains('%')) {
      final pct = value * 100;
      return '${pct.toStringAsFixed(f.contains('.') ? f.split('.').last.length - 1 : 0)}%';
    }
    return value.toString();
  }

  DateTime? _parseDate(dynamic val) {
    if (val is String) return DateTime.tryParse(val);
    if (val is num) {
      // Excel serial number (approx)
      return DateTime(1899, 12, 30).add(Duration(days: val.toInt()));
    }
    return null;
  }
}

/// 범위 참조를 나타내는 내부 클래스
class _CellRange {
  final String start;
  final String end;
  const _CellRange(this.start, this.end);
}

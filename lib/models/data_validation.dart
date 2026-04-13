// 데이터 검증 규칙 모델

enum ValidationType { list, wholeNumber, decimal, date, textLength, custom }

enum ValidationOperator {
  between,
  notBetween,
  equalTo,
  notEqualTo,
  greaterThan,
  lessThan,
  greaterOrEqual,
  lessOrEqual,
}

class DataValidation {
  final String id;
  final ValidationType type;
  final ValidationOperator operator;
  final String value1;
  final String value2;
  final List<String>? listItems;
  final bool showDropdown;
  final bool showError;
  final String errorTitle;
  final String errorMessage;
  final int startRow;
  final int startCol;
  final int endRow;
  final int endCol;

  const DataValidation({
    required this.id,
    required this.type,
    this.operator = ValidationOperator.between,
    this.value1 = '',
    this.value2 = '',
    this.listItems,
    this.showDropdown = true,
    this.showError = true,
    this.errorTitle = '',
    this.errorMessage = '',
    required this.startRow,
    required this.startCol,
    required this.endRow,
    required this.endCol,
  });

  /// 셀 값이 규칙을 충족하는지 검사
  bool validate(dynamic cellValue) {
    if (cellValue == null || cellValue.toString().isEmpty) return true;

    switch (type) {
      case ValidationType.list:
        if (listItems == null || listItems!.isEmpty) return true;
        return listItems!.contains(cellValue.toString());

      case ValidationType.wholeNumber:
        final n = int.tryParse(cellValue.toString());
        if (n == null) return false;
        return _checkOperator(n.toDouble());

      case ValidationType.decimal:
        final n = double.tryParse(cellValue.toString());
        if (n == null) return false;
        return _checkOperator(n);

      case ValidationType.textLength:
        final len = cellValue.toString().length.toDouble();
        return _checkOperator(len);

      case ValidationType.date:
        final d = DateTime.tryParse(cellValue.toString());
        if (d == null) return false;
        final v1 = DateTime.tryParse(value1);
        final v2 = DateTime.tryParse(value2);
        if (v1 == null) return true;
        return _checkDateOperator(d, v1, v2);

      case ValidationType.custom:
        return true;
    }
  }

  bool _checkOperator(double val) {
    final v1 = double.tryParse(value1) ?? 0;
    final v2 = double.tryParse(value2) ?? 0;
    switch (operator) {
      case ValidationOperator.between:
        return val >= v1 && val <= v2;
      case ValidationOperator.notBetween:
        return val < v1 || val > v2;
      case ValidationOperator.equalTo:
        return val == v1;
      case ValidationOperator.notEqualTo:
        return val != v1;
      case ValidationOperator.greaterThan:
        return val > v1;
      case ValidationOperator.lessThan:
        return val < v1;
      case ValidationOperator.greaterOrEqual:
        return val >= v1;
      case ValidationOperator.lessOrEqual:
        return val <= v1;
    }
  }

  bool _checkDateOperator(DateTime val, DateTime v1, DateTime? v2) {
    switch (operator) {
      case ValidationOperator.between:
        return !val.isBefore(v1) && (v2 == null || !val.isAfter(v2));
      case ValidationOperator.notBetween:
        return val.isBefore(v1) || (v2 != null && val.isAfter(v2));
      case ValidationOperator.equalTo:
        return val.year == v1.year && val.month == v1.month && val.day == v1.day;
      case ValidationOperator.notEqualTo:
        return !(val.year == v1.year && val.month == v1.month && val.day == v1.day);
      case ValidationOperator.greaterThan:
        return val.isAfter(v1);
      case ValidationOperator.lessThan:
        return val.isBefore(v1);
      case ValidationOperator.greaterOrEqual:
        return !val.isBefore(v1);
      case ValidationOperator.lessOrEqual:
        return !val.isAfter(v1);
    }
  }

  /// 해당 셀이 이 규칙의 범위에 포함되는지
  bool containsCell(int row, int col) {
    return row >= startRow && row <= endRow && col >= startCol && col <= endCol;
  }

  DataValidation copyWith({
    String? id,
    ValidationType? type,
    ValidationOperator? operator,
    String? value1,
    String? value2,
    List<String>? listItems,
    bool? showDropdown,
    bool? showError,
    String? errorTitle,
    String? errorMessage,
    int? startRow,
    int? startCol,
    int? endRow,
    int? endCol,
  }) {
    return DataValidation(
      id: id ?? this.id,
      type: type ?? this.type,
      operator: operator ?? this.operator,
      value1: value1 ?? this.value1,
      value2: value2 ?? this.value2,
      listItems: listItems ?? this.listItems,
      showDropdown: showDropdown ?? this.showDropdown,
      showError: showError ?? this.showError,
      errorTitle: errorTitle ?? this.errorTitle,
      errorMessage: errorMessage ?? this.errorMessage,
      startRow: startRow ?? this.startRow,
      startCol: startCol ?? this.startCol,
      endRow: endRow ?? this.endRow,
      endCol: endCol ?? this.endCol,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'operator': operator.index,
        'value1': value1,
        'value2': value2,
        'listItems': listItems,
        'showDropdown': showDropdown,
        'showError': showError,
        'errorTitle': errorTitle,
        'errorMessage': errorMessage,
        'startRow': startRow,
        'startCol': startCol,
        'endRow': endRow,
        'endCol': endCol,
      };

  factory DataValidation.fromJson(Map<String, dynamic> json) => DataValidation(
        id: json['id'] as String,
        type: ValidationType.values[json['type'] as int],
        operator: ValidationOperator.values[json['operator'] as int],
        value1: json['value1'] as String? ?? '',
        value2: json['value2'] as String? ?? '',
        listItems: (json['listItems'] as List?)?.cast<String>(),
        showDropdown: json['showDropdown'] as bool? ?? true,
        showError: json['showError'] as bool? ?? true,
        errorTitle: json['errorTitle'] as String? ?? '',
        errorMessage: json['errorMessage'] as String? ?? '',
        startRow: json['startRow'] as int,
        startCol: json['startCol'] as int,
        endRow: json['endRow'] as int,
        endCol: json['endCol'] as int,
      );
}

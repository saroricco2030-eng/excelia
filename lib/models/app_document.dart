enum DocumentType {
  spreadsheet,
  document,
  presentation,
  pdf,
}

class AppDocument {
  final String id;
  final String name;
  final DocumentType type;
  final String? filePath;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final int? fileSize;

  const AppDocument({
    required this.id,
    required this.name,
    required this.type,
    this.filePath,
    required this.createdAt,
    required this.modifiedAt,
    this.fileSize,
  });

  AppDocument copyWith({
    String? id,
    String? name,
    DocumentType? type,
    String? filePath,
    DateTime? createdAt,
    DateTime? modifiedAt,
    int? fileSize,
  }) {
    return AppDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.index,
        'filePath': filePath,
        'createdAt': createdAt.toIso8601String(),
        'modifiedAt': modifiedAt.toIso8601String(),
        'fileSize': fileSize,
      };

  factory AppDocument.fromJson(Map<String, dynamic> json) => AppDocument(
        id: json['id'] as String,
        name: json['name'] as String,
        type: DocumentType.values[json['type'] as int],
        filePath: json['filePath'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        modifiedAt: DateTime.parse(json['modifiedAt'] as String),
        fileSize: json['fileSize'] as int?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppDocument &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AppDocument(id: $id, name: $name, type: $type)';
}

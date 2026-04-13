import 'package:excelia/models/app_document.dart';

class RecentFile {
  final String name;
  final String path;
  final DocumentType type;
  final DateTime lastOpened;
  final int sizeInBytes;

  const RecentFile({
    required this.name,
    required this.path,
    required this.type,
    required this.lastOpened,
    required this.sizeInBytes,
  });

  RecentFile copyWith({
    String? name,
    String? path,
    DocumentType? type,
    DateTime? lastOpened,
    int? sizeInBytes,
  }) {
    return RecentFile(
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      lastOpened: lastOpened ?? this.lastOpened,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'path': path,
        'type': type.index,
        'lastOpened': lastOpened.toIso8601String(),
        'sizeInBytes': sizeInBytes,
      };

  factory RecentFile.fromJson(Map<String, dynamic> json) => RecentFile(
        name: json['name'] as String,
        path: json['path'] as String,
        type: DocumentType.values[json['type'] as int],
        lastOpened: DateTime.parse(json['lastOpened'] as String),
        sizeInBytes: json['sizeInBytes'] as int,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecentFile &&
          runtimeType == other.runtimeType &&
          path == other.path;

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() => 'RecentFile(name: $name, path: $path, type: $type)';
}

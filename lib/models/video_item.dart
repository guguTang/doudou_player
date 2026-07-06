import 'package:path/path.dart' as p;

class VideoItem {
  VideoItem({
    required this.id,
    required this.filePath,
    required this.title,
    this.zhSubPath,
    this.enSubPath,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  final String id;
  final String filePath;
  final String title;
  final String? zhSubPath;
  final String? enSubPath;
  final DateTime addedAt;

  factory VideoItem.fromPath(String filePath) {
    return VideoItem(
      id: filePath,
      filePath: filePath,
      title: p.basenameWithoutExtension(filePath),
    );
  }

  VideoItem copyWith({
    String? id,
    String? filePath,
    String? title,
    String? zhSubPath,
    String? enSubPath,
    bool clearZhSubPath = false,
    bool clearEnSubPath = false,
    DateTime? addedAt,
  }) {
    return VideoItem(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      zhSubPath: clearZhSubPath ? null : (zhSubPath ?? this.zhSubPath),
      enSubPath: clearEnSubPath ? null : (enSubPath ?? this.enSubPath),
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'title': title,
      'zhSubPath': zhSubPath,
      'enSubPath': enSubPath,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    return VideoItem(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      title: json['title'] as String,
      zhSubPath: json['zhSubPath'] as String?,
      enSubPath: json['enSubPath'] as String?,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }
}

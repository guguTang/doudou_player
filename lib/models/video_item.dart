import 'package:path/path.dart' as p;

class VideoItem {
  VideoItem({
    required this.id,
    required this.filePath,
    required this.title,
    this.zhSubPath,
    this.enSubPath,
    this.fileBookmark,
    this.directoryBookmark,
    this.zhSubBookmark,
    this.enSubBookmark,
    this.thumbnailPath,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  final String id;
  final String filePath;
  final String title;
  final String? zhSubPath;
  final String? enSubPath;
  final String? fileBookmark;
  final String? directoryBookmark;
  final String? zhSubBookmark;
  final String? enSubBookmark;
  final String? thumbnailPath;
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
    String? fileBookmark,
    String? directoryBookmark,
    String? zhSubBookmark,
    String? enSubBookmark,
    String? thumbnailPath,
    bool clearZhSubPath = false,
    bool clearEnSubPath = false,
    bool clearZhSubBookmark = false,
    bool clearEnSubBookmark = false,
    bool clearThumbnailPath = false,
    DateTime? addedAt,
  }) {
    return VideoItem(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      zhSubPath: clearZhSubPath ? null : (zhSubPath ?? this.zhSubPath),
      enSubPath: clearEnSubPath ? null : (enSubPath ?? this.enSubPath),
      fileBookmark: fileBookmark ?? this.fileBookmark,
      directoryBookmark: directoryBookmark ?? this.directoryBookmark,
      zhSubBookmark:
          clearZhSubBookmark ? null : (zhSubBookmark ?? this.zhSubBookmark),
      enSubBookmark:
          clearEnSubBookmark ? null : (enSubBookmark ?? this.enSubBookmark),
      thumbnailPath:
          clearThumbnailPath ? null : (thumbnailPath ?? this.thumbnailPath),
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
      'fileBookmark': fileBookmark,
      'directoryBookmark': directoryBookmark,
      'zhSubBookmark': zhSubBookmark,
      'enSubBookmark': enSubBookmark,
      'thumbnailPath': thumbnailPath,
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
      fileBookmark: json['fileBookmark'] as String?,
      directoryBookmark: json['directoryBookmark'] as String?,
      zhSubBookmark: json['zhSubBookmark'] as String?,
      enSubBookmark: json['enSubBookmark'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }
}

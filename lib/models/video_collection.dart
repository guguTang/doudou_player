enum VideoCollectionType { manual, scanRoot }

class VideoCollection {
  VideoCollection({
    required this.id,
    required this.name,
    required this.type,
    List<String>? videoIds,
    DateTime? createdAt,
    this.scanRootPath,
    this.directoryBookmark,
  })  : videoIds = List.unmodifiable(videoIds ?? const []),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final VideoCollectionType type;
  final List<String> videoIds;
  final DateTime createdAt;
  final String? scanRootPath;
  final String? directoryBookmark;

  VideoCollection copyWith({
    String? id,
    String? name,
    VideoCollectionType? type,
    List<String>? videoIds,
    DateTime? createdAt,
    String? scanRootPath,
    String? directoryBookmark,
  }) {
    return VideoCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      videoIds: videoIds ?? this.videoIds,
      createdAt: createdAt ?? this.createdAt,
      scanRootPath: scanRootPath ?? this.scanRootPath,
      directoryBookmark: directoryBookmark ?? this.directoryBookmark,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'videoIds': videoIds,
      'createdAt': createdAt.toIso8601String(),
      'scanRootPath': scanRootPath,
      'directoryBookmark': directoryBookmark,
    };
  }

  factory VideoCollection.fromJson(Map<String, dynamic> json) {
    return VideoCollection(
      id: json['id'] as String,
      name: json['name'] as String,
      type: VideoCollectionType.values.byName(json['type'] as String),
      videoIds: (json['videoIds'] as List<dynamic>).cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      scanRootPath: json['scanRootPath'] as String?,
      directoryBookmark: json['directoryBookmark'] as String?,
    );
  }
}

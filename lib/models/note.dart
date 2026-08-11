import 'note_block.dart';

class Note {
  String id;

  String title;

  String content;

  DateTime createdAt;

  DateTime updatedAt;

  String folderId;

  List<String> sphereIds;

  List<NoteBlock> blocks;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.folderId = "all",
    this.sphereIds = const [],
    this.blocks = const [],
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json["id"] as String,
      title: json["title"] as String? ?? "",
      content: json["content"] as String? ?? "",
      createdAt: DateTime.parse(json["createdAt"] as String),
      updatedAt: DateTime.parse(json["updatedAt"] as String),
      folderId: json["folderId"] ?? "all",
      sphereIds: List<String>.from(json["sphereIds"] ?? []),
      blocks: (json["blocks"] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                NoteBlock.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "content": content,
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
      "folderId": folderId,
      "sphereIds": sphereIds,
      "blocks": blocks.map((block) => block.toJson()).toList(),
    };
  }

  String get plainText {
    if (blocks.isEmpty) return content;
    return blocks.map((block) => block.text).join('\n');
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? folderId,
    List<String>? sphereIds,
    List<NoteBlock>? blocks,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      folderId: folderId ?? this.folderId,
      sphereIds: sphereIds ?? List<String>.from(this.sphereIds),
      blocks: blocks ?? List<NoteBlock>.from(this.blocks),
    );
  }
}

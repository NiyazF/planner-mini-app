class NoteFolder {
  final String id;

  String name;

  NoteFolder({required this.id, required this.name});

  factory NoteFolder.fromJson(Map<String, dynamic> json) {
    return NoteFolder(id: json["id"], name: json["name"]);
  }

  Map<String, dynamic> toJson() {
    return {"id": id, "name": name};
  }
}

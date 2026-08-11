class LifeSphere {
  String id;
  String name;
  String emoji;
  int color;

  LifeSphere({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
  });

  factory LifeSphere.fromJson(Map<String, dynamic> json) {
    return LifeSphere(
      id: json["id"],
      name: json["name"],
      emoji: json["emoji"],
      color: json["color"],
    );
  }

  Map<String, dynamic> toJson() {
    return {"id": id, "name": name, "emoji": emoji, "color": color};
  }
}

enum NoteBlockType {
  paragraph,
  heading1,
  heading2,
  checklist,
  numbered,
  quote,
  code,
  divider,
  image,
  table,
  drawing,
  audio,
}

NoteBlockType noteBlockTypeFromStorage(String? value) {
  return NoteBlockType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => NoteBlockType.paragraph,
  );
}

class NoteBlock {
  String id;
  String text;
  NoteBlockType type;

  bool isBold;
  bool isItalic;
  bool isUnderlined;
  bool isStruckThrough;
  bool isChecked;

  int colorValue;
  double fontSize;
  String fontFamily;

  NoteBlock({
    required this.id,
    this.text = '',
    this.type = NoteBlockType.paragraph,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderlined = false,
    this.isStruckThrough = false,
    this.isChecked = false,
    this.colorValue = 0xFF16161A,
    this.fontSize = 18,
    this.fontFamily = 'sans',
  });

  factory NoteBlock.fromJson(Map<String, dynamic> json) {
    return NoteBlock(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      type: noteBlockTypeFromStorage(json['type'] as String?),
      isBold: json['isBold'] as bool? ?? false,
      isItalic: json['isItalic'] as bool? ?? false,
      isUnderlined: json['isUnderlined'] as bool? ?? false,
      isStruckThrough: json['isStruckThrough'] as bool? ?? false,
      isChecked: json['isChecked'] as bool? ?? false,
      colorValue: json['colorValue'] as int? ?? 0xFF16161A,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 18,
      fontFamily: json['fontFamily'] as String? ?? 'sans',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type.name,
      'isBold': isBold,
      'isItalic': isItalic,
      'isUnderlined': isUnderlined,
      'isStruckThrough': isStruckThrough,
      'isChecked': isChecked,
      'colorValue': colorValue,
      'fontSize': fontSize,
      'fontFamily': fontFamily,
    };
  }

  NoteBlock copyWith({
    String? id,
    String? text,
    NoteBlockType? type,
    bool? isBold,
    bool? isItalic,
    bool? isUnderlined,
    bool? isStruckThrough,
    bool? isChecked,
    int? colorValue,
    double? fontSize,
    String? fontFamily,
  }) {
    return NoteBlock(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderlined: isUnderlined ?? this.isUnderlined,
      isStruckThrough: isStruckThrough ?? this.isStruckThrough,
      isChecked: isChecked ?? this.isChecked,
      colorValue: colorValue ?? this.colorValue,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }
}

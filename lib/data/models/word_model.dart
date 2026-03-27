/// Kelime verisi (JSON'dan)
class WordModel {
  final String id;
  final String word;
  final String meaning;
  final String example;
  final String exampleTr;
  final String? pronunciation;
  final String? level;

  const WordModel({
    required this.id,
    required this.word,
    required this.meaning,
    required this.example,
    required this.exampleTr,
    this.pronunciation,
    this.level,
  });

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      id: json['id'] as String? ?? json['word'] as String,
      word: json['word'] as String,
      meaning: json['meaning'] as String,
      example: json['example'] as String,
      exampleTr: json['example_tr'] as String,
      pronunciation: json['pronunciation'] as String?,
      level: json['level'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'meaning': meaning,
        'example': example,
        'example_tr': exampleTr,
        'pronunciation': pronunciation,
        'level': level,
      };
}

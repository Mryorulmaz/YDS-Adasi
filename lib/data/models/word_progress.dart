import 'word_status.dart';

/// Kullanıcının bir kelimeyle ilerlemesi (lokal DB'de tutulacak)
/// weight: Biliyorum → azalır, Tekrarla → artar. SmartShuffle zor kelimelere öncelik verir.
class WordProgress {
  final String wordId;
  WordStatus status;
  int correctCount;
  int weight; // 0=kolay, yüksek=zor. SmartShuffle için.
  DateTime? lastSeenAt;
  bool isFavorite;
  bool inVocabulary; // Kelime Hazinem'de mi?
  bool knownFromMainDeck; // Öğrenmeye Başla'da (main deck) Biliyorum yapıldı mı?
  bool inRepeatQueue; // Tekrarla kuyruğunda mı? (sadece sola kaydırılanlar)

  WordProgress({
    required this.wordId,
    this.status = WordStatus.newWord,
    this.correctCount = 0,
    this.weight = 0,
    this.lastSeenAt,
    this.isFavorite = false,
    this.inVocabulary = false,
    this.knownFromMainDeck = false,
    this.inRepeatQueue = false,
  });

  /// 1+ doğru → learning. Tam öğrenme Tekrarla'dan (applyKnown) gelir.
  void applyCorrect() {
    correctCount++;
    weight = (weight - 1).clamp(0, 999);
    lastSeenAt = DateTime.now();
    if (correctCount >= 1) {
      status = WordStatus.learning;
    }
  }

  /// Tekrarla ekranında "Biliyorum": kelimeyi kesin olarak öğrenilmiş kabul eder.
  void applyKnown() {
    status = WordStatus.learned;
    if (correctCount == 0) {
      correctCount = 1;
    } else if (correctCount < 3) {
      correctCount = 3;
    }
    weight = 0;
    lastSeenAt = DateTime.now();
  }

  /// Tekrarla → weight artar (zor kelime olarak işaretlenir).
  void applyWrong() {
    status = WordStatus.learning;
    weight = (weight + 2).clamp(0, 999);
    lastSeenAt = DateTime.now();
  }

  Map<String, dynamic> toMap() => {
        'wordId': wordId,
        'status': status.index,
        'correctCount': correctCount,
        'weight': weight,
        'lastSeenAt': lastSeenAt?.toIso8601String(),
        'isFavorite': isFavorite,
        'inVocabulary': inVocabulary,
        'knownFromMainDeck': knownFromMainDeck,
        'inRepeatQueue': inRepeatQueue,
      };

  factory WordProgress.fromMap(Map<dynamic, dynamic> map) {
    return WordProgress(
      wordId: map['wordId'] as String,
      status: WordStatus.values[map['status'] as int? ?? 0],
      correctCount: map['correctCount'] as int? ?? 0,
      weight: map['weight'] as int? ?? 0,
      lastSeenAt: map['lastSeenAt'] != null
          ? DateTime.tryParse(map['lastSeenAt'] as String)
          : null,
      isFavorite: map['isFavorite'] as bool? ?? false,
      inVocabulary: map['inVocabulary'] as bool? ?? false,
      knownFromMainDeck: map['knownFromMainDeck'] as bool? ?? false,
      inRepeatQueue: map['inRepeatQueue'] as bool? ?? false,
    );
  }

  factory WordProgress.fromJson(Map<String, dynamic> map) {
    return WordProgress(
      wordId: map['wordId'] as String,
      status: WordStatus.values[map['status'] as int? ?? 0],
      correctCount: map['correctCount'] as int? ?? 0,
      weight: map['weight'] as int? ?? 0,
      lastSeenAt: map['lastSeenAt'] != null
          ? DateTime.tryParse(map['lastSeenAt'] as String)
          : null,
      isFavorite: map['isFavorite'] as bool? ?? false,
      inVocabulary: map['inVocabulary'] as bool? ?? false,
      knownFromMainDeck: map['knownFromMainDeck'] as bool? ?? false,
      inRepeatQueue: map['inRepeatQueue'] as bool? ?? false,
    );
  }
}

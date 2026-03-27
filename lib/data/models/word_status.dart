/// Kelime öğrenme durumu (spaced repetition uyumlu)
enum WordStatus {
  newWord,   // Yeni – ilk görülen
  learning,  // Öğreniliyor – 1 doğru sonrası
  review,    // Tekrar – ileride spaced repetition
  learned,   // Öğrenildi – 3 doğru sonrası
}

extension WordStatusExt on WordStatus {
  String get label {
    switch (this) {
      case WordStatus.newWord:
        return 'Yeni';
      case WordStatus.learning:
        return 'Öğreniliyor';
      case WordStatus.review:
        return 'Tekrar';
      case WordStatus.learned:
        return 'Öğrenildi';
    }
  }
}

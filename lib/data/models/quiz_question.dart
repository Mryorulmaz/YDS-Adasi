import 'word_model.dart';

enum QuizType { meaning, sentence }

class QuizQuestion {
  final QuizType type;
  final WordModel word;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({
    required this.type,
    required this.word,
    required this.options,
    required this.correctIndex,
  });
}

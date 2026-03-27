import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/academic_meaning_fallback.dart';
import '../data/models/quiz_question.dart';
import '../data/models/word_model.dart';
import '../data/models/word_progress.dart';
import '../data/repositories/word_repository.dart';

/// Uygulama state'i – UI ana thread'de güncellenir, ağır işler arka planda
class AppProvider extends ChangeNotifier {
  final WordRepository _wordRepo = WordRepository();
  final ProgressRepository _progressRepo = ProgressRepository();

  List<WordModel> _allWords = [];
  List<WordModel> _currentDeck = [];
  int _currentIndex = 0;
  int _sessionStudiedCount = 0;
  bool _isLoading = true;
  bool _isPremium = false;
  Future<void>? _loadWordsFuture;
  String? _filterMode; // null = tümü, 'learning' = bilmediklerim, 'learned' = tekrarla

  List<WordModel> get allWords => List.unmodifiable(_allWords);
  List<WordModel> get currentDeck => List.unmodifiable(_currentDeck);
  int get currentIndex => _currentIndex;
  int get sessionStudiedCount => _sessionStudiedCount;
  bool get isLoading => _isLoading;
  bool get isPremium => _isPremium;
  String? get filterMode => _filterMode;

  int get todayStudied => _progressRepo.todayStudied;
  int get todayKnownCount => _progressRepo.todayKnownCount;
  int get mainKnownCount => _progressRepo.mainKnownCount;
  int get mainKnownUnlearnedCount => _progressRepo.mainKnownUnlearnedCount;
  int get streak => _progressRepo.streak;
  int get learnedCount => _progressRepo.learnedCount;
  int get learningCount => _progressRepo.learningCount;
  int get favoriteCount => _progressRepo.favoriteWordIds.length;
  List<String> get favoriteWordIds => _progressRepo.favoriteWordIds;
  double get lastQuizRatio => _progressRepo.lastQuizRatio;

  List<WordModel> getFavoriteWords() =>
      _allWords.where((w) => favoriteWordIds.contains(w.id)).toList();

  /// Kelime Hazinem: Öğrenmeye Başla'da Biliyorum yaptığın veya kesin öğrenilen kelimeler
  int get vocabularyCount => _progressRepo.vocabularyCount;
  List<WordModel> getVocabularyWords() {
    final ids = _progressRepo.vocabularyWordIds.toSet();
    return _allWords.where((w) => ids.contains(w.id)).toList();
  }

  List<String> get repeatQueueWordIds => _progressRepo.repeatQueueWordIds;

  List<({String date, int count})> get last7DaysActivity =>
      _progressRepo.last7DaysActivity;

  int get totalQuizSlots => _progressRepo.totalQuizSlots;
  int? getQuizSlotScore(int i) => _progressRepo.getQuizSlotScore(i);
  void recordQuizSlotScore(int slot, int correct) =>
      _progressRepo.recordQuizSlotScore(slot, correct);
  void addBonusQuizSlot() {
    _progressRepo.addBonusQuizSlot();
    notifyListeners();
  }
  bool get notificationsEnabled => _progressRepo.notificationsEnabled;

  Future<void> setNotificationsEnabled(bool value) async {
    await _progressRepo.setNotificationsEnabled(value);
    notifyListeners();
  }

  /// Tüm ilerlemeyi ve istatistikleri sıfırla (bildirim ayarı korunur)
  Future<void> resetStatistics() async {
    await _progressRepo.resetAll();
    _currentDeck = [];
    _currentIndex = 0;
    _sessionStudiedCount = 0;
    _filterMode = null;
    resetQuiz();
    await loadWords();
  }

  static const int dailyLimit = 25;

  /// Günlük limit: Premium sınırsız, ücretsiz 25 + bonus
  int get todayTarget =>
      _isPremium ? 999 : _progressRepo.todayTarget;

  /// Günlük limit doldu mu? (Premium hariç)
  bool get isDailyLimitReached => !_isPremium && todayStudied >= todayTarget;

  /// Öğrenmeye başlayabilir mi? (limit dolmadı veya Tekrarla/Quiz modu)
  bool canStartNewSession({String? mode}) {
    if (_isPremium) return true;
    if (mode != null && mode != '') return true; // Tekrarla, Quiz modları limit dışı
    return todayStudied < todayTarget;
  }

  int get todayRewardedAdCount => _progressRepo.todayRewardedAdCount;

  /// Ödüllü reklam izlendiğinde çağrılır; 2+ ise o gün Interstitial atlanır
  void recordRewardedAdWatched() {
    _progressRepo.incrementRewardedAdCount();
    notifyListeners();
  }

  /// Ödüllü reklam sonrası +10 kelime hakkı
  void grantBonusWords(int amount) {
    _progressRepo.addBonusWords(amount);
    notifyListeners();
  }

  WordModel? get currentWord {
    if (_currentDeck.isEmpty || _currentIndex >= _currentDeck.length) {
      return null;
    }
    return _currentDeck[_currentIndex];
  }

  WordProgress? get currentProgress {
    final w = currentWord;
    if (w == null) return null;
    return _progressRepo.getProgress(w.id);
  }

  bool get isFavorite => currentWord != null && _progressRepo.isFavorite(currentWord!.id);

  Future<void> loadWords() {
    _loadWordsFuture ??= _loadWordsInternal();
    return _loadWordsFuture!;
  }

  Future<void> _loadWordsInternal() async {
    if (!_isLoading) {
      _isLoading = true;
      notifyListeners();
    } else {
      notifyListeners();
    }
    await _progressRepo.init();
    _allWords = await _wordRepo.getWords();
    _isLoading = false;
    notifyListeners();
  }

  void setPremium(bool value) {
    if (value == _isPremium) return;
    _isPremium = value;
    notifyListeners();
  }

  /// SmartShuffle: excludeLearning=true (Öğrenmeye Başla) ise sadece yeni+hatırlatma; yoksa %60 yeni, %30 zor, %10 hatırlatma.
  List<WordModel> _buildSmartShuffleDeck(int take, {Set<String>? excludeIds, bool excludeLearning = false}) {
    if (take <= 0) return [];
    final exclude = excludeIds ?? <String>{};
    final seenIds = _progressRepo.learningWordIds.toSet()
      ..addAll(_progressRepo.learnedWordIds)
      ..addAll(exclude);
    final learnedIds = _progressRepo.learnedWordIds.toSet();
    final unseen = _allWords.where((w) => !seenIds.contains(w.id)).toList();
    List<({WordModel word, int weight})> difficult;
    if (excludeLearning) {
      difficult = <({WordModel word, int weight})>[];
    } else {
      difficult = _allWords
          .where((w) => seenIds.contains(w.id) && (learnedIds.isEmpty || !learnedIds.contains(w.id)))
          .map((w) {
            final p = _progressRepo.getProgress(w.id);
            return (word: w, weight: p?.weight ?? 0);
          })
          .where((x) => x.weight > 0)
          .toList();
      difficult.sort((a, b) => b.weight.compareTo(a.weight));
    }
    final review = _allWords
        .where((w) => learnedIds.contains(w.id) && !exclude.contains(w.id))
        .toList();

    final countNew = excludeLearning ? (take * 0.90).round() : (take * 0.60).round();
    final countDifficult = excludeLearning ? 0 : (take * 0.30).round();
    final countReview = excludeLearning ? (take * 0.10).round() : (take * 0.10).round();
    final rand = Random(DateTime.now().microsecondsSinceEpoch);
    unseen.shuffle(rand);
    review.shuffle(rand);
    final newWords = unseen.take(countNew).toList();
    final diffWords = difficult.map((x) => x.word).take(countDifficult).toList();
    diffWords.shuffle(rand);
    final reviewWords = review.take(countReview).toList();
    final deck = <WordModel>[...newWords, ...diffWords, ...reviewWords]..shuffle(rand);
    if (deck.length < take) {
      final extra = _allWords
          .where((w) =>
              seenIds.contains(w.id) &&
              !deck.any((d) => d.id == w.id) &&
              !exclude.contains(w.id))
          .toList()
        ..shuffle(rand);
      deck.addAll(extra.take(take - deck.length));
    }
    return deck.take(take).toList();
  }

  /// Oturum başlat. mode==null (Öğrenmeye Başla): Kullanıcının "öğrenilecekler" listesi
  /// varsa sadece onları kullanır; yoksa SmartShuffle ile yeni + zor karışımı.
  void startSession({String? mode}) {
    _filterMode = mode;
    if (mode == 'learning') {
      // Tekrarla: SADECE sola kaydırdıkların (repeatQueue)
      final ids = _progressRepo.repeatQueueWordIds;
      final list = _allWords.where((w) => ids.contains(w.id)).toList();
      list.shuffle(Random(DateTime.now().microsecondsSinceEpoch));
      _currentDeck = list;
    } else if (mode == 'learned') {
      final ids = _progressRepo.learnedWordIds;
      _currentDeck = _allWords.where((w) => ids.contains(w.id)).toList();
    } else if (mode == 'favorites') {
      final ids = _progressRepo.favoriteWordIds;
      _currentDeck = _allWords.where((w) => ids.contains(w.id)).toList();
    } else {
      // Öğrenmeye Başla: SADECE yeni + hatırlatma. Tekrarla kelimeleri sadece Tekrarla bölümünde.
      // Bugün gösterilen kelimeler tekrar gelmez (todayMainDeckIds).
      final takeCount = (todayTarget - todayStudied).clamp(1, 999);
      final excludeIds = _progressRepo.todayMainDeckIds;
      _currentDeck = _buildSmartShuffleDeck(
        takeCount,
        excludeIds: excludeIds.isEmpty ? null : excludeIds,
        excludeLearning: true,
      );
    }
    _currentIndex = 0;
    _sessionStudiedCount = 0;
    notifyListeners();
  }

  void swipeRight() {
    final w = currentWord;
    if (w == null) return;
    final p = _progressRepo.getOrCreateProgress(w.id);
    final fromMainDeck = _filterMode == null;
    if (_filterMode == 'learning') {
      // Tekrarla ekranında Biliyorum → kelime kesin öğrenildi
      p.applyKnown();
      p.inRepeatQueue = false;
      _progressRepo.saveProgress(p, wasCorrect: false, fromMainDeck: false);
    } else {
      // Öğrenmeye Başla (ve diğer modlar) → sadece learning'e geçir, bugünkü Biliyorum say
      p.applyCorrect();
      _progressRepo.saveProgress(p, wasCorrect: fromMainDeck, fromMainDeck: fromMainDeck);
    }
    _sessionStudiedCount++;
    notifyListeners();
    _nextCard();
  }

  void swipeLeft() {
    final w = currentWord;
    if (w == null) return;
    final p = _progressRepo.getOrCreateProgress(w.id);
    p.applyWrong();
    // Sola kaydırılanlar Tekrarla kuyruğuna girer
    p.inRepeatQueue = true;
    final fromMainDeck = _filterMode == null;
    _progressRepo.saveProgress(p, wasCorrect: false, fromMainDeck: fromMainDeck);
    _sessionStudiedCount++;
    notifyListeners();
    _nextCard();
  }

  void _nextCard() {
    if (_currentIndex < _currentDeck.length - 1) {
      _currentIndex++;
      notifyListeners();
    } else {
      _currentDeck = [];
      _currentIndex = 0;
      notifyListeners();
    }
  }

  void toggleFavorite() {
    final w = currentWord;
    if (w == null) return;
    _progressRepo.toggleFavorite(w.id);
    notifyListeners();
  }

  // --- Quiz ---
  List<QuizQuestion>? _quizQuestions;
  int _quizIndex = 0;
  int _quizCorrectCount = 0;
  int _currentQuizSlotIndex = 0;
  final List<QuizQuestion> _quizWrongQuestions = [];

  List<QuizQuestion>? get quizQuestions => _quizQuestions;
  int get quizIndex => _quizIndex;
  int get quizCorrectCount => _quizCorrectCount;
  List<QuizQuestion> get quizWrongQuestions => List.unmodifiable(_quizWrongQuestions);
  int get quizTotal => _quizQuestions?.length ?? 0;
  QuizQuestion? get currentQuizQuestion =>
      _quizQuestions != null && _quizIndex < _quizQuestions!.length
          ? _quizQuestions![_quizIndex]
          : null;
  bool get isQuizDone =>
      _quizQuestions != null && _quizIndex >= _quizQuestions!.length;

  void startQuizForSlot(int slotIndex) {
    _currentQuizSlotIndex = slotIndex;
    final learningIds = _progressRepo.learningWordIds;
    if (learningIds.isEmpty) {
      _quizQuestions = [];
      _quizIndex = 0;
      _quizCorrectCount = 0;
      _quizWrongQuestions.clear();
      notifyListeners();
      return;
    }
    final pool = _allWords.where((w) => learningIds.contains(w.id)).toList();
    if (pool.length < 2) {
      _quizQuestions = [];
      notifyListeners();
      return;
    }
    pool.shuffle(Random(slotIndex + DateTime.now().day * 1000 + DateTime.now().month * 10000));
    const take = 10;
    final selected = pool.take(take).toList();
    final questions = <QuizQuestion>[];
    final rand = Random(slotIndex + DateTime.now().day * 1000);
    final indices = List.generate(selected.length, (i) => i)..shuffle(rand);
    final meaningIndices = indices.take(5).toSet();
    for (var i = 0; i < selected.length; i++) {
      final word = selected[i];
      final type = meaningIndices.contains(i) ? QuizType.meaning : QuizType.sentence;
      if (type == QuizType.meaning) {
        final others =
            _allWords.where((w) => w.id != word.id).toList()..shuffle(rand);
        final correctMeaning = getDisplayMeaning(word.word, word.meaning);
        final options = [correctMeaning];
        for (var j = 0; options.length < 4 && j < others.length; j++) {
          final otherMeaning = getDisplayMeaning(others[j].word, others[j].meaning);
          if (!options.contains(otherMeaning)) {
            options.add(otherMeaning);
          }
        }
        options.shuffle(rand);
        final correctIndex = options.indexOf(correctMeaning);
        if (correctIndex >= 0) {
          questions.add(QuizQuestion(
            type: QuizType.meaning,
            word: word,
            options: options,
            correctIndex: correctIndex,
          ));
        }
      } else {
        final others =
            _allWords.where((w) => w.id != word.id).toList()..shuffle(rand);
        final options = [word.word];
        for (var j = 0; options.length < 4 && j < others.length; j++) {
          if (!options.contains(others[j].word)) {
            options.add(others[j].word);
          }
        }
        options.shuffle(rand);
        final correctIndex = options.indexOf(word.word);
        if (correctIndex >= 0) {
          questions.add(QuizQuestion(
            type: QuizType.sentence,
            word: word,
            options: options,
            correctIndex: correctIndex,
          ));
        }
      }
    }
    _quizQuestions = questions;
    _quizIndex = 0;
    _quizCorrectCount = 0;
    _quizWrongQuestions.clear();
    notifyListeners();
  }

  void answerQuiz(int selectedIndex) {
    final q = currentQuizQuestion;
    if (q == null) return;
    if (selectedIndex == q.correctIndex) {
      _quizCorrectCount++;
    } else {
      _quizWrongQuestions.add(q);
      final p = _progressRepo.getOrCreateProgress(q.word.id);
      p.applyWrong();
      _progressRepo.saveProgress(p);
    }
    _quizIndex++;
    if (_quizQuestions != null && _quizIndex >= _quizQuestions!.length) {
      _progressRepo.recordQuizResult(_quizCorrectCount, _quizQuestions!.length);
      _progressRepo.recordQuizSlotScore(_currentQuizSlotIndex, _quizCorrectCount);
    }
    notifyListeners();
  }

  void resetQuiz() {
    _quizQuestions = null;
    _quizIndex = 0;
    _quizCorrectCount = 0;
    _quizWrongQuestions.clear();
    notifyListeners();
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/services/notification_service.dart';
import '../models/word_model.dart';
import '../models/word_progress.dart';
import '../models/word_status.dart';

/// JSON string'den WordModel listesi parse eder (Isolate'te çalışır)
List<WordModel> _parseWordsJson(String jsonString) {
  final data = jsonDecode(jsonString) as Map<String, dynamic>;
  final list = data['words'] as List<dynamic>;
  return list
      .map((e) => WordModel.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Kelime verisini asset'ten okur (offline-first). ID üzerinden eşleştirme; tek kaynak karışıklığı önler.
/// Önce master_words.json dene; yoksa words + additions ile birleştir. Parse compute() ile izolatörde.
class WordRepository {
  List<WordModel>? _words;
  static const String _masterAssetPath = 'assets/data/master_words.json';
  static const String _baseAssetPath = 'assets/data/words.json';
  static const String _extraAssetPath = 'assets/data/words_additions.json';
  static const String _extraAssetPath2 = 'assets/data/words_additions2.json';
  static const String _newBatchPath = 'assets/data/new_words_batch.json';

  Future<List<WordModel>> getWords() async {
    if (_words != null) return _words!;

    // Tek kaynak: master_words.json varsa sadece onu kullan (script ile birleştirilmiş)
    try {
      final masterJson = await rootBundle.loadString(_masterAssetPath);
      _words = await compute(_parseWordsJson, masterJson);
      return _words!;
    } catch (_) {
      // master yoksa mevcut çoklu dosya
    }

    final baseJsonString = await rootBundle.loadString(_baseAssetPath);
    final baseWords = await compute(_parseWordsJson, baseJsonString);

    List<WordModel> extraWords = [];
    try {
      final extraJsonString = await rootBundle.loadString(_extraAssetPath);
      extraWords = await compute(_parseWordsJson, extraJsonString);
    } catch (_) {}

    List<WordModel> extraWords2 = [];
    try {
      final extraJsonString2 = await rootBundle.loadString(_extraAssetPath2);
      extraWords2 = await compute(_parseWordsJson, extraJsonString2);
    } catch (_) {}

    List<WordModel> newBatch = [];
    try {
      final batchJson = await rootBundle.loadString(_newBatchPath);
      newBatch = await compute(_parseWordsJson, batchJson);
    } catch (_) {}

    final seenIds = <String>{};
    final all = <WordModel>[];
    for (final w in baseWords) {
      if (seenIds.add(w.id)) all.add(w);
    }
    for (final w in extraWords) {
      if (seenIds.add(w.id)) all.add(w);
    }
    for (final w in extraWords2) {
      if (seenIds.add(w.id)) all.add(w);
    }
    for (final w in newBatch) {
      if (seenIds.add(w.id)) all.add(w);
    }
    _words = all;
    return _words!;
  }

  Future<WordModel?> getWordById(String id) async {
    final words = await getWords();
    try {
      return words.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }
}

const String _progressBoxName = 'word_progress';
const String _statsBoxName = 'app_stats';
const int _dailyStudyLimit = 25;

/// Kullanıcı ilerlemesi – Hive ile kalıcı
class ProgressRepository {
  Box<String>? _progressBox;
  Box? _statsBox;
  final Map<String, WordProgress> _progress = {};
  int _todayStudied = 0;
  int _todayKnownCount = 0; // Bugün "biliyorum" (sağa kaydırma) sayısı
  int _todayBonusWords = 0; // Ödüllü reklam ile kazanılan +10 kelime hakkı
  int _todayRewardedAdCount = 0; // Bugün izlenen ödüllü reklam sayısı (2+ ise Interstitial atlanır)
  int _todayQuizCount = 0; // Bugün başlatılan quiz sayısı (günlük limit)
  int _todayBonusQuizSlots = 0; // Reklam ile açılan ek quiz slotları
  String _todayQuizResults = ''; // "8|7|10|" = slot1:8/10, slot2:7/10, slot3:10/10
  final Set<String> _todayMainDeckIds = {}; // Bugün Öğrenmeye Başla'da gösterilen kelimeler (tekrar gelmesin)
  DateTime? _lastStudyDate;
  int _streak = 0;
  String? _loadedDate;

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(_progressBoxName)) {
      _progressBox = await Hive.openBox<String>(_progressBoxName);
    } else {
      _progressBox = Hive.box<String>(_progressBoxName);
    }
    if (!Hive.isBoxOpen(_statsBoxName)) {
      _statsBox = await Hive.openBox<dynamic>(_statsBoxName);
    } else {
      _statsBox = Hive.box<dynamic>(_statsBoxName);
    }
    _loadStats();
    _loadProgress();
  }

  void _loadStats() {
    if (_statsBox == null) return;
    _streak = _statsBox!.get('streak', defaultValue: 0) as int;
    final lastStr = _statsBox!.get('lastStudyDate') as String?;
    _lastStudyDate = lastStr != null ? DateTime.tryParse(lastStr) : null;
    _loadedDate = _statsBox!.get('todayDate') as String?;
    _todayStudied = (_statsBox!.get('todayStudied', defaultValue: 0) as int).clamp(0, 999);
    _todayKnownCount = (_statsBox!.get('todayKnownCount', defaultValue: 0) as int).clamp(0, _dailyStudyLimit);
    _todayBonusWords = (_statsBox!.get('todayBonusWords', defaultValue: 0) as int).clamp(0, 99);
    _todayRewardedAdCount = (_statsBox!.get('todayRewardedAdCount', defaultValue: 0) as int).clamp(0, 99);
    _todayQuizCount = (_statsBox!.get('todayQuizCount', defaultValue: 0) as int).clamp(0, 99);
    _todayBonusQuizSlots = (_statsBox!.get('todayBonusQuizSlots', defaultValue: 0) as int).clamp(0, 10);
    _todayQuizResults = _statsBox!.get('todayQuizResults', defaultValue: '') as String? ?? '';
    _todayMainDeckIds.clear();
    final savedIds = _statsBox!.get('todayMainDeckIds') as String?;
    if (savedIds != null && savedIds.isNotEmpty) {
      try {
        final list = jsonDecode(savedIds) as List<dynamic>;
        _todayMainDeckIds.addAll(list.map((e) => e.toString()));
      } catch (_) {}
    }
    final now = DateTime.now();
    final todayStr = _todayDateString(now);
    final todayDate = DateTime(now.year, now.month, now.day);
    if (_loadedDate != todayStr) {
      _todayStudied = 0;
      _todayKnownCount = 0;
      _todayBonusWords = 0;
      _todayRewardedAdCount = 0;
      _todayQuizCount = 0;
      _todayBonusQuizSlots = 0;
      _todayQuizResults = '';
      _todayMainDeckIds.clear();
      _loadedDate = todayStr;
      if (_lastStudyDate != null) {
        final lastDay = DateTime(_lastStudyDate!.year, _lastStudyDate!.month, _lastStudyDate!.day);
        final diff = todayDate.difference(lastDay).inDays;
        if (diff == 1) {
          _streak++;
        } else if (diff > 1) {
          _streak = 1;
        }
      } else {
        _streak = 1;
      }
      _lastStudyDate = todayDate;
      _persistStats();
    }
  }

  String _todayDateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _loadProgress() {
    if (_progressBox == null) return;
    _progress.clear();
    for (final key in _progressBox!.keys) {
      final value = _progressBox!.get(key);
      if (value != null) {
        try {
          final map = jsonDecode(value) as Map<String, dynamic>;
          final p = WordProgress.fromJson(map);
          // Geriye dönük uyumluluk: eski kayıtlarda knownFromMainDeck yok.
          // Learning + correctCount>0 ise büyük ihtimalle "Öğrenmeye Başla Biliyorum" idi.
          if (!map.containsKey('knownFromMainDeck')) {
            if (p.status == WordStatus.learning && p.correctCount > 0) {
              p.knownFromMainDeck = true;
            }
          }
          // Eski kayıtlarda inRepeatQueue yok: status==learning + correctCount==0 ise muhtemelen sola kaydırıldı.
          if (!map.containsKey('inRepeatQueue')) {
            if (p.status == WordStatus.learning && p.correctCount == 0) {
              p.inRepeatQueue = true;
            }
          }
          // Kelime Hazinem: Öğrenmeye Başla Biliyorum (knownFromMainDeck) + Öğrenildi (learned)
          p.inVocabulary = p.knownFromMainDeck || p.status == WordStatus.learned;
          _progress[key] = p;
        } catch (_) {}
      }
    }
  }

  void _persistStats() {
    final now = DateTime.now();
    final todayStr = _todayDateString(now);
    _statsBox?.put('streak', _streak);
    _statsBox?.put('lastStudyDate', _lastStudyDate?.toIso8601String());
    _statsBox?.put('todayStudied', _todayStudied);
    _statsBox?.put('todayKnownCount', _todayKnownCount);
    _statsBox?.put('todayBonusWords', _todayBonusWords);
    _statsBox?.put('todayRewardedAdCount', _todayRewardedAdCount);
    _statsBox?.put('todayQuizCount', _todayQuizCount);
    _statsBox?.put('todayBonusQuizSlots', _todayBonusQuizSlots);
    _statsBox?.put('todayQuizResults', _todayQuizResults);
    _statsBox?.put('todayDate', todayStr);
    _statsBox?.put('activity_$todayStr', _todayKnownCount);
    _statsBox?.put('todayMainDeckIds', jsonEncode(_todayMainDeckIds.toList()));
  }

  Set<String> get todayMainDeckIds => Set.from(_todayMainDeckIds);

  /// Unique Kelime Hazinem ID'leri: main deck Biliyorum + learned (Set = kesin benzersiz)
  Set<String> get vocabularyUniqueIds {
    final ids = <String>{};
    for (final e in _progress.entries) {
      final p = e.value;
      if (p.knownFromMainDeck || p.status == WordStatus.learned) {
        ids.add(e.key);
      }
    }
    return ids;
  }

  int get vocabularyCount => vocabularyUniqueIds.length;

  List<String> get vocabularyWordIds => vocabularyUniqueIds.toList();

  /// Öğrenmeye Başla'da sağa kaydırılan benzersiz kelime sayısı
  int get mainKnownCount =>
      _progress.values.where((p) => p.knownFromMainDeck).length;

  /// Öğrenmeye Başla'da Biliyorum (ama henüz learned olmayan) benzersiz kelime sayısı
  int get mainKnownUnlearnedCount => _progress.values
      .where((p) => p.knownFromMainDeck && p.status != WordStatus.learned)
      .length;

  /// Tekrarla kuyruğu: sadece sola kaydırılan ve henüz learned olmayanlar
  List<String> get repeatQueueWordIds => _progress.entries
      .where((e) => e.value.inRepeatQueue && e.value.status != WordStatus.learned)
      .map((e) => e.key)
      .toList();

  int get todayQuizCount => _todayQuizCount;
  int get todayBonusQuizSlots => _todayBonusQuizSlots;
  static const int _freeQuizLimit = 2;

  /// Toplam quiz slotu: 2 ücretsiz + bonus
  int get totalQuizSlots => _freeQuizLimit + _todayBonusQuizSlots;

  /// Slot N'nin skoru (null = tamamlanmadı)
  int? getQuizSlotScore(int slotIndex) {
    final parts = _todayQuizResults.split('|');
    if (slotIndex < 0 || slotIndex >= parts.length) return null;
    final s = parts[slotIndex].trim();
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }

  /// Slot tamamlandığında skoru kaydet
  void recordQuizSlotScore(int slotIndex, int correct) {
    final parts = _todayQuizResults.split('|');
    while (parts.length <= slotIndex) {
      parts.add('');
    }
    parts[slotIndex] = '$correct';
    _todayQuizResults = parts.join('|');
    _persistStats();
  }

  /// Günde 3 ücretsiz; 4+ için reklam gerekir
  bool get canStartFreeQuiz => _todayQuizCount < _freeQuizLimit;

  void incrementQuizCount() {
    _todayQuizCount = (_todayQuizCount + 1).clamp(0, 99);
    _persistStats();
  }

  void addBonusQuizSlot() {
    _todayBonusQuizSlots = (_todayBonusQuizSlots + 1).clamp(0, 10);
    _persistStats();
  }

  /// Günlük efektif limit: 25 + ödüllü reklam bonusu
  int get todayTarget => _dailyStudyLimit + _todayBonusWords;

  int get todayBonusWords => _todayBonusWords;

  int get todayRewardedAdCount => _todayRewardedAdCount;

  /// Ödüllü reklam izlendiğinde çağrılır; 2+ ise o gün Interstitial atlanır
  void incrementRewardedAdCount() {
    _todayRewardedAdCount = (_todayRewardedAdCount + 1).clamp(0, 99);
    _persistStats();
  }

  /// Ödüllü reklam izlendikten sonra +10 kelime hakkı ekle
  void addBonusWords(int amount) {
    _todayBonusWords = (_todayBonusWords + amount).clamp(0, 99);
    _persistStats();
  }

  void recordQuizResult(int correct, int total) {
    if (_statsBox == null) return;
    _statsBox!.put('lastQuizCorrect', correct);
    _statsBox!.put('lastQuizTotal', total);
  }

  int get lastQuizCorrect => _statsBox?.get('lastQuizCorrect', defaultValue: 0) as int? ?? 0;
  int get lastQuizTotal => _statsBox?.get('lastQuizTotal', defaultValue: 0) as int? ?? 0;
  double get lastQuizRatio => lastQuizTotal > 0 ? lastQuizCorrect / lastQuizTotal : 0.0;

  /// Son 7 gün için günde öğrenilen kelime sayısı (max 25; eski todayStudied değerleri 25'te cap).
  List<({String date, int count})> get last7DaysActivity {
    if (_statsBox == null) return [];
    final now = DateTime.now();
    final result = <({String date, int count})>[];
    for (var i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      final dateStr = _todayDateString(d);
      final raw = _statsBox!.get('activity_$dateStr', defaultValue: 0) as int? ?? 0;
      result.add((date: dateStr, count: raw.clamp(0, _dailyStudyLimit)));
    }
    return result;
  }

  void _persistProgress(WordProgress p) {
    _progressBox?.put(p.wordId, jsonEncode(p.toMap()));
  }

  WordProgress getOrCreateProgress(String wordId) {
    return _progress.putIfAbsent(
      wordId,
      () => WordProgress(wordId: wordId),
    );
  }

  /// wasCorrect: true ise todayKnownCount artar (sadece Öğrenmeye Başla için kullanılmalı)
  /// fromMainDeck: true ise kelime bugün Öğrenmeye Başla'da gösterildi; Kelime Hazinem'e girer, tekrar gelmesin
  void saveProgress(WordProgress p, {bool wasCorrect = false, bool fromMainDeck = false}) {
    // Main deck sağa kaydırma: Biliyorum havuzuna ekle (benzersiz)
    if (fromMainDeck && wasCorrect) {
      p.knownFromMainDeck = true;
    }
    // Kelime Hazinem: main deck biliyorum + learned
    p.inVocabulary = p.knownFromMainDeck || p.status == WordStatus.learned;
    _progress[p.wordId] = p;
    if (fromMainDeck) {
      _todayMainDeckIds.add(p.wordId);
    }
    _updateTodayAndStreak(wasCorrect: wasCorrect, countStudied: fromMainDeck);
    _persistProgress(p);
  }

  void _updateTodayAndStreak({bool wasCorrect = false, bool countStudied = true}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_lastStudyDate != today) {
      if (_lastStudyDate != null) {
        final diff = today.difference(_lastStudyDate!).inDays;
        if (diff == 1) {
          _streak++;
        } else if (diff > 1) {
          _streak = 1;
        }
      } else {
        _streak = 1;
      }
      _todayStudied = 0;
      _todayKnownCount = 0;
      _lastStudyDate = today;
    }
    if (countStudied) {
      _todayStudied = (_todayStudied + 1).clamp(0, _dailyStudyLimit + _todayBonusWords);
    }
    if (wasCorrect) _todayKnownCount = (_todayKnownCount + 1).clamp(0, _dailyStudyLimit);
    _persistStats();
  }

  int get todayStudied => _todayStudied;
  int get todayKnownCount => _todayKnownCount;
  int get streak => _streak;
  int get learnedCount =>
      _progress.values.where((p) => p.status == WordStatus.learned).length;
  int get learningCount =>
      _progress.values.where((p) => p.status == WordStatus.learning).length;

  List<String> get learningWordIds => _progress.entries
      .where((e) => e.value.status == WordStatus.learning)
      .map((e) => e.key)
      .toList();

  List<String> get learnedWordIds => _progress.entries
      .where((e) => e.value.status == WordStatus.learned)
      .map((e) => e.key)
      .toList();

  List<String> get favoriteWordIds => _progress.entries
      .where((e) => e.value.isFavorite)
      .map((e) => e.key)
      .toList();

  WordProgress? getProgress(String wordId) => _progress[wordId];

  void toggleFavorite(String wordId) {
    final p = getOrCreateProgress(wordId);
    p.isFavorite = !p.isFavorite;
    saveProgress(p);
  }

  bool isFavorite(String wordId) => _progress[wordId]?.isFavorite ?? false;

  bool get notificationsEnabled =>
      _statsBox?.get('notificationsEnabled', defaultValue: true) as bool? ?? true;

  /// Tüm ilerlemeyi ve istatistikleri sıfırla; bildirim ayarını korur
  Future<void> resetAll() async {
    final keepNotifications = notificationsEnabled;
    _progress.clear();
    for (final key in _progressBox?.keys.toList() ?? <dynamic>[]) {
      await _progressBox?.delete(key);
    }
    for (final key in _statsBox?.keys.toList() ?? <dynamic>[]) {
      await _statsBox?.delete(key);
    }
    _todayStudied = 0;
    _todayKnownCount = 0;
    _todayBonusWords = 0;
    _todayRewardedAdCount = 0;
    _todayQuizCount = 0;
    _todayBonusQuizSlots = 0;
    _todayQuizResults = '';
    _todayMainDeckIds.clear();
    _lastStudyDate = null;
    _streak = 0;
    _loadedDate = null;
    if (keepNotifications) {
      _statsBox?.put('notificationsEnabled', true);
    }
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _statsBox?.put('notificationsEnabled', value);
    if (value) {
      await NotificationService.requestPermission();
      await NotificationService.scheduleDailyReminder();
    } else {
      await NotificationService.cancelDailyReminder();
    }
  }
}

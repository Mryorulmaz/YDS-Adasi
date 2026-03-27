import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/services/ad_service.dart';
import '../core/theme/app_theme.dart';
import '../data/academic_meaning_fallback.dart';
import '../data/models/quiz_question.dart';
import '../providers/app_provider.dart';
import 'card_learning_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.slotIndex});

  final int slotIndex;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _bannerAd = AdService.instance.buildBannerAd()..load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Quiz',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (context, app, _) {
            Widget content;
            if (app.quizQuestions == null) {
              content = Center(
                child: CircularProgressIndicator(color: theme.colorScheme.primary),
              );
            } else if (app.quizQuestions!.isEmpty) {
              content = _buildEmpty(context, app);
            } else if (app.isQuizDone) {
              content = _buildResult(context, app);
            } else {
              content = _buildQuestion(context, app);
            }
            return Column(
              children: [
                Expanded(child: content),
                if (_bannerAd != null && !app.isPremium)
                  Container(
                    alignment: Alignment.center,
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, AppProvider app) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school_rounded,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Quiz için yeterli kelime yok',
              style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Önce kartlarla veya "Zor Kelimeler" ile çalış; zorlandığın kelimelerden quiz oluşur.',
              style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context, AppProvider app) {
    final theme = Theme.of(context);
    final total = app.quizTotal;
    final correct = app.quizCorrectCount;
    final wrongList = app.quizWrongQuestions;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            correct == total ? Icons.celebration : Icons.assignment_turned_in,
            size: 80,
            color: correct == total ? AppColors.success : theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            '$total soruda $correct doğru',
            style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            total > 0
                ? '%${((correct / total) * 100).round()} başarı'
                : '',
            style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                ),
            textAlign: TextAlign.center,
          ),
          if (wrongList.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text(
              'Yanlışlar (${wrongList.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            ...wrongList.map((q) {
              final correctAnswer = q.type == QuizType.meaning
                  ? getDisplayMeaning(q.word.word, q.word.meaning)
                  : q.word.word;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.type == QuizType.meaning
                          ? '"${q.word.word}" ne demek?'
                          : 'Cümle: ${q.word.example}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Doğru cevap: $correctAnswer',
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              app.startSession(mode: 'learning');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CardLearningScreen(filterMode: 'learning'),
                ),
              );
              app.resetQuiz();
            },
            icon: const Icon(Icons.replay),
            label: const Text('Yanlışları Tekrarla'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              app.resetQuiz();
              Navigator.of(context).pop();
            },
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(BuildContext context, AppProvider app) {
    final theme = Theme.of(context);
    final q = app.currentQuizQuestion!;
    final progress = '${app.quizIndex + 1} / ${app.quizTotal}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            progress,
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (q.type == QuizType.meaning) ...[
                  Text(
                    '"${q.word.word}" ne demek?',
                    style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 22,
                          color: theme.colorScheme.onSurface,
                        ),
                  ),
                ] else ...[
                  Text(
                    'Cümleyi tamamla:',
                    style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    q.word.example.replaceAll(q.word.word, '______'),
                    style: theme.textTheme.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                        ),
                  ),
                ],
                const SizedBox(height: 32),
                ...q.options.asMap().entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        app.answerQuiz(e.key);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        ),
                      ),
                      child: Text(
                        e.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

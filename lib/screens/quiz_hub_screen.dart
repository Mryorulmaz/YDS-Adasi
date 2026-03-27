import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/services/ad_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/glass_container.dart';
import '../providers/app_provider.dart';
import 'quiz_screen.dart';

/// 3 quiz kartı alt alta; kullanıcı basıp çözer. Günlük sıfırlanır. 4+ için reklam.
class QuizHubScreen extends StatelessWidget {
  const QuizHubScreen({super.key});

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
            if (app.learningCount < 2) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
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
                        'Quiz için en az 2 kelime öğrenmelisin',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            final isPremium = app.isPremium;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tekrar kelimelerinden günlük quizler',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(app.totalQuizSlots, (i) {
                    final score = app.getQuizSlotScore(i);
                    final isDone = score != null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _QuizCard(
                        slotIndex: i + 1,
                        score: score,
                        isDone: isDone,
                        enabled: !isDone || isPremium,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          app.startQuizForSlot(i);
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => QuizScreen(slotIndex: i),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                    );
                  }),
                  if (isPremium)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _QuizCard(
                        slotIndex: app.totalQuizSlots + 1,
                        score: null,
                        isDone: false,
                        enabled: true,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          final newIndex = app.totalQuizSlots;
                          app.startQuizForSlot(newIndex);
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => QuizScreen(slotIndex: newIndex),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _AdQuizCard(
                        onTap: () async {
                          HapticFeedback.selectionClick();
                          await AdService.instance.showRewarded(
                            onRewarded: () {
                              app.addBonusQuizSlot();
                            },
                          );
                        },
                        isDark: isDark,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({
    required this.slotIndex,
    required this.score,
    required this.isDone,
    required this.enabled,
    required this.onTap,
    required this.isDark,
  });

  final int slotIndex;
  final int? score;
  final bool isDone;
  final bool enabled;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$slotIndex',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quiz $slotIndex',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isDone ? 'Tamamlandı $score/10' : '10 soru • Başla',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        if (!isDone)
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 18,
            color: theme.colorScheme.primary,
          ),
        if (isDone)
          Icon(
            Icons.check_circle_rounded,
            size: 28,
            color: AppColors.success,
          ),
      ],
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: isDark
            ? GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Opacity(opacity: isDone ? 0.8 : 1, child: content),
              )
            : Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Opacity(opacity: isDone ? 0.8 : 1, child: content),
              ),
      ),
    );
  }
}

class _AdQuizCard extends StatelessWidget {
  const _AdQuizCard({required this.onTap, required this.isDark});

  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(Icons.play_circle_outline_rounded, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1 reklam izle',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '+1 quiz hakkı aç',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios_rounded, size: 18, color: theme.colorScheme.primary),
      ],
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(color: theme.colorScheme.primary, width: 1.5),
          ),
          child: content,
        ),
      ),
    );
  }
}

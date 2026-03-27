import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/glass_container.dart';
import '../providers/app_provider.dart';
import 'card_learning_screen.dart';
import 'premium_screen.dart';
import 'vocabulary_list_screen.dart';

void _showResetDialog(BuildContext context, AppProvider app) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('İstatistikleri sıfırla'),
      content: const Text(
        'Tüm ilerleme, seri, öğrenilen kelimeler ve istatistikler silinecek. Bu işlem geri alınamaz. Devam edilsin mi?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.of(ctx).pop();
            await app.resetStatistics();
          },
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          child: const Text('Sıfırla'),
        ),
      ],
    ),
  );
}

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _requestReview(BuildContext context) async {
    final review = InAppReview.instance;
    final available = await review.isAvailable();
    if (!context.mounted) return;
    if (!available) {
      _toast(context, 'Mağaza incelemesi şu an kullanılamıyor.');
      return;
    }
    await review.requestReview();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          'İstatistik',
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
            if (app.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: theme.colorScheme.primary),
              );
            }
            return _buildStatsContent(context, app, isDark);
          },
        ),
      ),
    );
  }

  Widget _buildStatsContent(BuildContext context, AppProvider app, bool isDark) {
    final theme = Theme.of(context);
    const int totalTarget = 5000; // Hedef
    final vocabCount = app.vocabularyCount; // Biliyorum + Öğrenildi (Kelime Hazinem'e giren)
    final progress = (vocabCount / totalTarget).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _BigProgressCard(
              learned: vocabCount,
              total: totalTarget,
              progress: progress,
              isDark: isDark,
            ),
          ),
          _VocabularyCard(
            vocabularyCount: app.vocabularyCount,
            isDark: isDark,
            onTap: () {
              final words = app.getVocabularyWords();
              if (words.isEmpty) {
                _toast(context, 'Henüz Kelime Hazinem boş.');
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => VocabularyListScreen(words: words),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const SizedBox(height: 24),
          _StreakOrb(streak: app.streak, isDark: isDark),
          const SizedBox(height: 24),
          Text(
            'Başarılar',
            style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.trending_up_rounded,
                  title: 'Öğrenilen',
                  value: '${app.learnedCount}',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.today_rounded,
                  title: 'Bugün',
                  value: '${app.todayStudied}',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.quiz_rounded,
                  title: 'Quiz %',
                  value: app.lastQuizRatio > 0
                      ? '${(app.lastQuizRatio * 100).round()}'
                      : '—',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.star_rounded,
                  title: 'Favori',
                  value: '${app.favoriteCount}',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Son 7 gün',
            style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 16),
          _WeeklyChart(days: app.last7DaysActivity, isDark: isDark),
          const SizedBox(height: 24),
          _ActionCard(
            icon: Icons.star_rounded,
            title: 'Favori Kelimeler',
            subtitle: '${app.favoriteCount} kelime',
            color: AppColors.accent,
            isDark: isDark,
            onTap: () {
              if (app.favoriteWordIds.isEmpty) {
                _toast(context, 'Henüz favori kelimen yok.');
                return;
              }
              app.startSession(mode: 'favorites');
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CardLearningScreen(filterMode: 'favorites'),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          if (!app.isPremium)
            Padding(
              padding: const EdgeInsets.only(bottom: 0),
              child: _ActionCard(
                icon: Icons.workspace_premium_rounded,
                title: 'YDS ADASI PRO\'ya geç',
                subtitle: 'Sınırsız öğrenme, sınırsız quiz ve reklamsız deneyim',
                color: theme.colorScheme.primary,
                isDark: isDark,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const PremiumScreen()),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          isDark
              ? GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 84),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          color: theme.colorScheme.primary,
                          size: 26,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Günlük hatırlatma',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Bugünkü kelimelerin seni bekliyor!',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: app.notificationsEnabled,
                          onChanged: app.setNotificationsEnabled,
                          activeColor: AppColors.cyan400,
                        ),
                      ],
                    ),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 84),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          color: theme.colorScheme.primary,
                          size: 26,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Günlük hatırlatma',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Bugünkü kelimelerin seni bekliyor!',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: app.notificationsEnabled,
                          onChanged: app.setNotificationsEnabled,
                          activeColor: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
          const SizedBox(height: 8),
          _ActionCard(
            icon: Icons.rate_review_rounded,
            title: 'Uygulamayı değerlendir',
            subtitle: 'Mağazada puan ver, bize destek ol',
            color: theme.colorScheme.primary,
            isDark: isDark,
            onTap: () => _requestReview(context),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _showResetDialog(context, app),
            icon: Icon(
              Icons.restart_alt_rounded,
              size: 20,
              color: theme.colorScheme.error,
            ),
            label: Text(
              'İstatistikleri sıfırla',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _BigProgressCard extends StatelessWidget {
  const _BigProgressCard({
    required this.learned,
    required this.total,
    required this.progress,
    required this.isDark,
  });

  final int learned;
  final int total;
  final double progress;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '5000 kelime hedefi',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '$learned / $total',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.progressTrackRadius),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: isDark
                  ? AppColors.navy700
                  : theme.colorScheme.primary.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppColors.cyan400 : theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
    return isDark
        ? GlassContainer(padding: EdgeInsets.zero, child: content)
        : Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              boxShadow: AppTheme.cardShadow,
            ),
            child: content,
          );
  }
}

class _VocabularyCard extends StatelessWidget {
  const _VocabularyCard({
    required this.vocabularyCount,
    required this.isDark,
    required this.onTap,
  });

  final int vocabularyCount;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 32,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kelime Hazinem',
                  style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            size: 28,
          ),
        ],
      ),
    );
    final card = isDark
        ? GlassContainer(padding: EdgeInsets.zero, child: content)
        : Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              boxShadow: AppTheme.cardShadow,
            ),
            child: content,
          );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: card,
      ),
    );
  }
}

class _StreakOrb extends StatelessWidget {
  const _StreakOrb({required this.streak, required this.isDark});

  final int streak;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        width: 108,
        height: 108,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.cyan400.withValues(alpha: 0.4),
                    AppColors.accent.withValues(alpha: 0.5),
                  ],
                )
              : null,
          color: isDark ? null : AppColors.accent.withValues(alpha: 0.15),
          boxShadow: [
            if (isDark)
              BoxShadow(
                color: AppColors.cyan400.withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 0,
              )
            else
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              size: 32,
              color: isDark ? AppColors.cyan300 : AppColors.accent,
            ),
            const SizedBox(height: 4),
            Text(
              '$streak',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              'gün seri',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 28),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
    if (isDark) {
      return GlassContainer(
        padding: const EdgeInsets.all(20),
        child: content,
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: content,
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.days, required this.isDark});

  static const int _maxWords = 25;
  static const double _maxBarHeight = 72.0;

  final List<({String date, int count})> days;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ordered = days.toList().reversed.toList();
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: ordered.map((d) {
        final label = d.date.length >= 10 ? d.date.substring(8, 10) : d.date;
        final countForBar = d.count > _maxWords ? _maxWords : d.count;
        final height = (countForBar / _maxWords).clamp(0.0, 1.0) * _maxBarHeight;
        final barHeight = height.clamp(4.0, _maxBarHeight);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${d.count}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 28,
              height: barHeight,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        );
      }).toList(),
    );
    if (isDark) {
      return GlassContainer(
        padding: const EdgeInsets.all(24),
        child: child,
      );
    }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: child,
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ],
    );
    if (isDark) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: GlassContainer(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 84),
              child: content,
            ),
          ),
        ),
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            boxShadow: AppTheme.cardShadow,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 84),
            child: content,
          ),
        ),
      ),
    );
  }
}

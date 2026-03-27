import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../core/services/ad_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/scale_tap.dart';
import '../providers/app_provider.dart';
import 'card_learning_screen.dart';
import 'premium_screen.dart';
import 'quiz_hub_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ConfettiController _confettiController;
  int _beforeSessionTodayKnown = 0;
  int _beforeSessionLearned = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    // Kelimeler MainShell açılışında bir kez yüklenir; liste boşsa (örn. reset sonrası) yeniden yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppProvider>();
      if (app.allWords.isEmpty && !app.isLoading) app.loadWords();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _openCards(String? filterMode) {
    final app = context.read<AppProvider>();
    if (filterMode == null && app.isDailyLimitReached) return;
    _beforeSessionTodayKnown = app.todayKnownCount;
    _beforeSessionLearned = app.learnedCount;
    app.startSession(mode: filterMode);
    Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CardLearningScreen(filterMode: filterMode),
      ),
    ).then((value) {
      if (!mounted) return;
      final ap = context.read<AppProvider>();
      if (ap.todayKnownCount > _beforeSessionTodayKnown ||
          ap.learnedCount > _beforeSessionLearned) {
        _confettiController.play();
      }
      if (value == true) _showMiniQuizDialog(context);
    });
  }

  void _openQuiz(BuildContext context, AppProvider app) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const QuizHubScreen()),
    );
  }

  void _showMiniQuizDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mini quiz'),
        content: const Text(
          '20 kelime çalıştın! Mini quiz ile pekiştirmek ister misin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Sonra'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _openQuiz(context, context.read<AppProvider>());
            },
            child: const Text('Quiz\'e git'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Consumer<AppProvider>(
          builder: (context, app, _) {
            if (app.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: theme.colorScheme.primary),
              );
            }
            final progress = app.todayTarget > 0
                ? (app.todayStudied / app.todayTarget).clamp(0.0, 1.0)
                : 0.0;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  _buildStatsHub(context, app, progress, isDark),
                  const SizedBox(height: 28),
                  _buildStartButton(context, theme, app),
                  const SizedBox(height: 24),
                  _buildBentoGrid(context, app, theme, isDark),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi,
              emissionFrequency: 0.05,
              numberOfParticles: 12,
              maxBlastForce: 15,
              minBlastForce: 8,
              gravity: 0.15,
              colors: const [
                Color(0xFF1F8AA6),
                Color(0xFF22D3EE),
                Color(0xFFFF7A00),
                Color(0xFF10B981),
              ],
              shouldLoop: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHub(
    BuildContext context,
    AppProvider app,
    double progress,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    Widget statChip(String label, String value, IconData icon) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ],
      );
    }

    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.progressTrackRadius),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: isDark
                ? AppColors.navy700
                : theme.colorScheme.primary.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? AppColors.cyan400 : theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Bugün ${app.todayStudied}/${app.todayTarget} kelime çalışıldı',
          style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                fontSize: 14,
              ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            statChip('Seri', '${app.streak} gün', Icons.local_fire_department_rounded),
            statChip('Biliyorum', '${app.mainKnownUnlearnedCount}', Icons.check_circle_rounded),
            statChip('Öğrenildi', '${app.learnedCount}', Icons.trending_up_rounded),
          ],
        ),
      ],
    );

    if (isDark) {
      return GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: child,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: child,
    );
  }

  Widget _buildBentoGrid(
    BuildContext context,
    AppProvider app,
    ThemeData theme,
    bool isDark,
  ) {
    Widget card({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      final content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              size: 24,
            ),
          ],
        ),
      );
      return ScaleTap(
        onTap: onTap,
        child: isDark
            ? GlassContainer(padding: EdgeInsets.zero, child: content)
            : Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: content,
              ),
      );
    }

    return Column(
      children: [
        card(
          icon: Icons.autorenew_rounded, // 🔁 circular arrows
          title: 'Tekrarla',
          subtitle: 'Öğrenmek istediğin kelimeler',
          onTap: () {
            HapticFeedback.selectionClick();
            _openCards('learning');
          },
        ),
        const SizedBox(height: 12),
        card(
          icon: Icons.help_outline_rounded, // ❓ question mark
          title: 'Quiz',
          subtitle: 'Bilmediğin kelimelerden sorular',
          onTap: () => _openQuiz(context, app),
        ),
        if (!app.isPremium) ...[
          const SizedBox(height: 12),
          card(
            icon: Icons.star_rounded, // ⭐ pro badge
            title: 'YDS ADASI PRO',
            subtitle: 'Sınırsız öğrenme ve quiz, reklamsız deneyim',
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PremiumScreen()),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildStartButton(BuildContext context, ThemeData theme, AppProvider app) {
    final isDark = theme.brightness == Brightness.dark;
    final limitReached = app.isDailyLimitReached && !app.isPremium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        limitReached
            ? ScaleTap(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const PremiumScreen()),
                  );
                },
                child: Opacity(
                  opacity: 0.5,
                  child: Container(
                    height: AppTheme.buttonHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? AppColors.cyan400 : theme.colorScheme.primary)
                              .withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      'Bugünkü limit doldu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              )
            : ScaleTap(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _openCards(null);
                },
                child: Container(
                  height: AppTheme.buttonHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? AppColors.cyan400 : theme.colorScheme.primary)
                            .withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    'Öğrenmeye Başla',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
        if (limitReached) ...[
          const SizedBox(height: 12),
          Shimmer.fromColors(
            baseColor: theme.colorScheme.primary.withValues(alpha: 0.3),
            highlightColor: theme.colorScheme.primary.withValues(alpha: 0.6),
            period: const Duration(milliseconds: 2000),
            loop: 0,
            child: ScaleTap(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PremiumScreen()),
                );
              },
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: theme.colorScheme.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'YDS ADASI PRO ile sınırsız öğren',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Shimmer.fromColors(
            baseColor: theme.colorScheme.primary.withValues(alpha: 0.3),
            highlightColor: theme.colorScheme.primary.withValues(alpha: 0.6),
            period: const Duration(milliseconds: 2000),
            loop: 0,
            child: ScaleTap(
              onTap: () async {
                HapticFeedback.selectionClick();
                await AdService.instance.showRewarded(
                  onRewarded: () {
                    if (!context.mounted) return;
                    final ap = context.read<AppProvider>();
                    ap.recordRewardedAdWatched();
                    ap.grantBonusWords(10);
                  },
                );
              },
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_outline_rounded, color: theme.colorScheme.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '1 reklam izle, +10 kelime hakkı',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

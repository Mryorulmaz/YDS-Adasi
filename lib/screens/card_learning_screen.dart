import 'dart:math' as math;

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/services/ad_service.dart';
import '../core/widgets/ad_break_overlay.dart';
import '../core/theme/app_theme.dart';
import '../core/services/tts_service.dart';
import '../data/academic_meaning_fallback.dart';
import '../data/models/word_model.dart';
import '../providers/app_provider.dart';

class CardLearningScreen extends StatefulWidget {
  const CardLearningScreen({super.key, this.filterMode});

  final String? filterMode;

  @override
  State<CardLearningScreen> createState() => _CardLearningScreenState();
}

class _CardLearningScreenState extends State<CardLearningScreen> {
  bool _isFront = true;
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _bannerAd = AdService.instance.buildBannerAd()..load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppProvider>();
      if (app.currentDeck.isEmpty && !app.isLoading) {
        _maybePop();
      }
    });
  }

  Future<void> _onSwipe(AppProvider app, VoidCallback swipe) async {
    swipe();
    if (app.isPremium || app.todayRewardedAdCount >= 2) return;
    if (app.sessionStudiedCount == 10 || app.sessionStudiedCount == 20) {
      if (!mounted) return;
      await _showAdBreakOverlay();
      if (!mounted) return;
      AdService.instance.showInterstitial();
    }
  }

  Future<void> _showAdBreakOverlay() async {
    final ctx = context;
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (c) => const AdBreakOverlay(),
    );
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!ctx.mounted) return;
    Navigator.of(ctx).pop();
  }

  void _maybePop() {
    if (mounted) Navigator.of(context).pop();
  }

  void _speak(String text) {
    if (text.isEmpty) return;
    final tts = TtsService();
    tts.init().then((_) => tts.speak(text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Kelime Kartı',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
          style: IconButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: Selector<AppProvider, WordModel?>(
          selector: (_, a) => a.currentWord,
          builder: (context, word, _) {
            final app = context.read<AppProvider>();
            if (word == null) {
              return _buildEmpty(app, theme);
            }
            return Column(
              children: [
                Selector<AppProvider, int>(
                  selector: (_, a) => a.todayKnownCount,
                  builder: (_, todayKnown, __) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Bugün Biliyorum: $todayKnown',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 420),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Selector<AppProvider, bool>(
                          selector: (_, a) => a.isFavorite,
                          builder: (_, isFav, __) => RepaintBoundary(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 160),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                final slide = Tween<Offset>(
                                  begin: const Offset(0.04, 0),
                                  end: Offset.zero,
                                ).animate(animation);
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(position: slide, child: child),
                                );
                              },
                              child: _SwipeableCard(
                                key: ValueKey<String>(word.id),
                                word: word,
                                isFront: _isFront,
                                isFavorite: isFav,
                                onSwipeLeft: () {
                                  HapticFeedback.mediumImpact();
                                  setState(() => _isFront = true);
                                  _onSwipe(app, app.swipeLeft);
                                },
                                onSwipeRight: () {
                                  HapticFeedback.mediumImpact();
                                  setState(() => _isFront = true);
                                  _onSwipe(app, app.swipeRight);
                                },
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _isFront = !_isFront);
                                },
                                onFavorite: () {
                                  HapticFeedback.selectionClick();
                                  app.toggleFavorite();
                                },
                                onPronounce: () => _speak(word.word),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildActions(app, theme),
                const SizedBox(height: 20),
                Selector<AppProvider, bool>(
                  selector: (_, a) => a.isPremium,
                  builder: (_, isPremium, __) {
                    if (_bannerAd == null || isPremium) return const SizedBox(height: 12);
                    return Column(
                      children: [
                        Container(
                          alignment: Alignment.center,
                          width: _bannerAd!.size.width.toDouble(),
                          height: _bannerAd!.size.height.toDouble(),
                          child: AdWidget(ad: _bannerAd!),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty(AppProvider app, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 56,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bu turda kart kalmadı',
              style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    color: theme.colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Bugün ${app.todayStudied} kelime çalıştın.',
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () async {
                if (!app.isPremium && app.todayRewardedAdCount < 2 && app.sessionStudiedCount > 0) {
                  await _showAdBreakOverlay();
                  if (!mounted) return;
                  AdService.instance.showInterstitial();
                }
                if (!mounted) return;
                Navigator.of(context).pop(app.sessionStudiedCount >= 20);
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                ),
              ),
              child: const Text('Ana sayfaya dön'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(AppProvider app, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionPill(
            icon: Icons.replay_rounded,
            label: 'Tekrarla',
            color: AppColors.reviewOrange,
            glowColor: Colors.orange,
            onPressed: () {
              HapticFeedback.mediumImpact();
              setState(() => _isFront = true);
              _onSwipe(app, app.swipeLeft);
            },
          ),
          _ActionPill(
            icon: Icons.volume_up_rounded,
            label: 'Telaffuz',
            color: theme.colorScheme.primary,
            glowColor: theme.colorScheme.primary,
            onPressed: () {
              HapticFeedback.selectionClick();
              _speak(app.currentWord?.word ?? '');
            },
          ),
          _ActionPill(
            icon: Icons.check_rounded,
            label: 'Biliyorum',
            color: AppColors.success,
            glowColor: Colors.green,
            onPressed: () {
              HapticFeedback.mediumImpact();
              setState(() => _isFront = true);
              _onSwipe(app, app.swipeRight);
            },
          ),
        ],
      ),
    );
  }
}

class _SwipeableCard extends StatefulWidget {
  const _SwipeableCard({
    super.key,
    required this.word,
    required this.isFront,
    required this.isFavorite,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onTap,
    required this.onFavorite,
    required this.onPronounce,
  });

  final WordModel word;
  final bool isFront;
  final bool isFavorite;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onPronounce;

  @override
  State<_SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<_SwipeableCard> with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _drag = ValueNotifier<double>(0);
  late final AnimationController _dragController;
  Animation<double>? _dragAnimation;
  bool _swipeTriggered = false;
  /// Yeşil/turuncu görünür (offset > 20) olduğunda parmağı bırakınca geçer; az kaydırma yeter.
  static const double _swipeThreshold = 70;
  static const double _velocityThreshold = 400;
  static const double _minDragForVelocity = 40;
  static const double _maxOffset = 260;
  static const Duration _snapDuration = Duration(milliseconds: 140);

  @override
  void initState() {
    super.initState();
    _dragController = AnimationController(vsync: this, duration: _snapDuration)
      ..addListener(() {
        final a = _dragAnimation;
        if (a != null) _drag.value = a.value;
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
          if (_swipeTriggered) {
            _swipeTriggered = false;
            // Animasyon bitince callback tetikle, sonra offset’i sıfırla
            // (yeni kart merkezde başlar)
            // Callback tek sefer çalışsın diye bu noktada çağırıyoruz.
          }
          _dragAnimation = null;
        }
      });
  }

  @override
  void dispose() {
    _dragController.dispose();
    _drag.dispose();
    super.dispose();
  }

  void _animateDragTo(double target, {VoidCallback? onCompleted}) {
    _dragController.stop();
    _dragController.reset();
    _dragAnimation = Tween<double>(begin: _drag.value, end: target).animate(
      CurvedAnimation(parent: _dragController, curve: Curves.easeOutCubic),
    );
    _dragController.forward().whenComplete(() {
      onCompleted?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (_) {
        if (_dragController.isAnimating) return;
        _drag.value = 0;
      },
      onHorizontalDragUpdate: (d) {
        if (_dragController.isAnimating) return;
        _drag.value += d.delta.dx;
      },
      onHorizontalDragEnd: (d) {
        if (_dragController.isAnimating) return;
        final v = d.primaryVelocity ?? 0;
        final drag = _drag.value;
        final useVelocity = drag.abs() >= _minDragForVelocity;
        final rightByDrag = drag >= _swipeThreshold;
        final rightByVelocity = useVelocity && v >= _velocityThreshold;
        final leftByDrag = drag <= -_swipeThreshold;
        final leftByVelocity = useVelocity && v <= -_velocityThreshold;
        if (rightByDrag || rightByVelocity) {
          _swipeTriggered = true;
          _animateDragTo(_maxOffset, onCompleted: () {
            widget.onSwipeRight();
            _drag.value = 0;
          });
          return;
        }
        if (leftByDrag || leftByVelocity) {
          _swipeTriggered = true;
          _animateDragTo(-_maxOffset, onCompleted: () {
            widget.onSwipeLeft();
            _drag.value = 0;
          });
          return;
        }
        // Eşik aşılmadıysa yumuşak şekilde merkeze dön
        _animateDragTo(0);
      },
      child: ValueListenableBuilder<double>(
        valueListenable: _drag,
        child: GestureDetector(
          onTap: widget.onTap,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: widget.isFront ? 0 : 1),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOut,
            builder: (context, value, _) {
              final angle = value * math.pi;
              final isBack = angle > math.pi / 2;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: isBack
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(math.pi),
                        child: _buildBack(context),
                      )
                    : _buildFront(context),
              );
            },
          ),
        ),
        builder: (context, offset, child) {
          final angle = (offset / 400) * 0.3;
          final dragOpacity = (offset.abs() / _swipeThreshold).clamp(0.0, 1.0) * 0.85;
          final showRight = offset > 20;
          final showLeft = offset < -20;
          return Transform.translate(
            offset: Offset(offset.clamp(-_maxOffset, _maxOffset), 0),
            child: Transform.rotate(
              angle: angle.clamp(-0.2, 0.2),
              child: Stack(
                children: [
                  child!,
                  if (showRight && dragOpacity > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 100),
                          opacity: dragOpacity,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppTheme.cardRadiusLarge),
                              color: AppColors.success.withValues(alpha: 0.35),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    color: Colors.white, size: 48),
                                const SizedBox(width: 12),
                                Text(
                                  'Biliyorum',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (showLeft && dragOpacity > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 100),
                          opacity: dragOpacity,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppTheme.cardRadiusLarge),
                              color: AppColors.reviewOrange.withValues(alpha: 0.4),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.replay_rounded,
                                    color: Colors.white, size: 48),
                                const SizedBox(width: 12),
                                Text(
                                  'Tekrarla',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFront(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadiusLarge),
        border: isDark ? Border.all(color: AppColors.glassBorder, width: 1) : null,
        boxShadow: [
          ...AppTheme.cardShadowStrong,
          if (isDark)
            BoxShadow(
              color: AppColors.cyan400.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.word.word,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.word.level != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.word.level!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: Icon(
                widget.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: widget.isFavorite ? AppColors.accent : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                size: 26,
              ),
              onPressed: widget.onFavorite,
              tooltip: widget.isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadiusLarge),
        border: isDark ? Border.all(color: AppColors.glassBorder, width: 1) : null,
        boxShadow: AppTheme.cardShadowStrong,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.word.word,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              getDisplayMeaning(widget.word.word, widget.word.meaning),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            if (widget.word.level != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.word.level!,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              'Örnek',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.word.example,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.word.exampleTr,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionPill extends StatefulWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.color,
    this.glowColor,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color? glowColor;
  final VoidCallback onPressed;

  static const double _size = 44;

  @override
  State<_ActionPill> createState() => _ActionPillState();
}

class _ActionPillState extends State<_ActionPill> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = widget.glowColor ?? widget.color;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          onTap: widget.onPressed,
          child: AnimatedBuilder(
            animation: _scale,
            builder: (_, child) => Transform.scale(
              scale: _scale.value,
              child: child,
            ),
            child: Container(
              width: _ActionPill._size,
              height: _ActionPill._size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: glow.withValues(alpha: 0.35),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(widget.icon, color: widget.color, size: 22),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

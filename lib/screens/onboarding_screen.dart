import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/theme/app_theme.dart';
import 'main_shell.dart';

const String _onboardingBox = 'app_stats';
const String _onboardingKey = 'onboardingDone';

Future<bool> isOnboardingDone() async {
  if (!Hive.isBoxOpen(_onboardingBox)) return false;
  final value = Hive.box<dynamic>(_onboardingBox).get(_onboardingKey);
  return value == true;
}

Future<void> setOnboardingDone() async {
  if (!Hive.isBoxOpen(_onboardingBox)) await Hive.openBox<dynamic>(_onboardingBox);
  await Hive.box<dynamic>(_onboardingBox).put(_onboardingKey, true);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  static const List<({String title, String subtitle})> _pages = [
    (title: '5000+ YDS / YÖKDİL kelimesi', subtitle: 'Güncel sınav kelimeleri ile hedefe ulaş.'),
    (title: 'Kartları kaydırarak ilerle', subtitle: ''),
    (title: 'Her gün çalış, serini koru', subtitle: 'Günlük seri ile motivasyonunu yüksek tut.'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      HapticFeedback.selectionClick();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _page++);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    await setOnboardingDone();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.background;
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceMuted = theme.colorScheme.onSurface.withValues(alpha: 0.75);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pages.length,
                onPageChanged: (p) => setState(() => _page = p),
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (index == 1)
                          _buildSwipeHint(primaryColor, onSurfaceMuted)
                        else if (index == 0)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/images/book_icon_master.png',
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 80,
                            color: primaryColor,
                          ),
                        const SizedBox(height: 32),
                        Text(
                          item.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                                fontSize: 24,
                                color: onSurface,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        if (item.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            item.subtitle,
                            style: theme.textTheme.bodyLarge?.copyWith(
                                  color: onSurfaceMuted,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page == i ? primaryColor : onSurfaceMuted.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                  ),
                ),
                child: Text(_page == _pages.length - 1 ? 'Başla' : 'İleri'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeHint(Color primaryColor, Color muted) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.swipe_rounded, size: 64, color: primaryColor),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Icon(Icons.arrow_back_rounded, color: AppColors.reviewOrange, size: 28),
                const SizedBox(height: 8),
                Text('Sola kaydır', style: TextStyle(fontSize: 14, color: muted)),
                const SizedBox(height: 4),
                Text('Tekrarla', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.reviewOrange)),
              ],
            ),
            const SizedBox(width: 40),
            Column(
              children: [
                Icon(Icons.arrow_forward_rounded, color: AppColors.success, size: 28),
                const SizedBox(height: 8),
                Text('Sağa kaydır', style: TextStyle(fontSize: 14, color: muted)),
                const SizedBox(height: 4),
                Text('Biliyorum', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.success)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

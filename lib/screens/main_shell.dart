import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/app_provider.dart';
import 'home_screen.dart';
import 'stats_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final PageController _pageController;

  static const List<Widget> _screens = [
    HomeScreen(),
    StatsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    // Kelime verisi uygulama açılışında bir kez yüklensin (main thread’i kilitlememek için repo compute kullanıyor)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppProvider>().loadWords();
    });
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              children: _screens,
            ),
          ),
          _FloatingTabBar(
            currentIndex: _currentIndex,
            onTap: (i) {
              HapticFeedback.selectionClick();
              setState(() => _currentIndex = i);
              _pageController.animateToPage(
                i,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

const List<({IconData icon, IconData iconActive, String label})> _tabItems = [
  (icon: Icons.school_outlined, iconActive: Icons.school_rounded, label: 'Öğren'),
  (icon: Icons.bar_chart_outlined, iconActive: Icons.bar_chart_rounded, label: 'İstatistik'),
];

class _FloatingTabBar extends StatelessWidget {
  const _FloatingTabBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.glassWhite : AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: isDark ? Border.all(color: AppColors.glassBorder, width: 1) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / _tabItems.length;
            const pillPadding = 4.0;
            final pillWidth = tabWidth - pillPadding * 2;
            const pillHeight = 48.0;
            final pillLeft = currentIndex * tabWidth + pillPadding;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  left: pillLeft,
                  top: 10,
                  child: Container(
                    width: pillWidth,
                    height: pillHeight,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(
                        alpha: isDark ? 0.25 : 0.15,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    _tabItems.length,
                    (i) {
                      final t = _tabItems[i];
                      final isActive = i == currentIndex;
                      return Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => onTap(i),
                            borderRadius: BorderRadius.circular(24),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      isActive ? t.iconActive : t.icon,
                                      key: ValueKey('$isActive$i'),
                                      size: 24,
                                      color: isActive
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                      color: isActive
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                    child: Text(t.label),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/app_provider.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';

const String _statsBoxName = 'app_stats';

/// İlk açılışta onboarding / ana shell seçimi. Kelimeler uygulama başında bir kez yüklenir (main thread kilitlenmez).
class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  late final Future<bool> _onboardingFuture = _checkOnboarding();

  Future<bool> _checkOnboarding() async {
    if (!Hive.isBoxOpen(_statsBoxName)) {
      await Hive.openBox<dynamic>(_statsBoxName);
    }
    try {
      return await isOnboardingDone();
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _onboardingFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        if (!snapshot.data!) {
          return const OnboardingScreen();
        }
        return _InitialDataLoader(child: const MainShell());
      },
    );
  }
}

/// Kelime listesini uygulama başında bir kez yükler; sonra ana shell gösterilir (performans için).
class _InitialDataLoader extends StatefulWidget {
  const _InitialDataLoader({required this.child});

  final Widget child;

  @override
  State<_InitialDataLoader> createState() => _InitialDataLoaderState();
}

class _InitialDataLoaderState extends State<_InitialDataLoader> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    await context.read<AppProvider>().loadWords();
    if (!mounted) return;
    setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return widget.child;
  }
}

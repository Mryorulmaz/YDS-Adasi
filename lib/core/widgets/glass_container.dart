import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 2026 glassmorphism – cam efekti, yumuşak köşeler
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.blur = 12,
    this.sigma = 24,
    this.color,
    this.borderWidth = 1,
    this.padding,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final double blur;
  final double sigma;
  final Color? color;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(AppTheme.cardRadius);
    final fillColor = color ??
        (isDark ? AppColors.glassWhite : Colors.white.withValues(alpha: 0.85));
    final borderColor =
        isDark ? AppColors.glassBorder : Colors.white.withValues(alpha: 0.4);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: radius,
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: child,
        ),
      ),
    );
  }
}

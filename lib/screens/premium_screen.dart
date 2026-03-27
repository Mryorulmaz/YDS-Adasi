import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_theme.dart';
import '../core/services/iap_service.dart';
import '../core/widgets/scale_tap.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  String? _selectedId = 'ydsadasi_premium_yearly';

  static const String _privacyUrl = 'https://mryorulmaz.github.io/privacy.html';
  static const String _eulaUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

  static const List<String> _planOrder = [
    'ydsadasi_premium_monthly',
    'ydsadasi_premium_3months',
    'ydsadasi_premium_yearly',
  ];

  static const Map<String, ({String title, int months, String periodLabel})> _planMeta = {
    'ydsadasi_premium_monthly': (title: 'PRO Aylık', months: 1, periodLabel: 'Aylık'),
    'ydsadasi_premium_3months': (title: 'PRO 3 Aylık', months: 3, periodLabel: '3 Aylık'),
    'ydsadasi_premium_yearly': (title: 'PRO Yıllık', months: 12, periodLabel: 'Yıllık'),
  };

  static const Map<String, String> _fallbackMainPrice = {
    'ydsadasi_premium_yearly': '299,99 TL',
    'ydsadasi_premium_3months': '99,99 TL',
    'ydsadasi_premium_monthly': '49,99 TL',
  };

  String _formatTry(double amount) {
    final s = amount.toStringAsFixed(2).replaceAll('.', ',');
    return '₺$s';
  }

  String _monthlyEquivalent(ProductDetails p) {
    final meta = _planMeta[p.id];
    final months = meta?.months ?? 1;
    final perMonth = (p.rawPrice / months);
    return 'Sadece ${_formatTry(perMonth)} / ay';
  }

  String _periodPrice(ProductDetails p) {
    return p.price;
  }

  String _periodLabelFor(String productId) {
    return _planMeta[productId]?.periodLabel ?? '';
  }

  String _legalText() {
    final base =
        '3 günlük ücretsiz deneme süresinin sonunda seçtiğiniz plan üzerinden aboneliğiniz otomatik olarak ücretli hale gelir ve bir sonraki dönem için yenilenir. '
        'Ücret, belirtilen tutar üzerinden otomatik olarak tahsil edilir. '
        'Aboneliğin otomatik yenilenmesini, ücretsiz deneme bitmeden önce istediğiniz zaman mağaza abonelik ayarlarından kapatabilirsiniz.';

    if (Platform.isIOS) {
      return '$base Ödeme, onaylandığında Apple Kimliği hesabınıza bağlı ödeme yönteminden tahsil edilir. '
          'Aboneliğinizi cihazınızın Ayarlar > Apple Kimliği > Abonelikler bölümünden yönetebilir veya iptal edebilirsiniz.';
    }
    if (Platform.isAndroid) {
      return '$base Ödeme, onaylandığında Google Play hesabınızdan tahsil edilir. '
          'Aboneliğinizi Google Play Abonelikler bölümünden yönetebilir veya iptal edebilirsiniz.';
    }
    return base;
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bağlantı açılamadı. Lütfen daha sonra tekrar deneyin.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.background;
    final onSurface = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final onSurfaceMuted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final linkStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'PRO',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Consumer<IapService>(
          builder: (context, iap, _) {
            final products = iap.products;
            final canPurchase = !iap.purchasePending;
            final selectedId = _selectedId ?? _planOrder.last;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sınırları Kaldırın, Sınavı Kazanın!',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '5000+ Akademik Kelime ve Sınırsız Quiz ile YDS Hedefinize Ulaşın.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: onSurfaceMuted,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      _FeatureChip(
                        icon: Icons.all_inclusive_rounded,
                        title: 'Sınırsız Öğrenmeye Başlayın',
                        subtitle:
                            'Günlük kelime barajına takılmadan tüm arşive anında erişin.',
                      ),
                      SizedBox(height: 14),
                      _FeatureChip(
                        icon: Icons.quiz_rounded,
                        title: 'Sınırsız Quiz ve Deneme',
                        subtitle:
                            'Kendinizi test edin; sınırsız quiz ve deneme sınavı ile seviyenizi ölçün.',
                      ),
                      SizedBox(height: 14),
                      _FeatureChip(
                        icon: Icons.block_rounded,
                        title: 'Kesintisiz Odaklanın',
                        subtitle:
                            'Reklamları tamamen kaldırın, sadece başarıya odaklanın.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  ..._planOrder.map((id) {
                    final meta = _planMeta[id]!;
                    final product =
                        products.where((x) => x.id == id).toList().cast<ProductDetails?>().firstWhere(
                              (p) => p != null,
                              orElse: () => null,
                            );
                    final mainPrice = product != null
                        ? _periodPrice(product)
                        : (_fallbackMainPrice[id] ?? '—');
                    final isSelected = selectedId == id;
                    final primary = theme.colorScheme.primary;
                    final onSurfaceColor = theme.colorScheme.onSurface;
                    final borderColor =
                        isDark ? AppColors.glassBorder : Colors.black12;
                    final bgColor = isDark ? AppColors.glassWhite : AppColors.surface;
                    final periodLabel = _periodLabelFor(id);
                    final billedText = '3 gün ücretsiz deneme, sonra $mainPrice / $periodLabel';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor, width: 1),
                          boxShadow: isDark ? null : AppTheme.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    meta.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: onSurfaceColor,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: primary.withValues(alpha: isSelected ? 0.9 : 0.6),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '3 gün deneme',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: onSurfaceColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              mainPrice,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: onSurfaceColor,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Süre: ${meta.periodLabel}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: onSurfaceColor.withValues(alpha: 0.75),
                                height: 1.25,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              billedText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: onSurfaceColor.withValues(alpha: 0.9),
                                height: 1.25,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Builder(
                              builder: (context) {
                                final canTap = !iap.purchasePending;
                                final button = Container(
                                  height: AppTheme.buttonHeight * 0.6,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius:
                                        BorderRadius.circular(AppTheme.buttonRadius),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    iap.purchasePending
                                        ? 'İşlem devam ediyor...'
                                        : 'YDS ADASI PRO’YA ŞİMDİ BAŞLA',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                );

                                if (!canTap) {
                                  return Opacity(
                                    opacity: 0.7,
                                    child: button,
                                  );
                                }

                                return ScaleTap(
                                  onTap: () async {
                                    setState(() {
                                      _selectedId = id;
                                    });

                                    if (!iap.available || products.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Mağaza bağlantısı kurulamadı. Lütfen daha sonra tekrar deneyin.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    final selectedProduct = products.firstWhere(
                                      (p) => p.id == id,
                                      orElse: () => products.first,
                                    );
                                    await context.read<IapService>().buy(selectedProduct);
                                  },
                                  child: button,
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              runAlignment: WrapAlignment.center,
                              spacing: 12,
                              children: [
                                GestureDetector(
                                  onTap: () => _openExternalUrl(_privacyUrl),
                                  child: Text('Gizlilik Politikası', style: linkStyle),
                                ),
                                GestureDetector(
                                  onTap: () => _openExternalUrl(_eulaUrl),
                                  child: Text('Kullanım Şartları (EULA)', style: linkStyle),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 6),
                  if (iap.lastError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        iap.lastError!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    _legalText(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onSurfaceMuted,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: iap.available ? () => context.read<IapService>().restore() : null,
                    child: const Text('Satın alımları geri yükle'),
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

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassWhite : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: isDark ? Border.all(color: AppColors.glassBorder) : null,
        boxShadow: isDark ? null : AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.monthly,
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.isDark,
    required this.primary,
    required this.onSurface,
    required this.onSurfaceMuted,
  });

  final String title;
  final String price;
  final String? monthly;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final bool isDark;
  final Color primary;
  final Color onSurface;
  final Color onSurfaceMuted;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? primary : (isDark ? AppColors.glassBorder : Colors.black12);
    final bg = selected
        ? primary.withValues(alpha: isDark ? 0.16 : 0.07)
        : (isDark ? AppColors.glassWhite : AppColors.surface);

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: selected ? 1.6 : 1),
              boxShadow: selected && !isDark
                  ? [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : (isDark ? null : AppTheme.cardShadow),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '3 Gün Ücretsiz Deneme Dahil',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: selected ? primary : onSurfaceMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                if (monthly != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    monthly!,
                    style: TextStyle(
                      fontSize: 11,
                      color: onSurfaceMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Mağaza tarafında tanımlanacak ürün ID'leri.
///
/// Not: 3 günlük ücretsiz deneme, **ayrı bir ürün değil**; her abonelik paketinin
/// (base plan / offer) içinde mağaza üzerinden tanımlanır.
const Set<String> kPremiumProductIds = {
  'ydsadasi_premium_monthly',
  'ydsadasi_premium_3months',
  'ydsadasi_premium_yearly',
};

class IapService extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool _available = false;
  bool _loading = false;
  bool _purchasePending = false;
  String? _lastError;

  List<ProductDetails> _products = [];
  final Set<String> _activeProductIds = {};

  bool get available => _available;
  bool get isLoading => _loading;
  bool get purchasePending => _purchasePending;
  String? get lastError => _lastError;
  List<ProductDetails> get products => List.unmodifiable(_products);

  /// Basit entitlement: aktif ürünlerden biri varsa Premium kabul edilir.
  ///
  /// Üretim ortamında en sağlam yöntem, sunucu tarafı receipt doğrulaması + expiry kontrolüdür.
  bool get isPremium => _activeProductIds.isNotEmpty;

  Future<void> init() async {
    if (_sub != null) return;
    _loading = true;
    notifyListeners();

    _available = await _iap.isAvailable();
    if (!_available) {
      _loading = false;
      notifyListeners();
      return;
    }

    _sub = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object e) {
        _lastError = e.toString();
        _purchasePending = false;
        notifyListeners();
      },
    );

    await refreshProducts();
    await restore();

    _loading = false;
    notifyListeners();
  }

  Future<void> refreshProducts() async {
    if (!_available) return;
    _loading = true;
    notifyListeners();

    final resp = await _iap.queryProductDetails(kPremiumProductIds);
    if (resp.error != null) {
      _lastError = resp.error!.message;
      _products = [];
    } else {
      _lastError = null;
      _products = resp.productDetails..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> buy(ProductDetails product) async {
    if (!_available) return;
    _lastError = null;
    _purchasePending = true;
    notifyListeners();

    final param = PurchaseParam(productDetails: product);
    // Abonelikler için buyNonConsumable kullanılır.
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    if (!_available) return;
    _lastError = null;
    await _iap.restorePurchases();
  }

  void _onPurchaseUpdates(List<PurchaseDetails> purchases) {
    var anyPending = false;
    for (final p in purchases) {
      if (!kPremiumProductIds.contains(p.productID)) continue;

      switch (p.status) {
        case PurchaseStatus.pending:
          anyPending = true;
          break;
        case PurchaseStatus.error:
          _lastError = p.error?.message ?? 'Satın alma hatası';
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // MVP doğrulama: ürün ID var mı? (Sunucu doğrulaması önerilir.)
          _activeProductIds.add(p.productID);
          break;
        case PurchaseStatus.canceled:
          // iOS/Android bazı sürümlerde gelebilir.
          _lastError = 'İşlem iptal edildi';
          break;
      }

      if (p.pendingCompletePurchase) {
        _iap.completePurchase(p);
      }
    }

    _purchasePending = anyPending;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _sub = null;
    super.dispose();
  }
}


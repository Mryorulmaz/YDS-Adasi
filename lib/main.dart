import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/services/ad_service.dart';
import 'core/services/iap_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/app_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await MobileAds.instance.initialize();
  await AdService.instance.initialize();
  runApp(const YdsApp());
}

class YdsApp extends StatelessWidget {
  const YdsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => IapService()..init()),
        ChangeNotifierProxyProvider<IapService, AppProvider>(
          create: (_) => AppProvider(),
          update: (_, iap, app) {
            app ??= AppProvider();
            app.setPremium(iap.isPremium);
            return app;
          },
        ),
      ],
      child: MaterialApp(
        title: 'YDS ADASI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: const AppLoader(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stitch/widgets/navigation.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'providers/pdf_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/help_us/help_us_screen.dart';
import 'screens/select_pdf/select_pdf_screen.dart';
import 'screens/success/success_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/upgrade/upgrade_screen.dart';
import 'screens/split_pdf/split_pdf_screen.dart';
import 'screens/help_support/help_support_screen.dart';
import 'services/ad_service.dart';

import 'services/billing_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService.instance.initialize();
  await BillingService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PdfProvider()),
        ChangeNotifierProvider.value(value: BillingService.instance),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getLightTheme(),
          darkTheme: AppTheme.getDarkTheme(),
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          initialRoute: '/',
          routes: {
            '/': (context) => const NavigationPage(),
            '/home': (context) => const HomeScreen(),
            '/help-us': (context) => const HelpUsScreen(),
            '/select-pdf': (context) => const SelectPdfScreen(),
            '/success': (context) => const SuccessScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/upgrade': (context) => const UpgradeScreen(),
            '/split-pdf': (context) => const SplitPdfScreen(),
            '/help-support': (context) => const HelpSupportScreen(),
          },
        );
      },
    );
  }
}

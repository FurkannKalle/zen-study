import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // PlatformDispatcher için gerekli
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'providers/question_provider.dart';
import 'screens/onboarding/exam_selection_page.dart';
import 'screens/onboarding/onboarding_page.dart';
import 'screens/main_layout.dart';
import 'package:home_widget/home_widget.dart';
import 'services/notification_service.dart';
import 'providers/theme_provider.dart';
import 'providers/streak_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final initialExam = prefs.getString('selectedExam');
  final bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

  await NotificationService.instance.init();
  NotificationService.instance.requestPermissions(); // İzin isteği arka planda başlatılır
  
  await HomeWidget.setAppGroupId('group.zen');
  final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
  final bool launchedFromWidget = initialUri?.toString() == 'zen://focus';

  // UI (RenderFlex vb.) çökmelerini güvenle yakalayarak Sentry'ye postalar
  FlutterError.onError = (FlutterErrorDetails details) {
    Sentry.captureException(details.exception, stackTrace: details.stack);
  };

  // Asenkron ve platform altındaki sinsi Dart çökmelerini (Offline kilitlenme korumalı) yakalar
  PlatformDispatcher.instance.onError = (error, stack) {
    Sentry.captureException(error, stackTrace: stack);
    return true;
  };

  // Sentry Mimarisi: Hatalar, uygulamanın (Zen) arayüzünü karartmadan sessiz raporlanır
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://0b06009f6e32ec97955f01320fd67744@o4512180252508160.ingest.de.sentry.io/4512180254933072';
      options.tracesSampleRate = 1.0;
      options.reportSilentFlutterErrors = true; // Offline anında çökmez
    },
    appRunner: () => runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => QuestionProvider()
            ..loadUserExam()
            ..loadDueQuestions()
            ..loadAllQuestions()
          ),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => StreakProvider()),
        ],
        child: SoruTakipApp(
          initialExam: initialExam, 
          isFirstTime: isFirstTime,
          launchedFromWidget: launchedFromWidget,
        ),
      ),
    ),
  );
}

class SoruTakipApp extends StatelessWidget {
  final String? initialExam;
  final bool isFirstTime;
  final bool launchedFromWidget;
  const SoruTakipApp({
    super.key, 
    this.initialExam, 
    required this.isFirstTime,
    this.launchedFromWidget = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Soru Takip Zen',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          locale: const Locale('tr', 'TR'),
          supportedLocales: const [
            Locale('tr', 'TR'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: isFirstTime 
                ? const OnboardingPage() 
                : (initialExam == null ? const ExamSelectionPage() : MainLayout(initialIndex: launchedFromWidget ? 1 : 0)),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:predator/l10n/app_localizations.dart';
import 'core/theme.dart';
import 'services/incident_provider.dart';
import 'screens/splash/splash_screen.dart';

/// Set to true to run without Firebase (demo/preview mode)
const bool kDemoMode = true;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  if (!kDemoMode) {
    // Initialize Firebase only in production
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  runApp(const PredatorApp());
}

class PredatorApp extends StatelessWidget {
  const PredatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => IncidentProvider(),
      child: MaterialApp(
        title: 'Predator',
        debugShowCheckedModeBanner: false,
        theme: PredatorTheme.lightTheme,
        darkTheme: PredatorTheme.darkTheme,
        themeMode: ThemeMode.system,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('fr'),
          Locale('it'),
          Locale('es'),
          Locale('de'),
        ],
        home: const SplashScreen(),
      ),
    );
  }
}

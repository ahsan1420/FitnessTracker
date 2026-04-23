import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app_settings.dart';
import 'app_theme.dart';
import 'firebase_options.dart';
import 'splashscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AppSettings.load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        final settings = snapshot.data!;

        return AnimatedBuilder(
          animation: settings,
          builder: (context, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
              home: SplashScreen(settings: settings),
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/filter_provider.dart';
import 'screens/quiz_screen.dart';
import 'services/share_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => QuizProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(
          create: (context) {
            final filterProvider = FilterProvider();
            // Initialize the provider to load persisted filters
            filterProvider.initialize();
            return filterProvider;
          },
        ),
        Provider(create: (context) => ShareService()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          // Define the light theme
          final lightTheme = ThemeData(
              primaryColor: Colors.blue.shade800,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFF0F4F8));

          // Define the standard dark theme
          final darkTheme = ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          );

          // Define the OLED dark theme (true black)
          final oledDarkTheme = darkTheme.copyWith(
            scaffoldBackgroundColor: Colors.black,
            // You might want to adjust other colors for better contrast on black
            cardColor: const Color(0xFF121212), // A very dark grey for cards
          );

          return MaterialApp(
            title: 'xSAT',
            theme: lightTheme,
            darkTheme: settingsProvider.isOledMode ? oledDarkTheme : darkTheme,
            themeMode: settingsProvider.themeMode,
            debugShowCheckedModeBanner: false,
            home: const QuizScreen(),
          );
        },
      ),
    );
  }
}

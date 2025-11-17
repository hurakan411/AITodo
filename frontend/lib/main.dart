import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'src/screens/contract_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/profile_screen.dart';
import 'src/screens/game_over_screen.dart';
import 'src/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.init();
  final consent = storage.getConsentAccepted();
  runApp(ProviderScope(overrides: [
    initialConsentProvider.overrideWithValue(consent),
    storageServiceProvider.overrideWithValue(storage),
  ], child: const ObeyApp()));
}

final initialConsentProvider = Provider<bool>((ref) => false);

class ObeyApp extends ConsumerWidget {
  const ObeyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consent = ref.watch(initialConsentProvider);

    final router = GoRouter(
      initialLocation: consent ? '/home' : '/contract',
      routes: [
        GoRoute(path: '/contract', builder: (c, s) => const ContractScreen()),
        GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
        GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
        GoRoute(path: '/gameover', builder: (c, s) => const GameOverScreen()),
      ],
    );

    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFFFFF), // 純白
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF000000), // 純黒
        secondary: Color(0xFFEEEEEE), // 極薄グレー
        surface: Color(0xFFFFFFFF),
        surfaceContainerHighest: Color(0xFFFAFAFA),
        error: Color(0xFF000000),
        onPrimary: Colors.white,
        onSurface: Color(0xFF000000),
        onSurfaceVariant: Color(0xFF888888),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Color(0xFF000000),
          fontSize: 56,
          fontWeight: FontWeight.w200,
          letterSpacing: -2,
          height: 1.0,
        ),
        displayMedium: TextStyle(
          color: Color(0xFF000000),
          fontSize: 36,
          fontWeight: FontWeight.w200,
          letterSpacing: -1,
          height: 1.1,
        ),
        titleLarge: TextStyle(
          color: Color(0xFF000000),
          fontSize: 18,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          color: Color(0xFF000000),
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          height: 1.5,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF000000),
          fontSize: 15,
          fontWeight: FontWeight.w300,
          letterSpacing: 0,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF666666),
          fontSize: 13,
          fontWeight: FontWeight.w300,
          letterSpacing: 0,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          color: Color(0xFF000000),
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF000000),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF000000),
          fontSize: 11,
          fontWeight: FontWeight.w400,
          letterSpacing: 3,
        ),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFFFFFFFF),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(
            color: Color(0xFFDDDDDD),
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF000000),
          foregroundColor: const Color(0xFFFFFFFF),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          textStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            letterSpacing: 2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF000000),
          side: const BorderSide(color: Color(0xFF000000), width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          textStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            letterSpacing: 2,
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFFAFAFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFFDDDDDD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFFDDDDDD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFF000000), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      ),
      dividerColor: const Color(0xFFEEEEEE),
    );

    return MaterialApp.router(
      title: 'Obey',
      theme: theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

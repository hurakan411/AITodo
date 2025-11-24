import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'src/screens/contract_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/profile_screen.dart';
import 'src/screens/game_over_screen.dart';
import 'src/services/storage_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Warning: .env file not found: $e');
  }
  
  // Initialize Supabase
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty && supabaseUrl != 'your_supabase_url_here') {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  } else {
    print('Warning: Supabase URL or Anon Key not provided or invalid. Supabase features will not work.');
  }

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
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFE8EAF0),
      fontFamily: GoogleFonts.poppins().fontFamily,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6B7FD7), // Soft blue-purple
        secondary: Color(0xFFA8B4E5),
        surface: Color(0xFFE8EAF0),
        surfaceContainerHighest: Color(0xFFD8DAE5),
        error: Color(0xFFE57373),
        onPrimary: Colors.white,
        onSurface: Color(0xFF2D3142),
        onSurfaceVariant: Color(0xFF8E92AB),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Color(0xFF2D3142),
          fontSize: 32,
          fontWeight: FontWeight.w300,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          color: Color(0xFF2D3142),
          fontSize: 24,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          color: Color(0xFF2D3142),
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          color: Color(0xFF4A4E6D),
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF4A4E6D),
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF8E92AB),
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          color: Color(0xFF4A4E6D),
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFE8EAF0),
        foregroundColor: Color(0xFF2D3142),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFF2D3142),
          fontSize: 18,
          fontWeight: FontWeight.w400,
          letterSpacing: 2,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFE8EAF0),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE8EAF0),
          foregroundColor: const Color(0xFF6B7FD7),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF6B7FD7),
          side: BorderSide.none,
          backgroundColor: const Color(0xFFE8EAF0),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.25,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFE8EAF0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6B7FD7), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dividerColor: const Color(0xFFD8DAE5),
    );

    return MaterialApp.router(
      title: 'Obey',
      theme: theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/core.dart';
import 'screens/screens.dart';
import 'screens/auth_screen.dart';
import 'models/models.dart';
import 'services/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<String>('sync_queue');
  await AppSettings.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ColorScheme appScheme = ColorScheme(
      brightness: Brightness.light,
      primary: BrandPalette.teal,
      onPrimary: Colors.white,
      secondary: BrandPalette.sun,
      onSecondary: BrandPalette.ink,
      error: Color(0xFFB5413E),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: BrandPalette.ink,
    );

    return MaterialApp(
      title: 'ERP Bill Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: appScheme,
        scaffoldBackgroundColor: BrandPalette.pageBase,
        textTheme: appTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white.withValues(alpha: 0.82),
          foregroundColor: BrandPalette.navy,
          elevation: 0,
          titleTextStyle: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: BrandPalette.navy,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.9),
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: BrandPalette.navy.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.82),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          hintStyle: TextStyle(color: BrandPalette.ink.withValues(alpha: 0.55)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: BrandPalette.navy.withValues(alpha: 0.2),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: BrandPalette.navy.withValues(alpha: 0.16),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: BrandPalette.teal, width: 1.5),
          ),
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: Colors.transparent,
          selectedIconTheme: const IconThemeData(color: BrandPalette.sun),
          unselectedIconTheme: IconThemeData(
            color: Colors.white.withValues(alpha: 0.74),
          ),
          selectedLabelTextStyle: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelTextStyle: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.74),
            fontWeight: FontWeight.w600,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          labelTextStyle: WidgetStatePropertyAll(
            GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
          ),
          indicatorColor: BrandPalette.teal.withValues(alpha: 0.2),
          backgroundColor: Colors.white.withValues(alpha: 0.88),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: BrandPalette.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            textStyle: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: BrandPalette.navy,
            side: BorderSide(color: BrandPalette.navy.withValues(alpha: 0.25)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      home: const BootScreen(),
    );
  }
}

class BootScreen extends StatefulWidget {
  const BootScreen({super.key});
  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final token = await ApiService.getToken();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (token != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const PlatformShell()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AuthScreen()),
          );
        }
      });
    } catch (e) {
      debugPrint("Auth Init Error: $e");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: BrandPalette.teal),
      ),
    );
  }
}

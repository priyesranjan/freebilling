import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../enums/enums.dart';

bool isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String formatDate(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String formatDateTime(DateTime date) {
  final String hour = date.hour.toString().padLeft(2, '0');
  final String minute = date.minute.toString().padLeft(2, '0');
  return '${formatDate(date)} $hour:$minute';
}

const String kTwoFactorApiKey = String.fromEnvironment('TWO_FACTOR_API_KEY');

const String kTwoFactorTemplateName = String.fromEnvironment(
  'TWO_FACTOR_TEMPLATE',
);

String? normalizeIndianPhoneNumber(String input) {
  final String digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length == 10) {
    return '91$digits';
  }

  if (digits.length == 12 && digits.startsWith('91')) {
    return digits;
  }

  return null;
}

String formatIndianPhoneForDisplay(String normalizedPhone) {
  if (normalizedPhone.length == 12 && normalizedPhone.startsWith('91')) {
    return '+91 ${normalizedPhone.substring(2)}';
  }

  return normalizedPhone;
}

class BrandPalette {
  static const Color pageBase = Color(0xFFF6F5EE);
  static const Color ink = Color(0xFF162027);
  static const Color navy = Color(0xFF14344A);
  static const Color teal = Color(0xFF1F8A86);
  static const Color sun = Color(0xFFF1B15C);
  static const Color coral = Color(0xFFE97A63);
  static const Color mint = Color(0xFFBEE5D8);
}

TextTheme appTextTheme() {
  final TextTheme base = GoogleFonts.dmSansTextTheme();
  return base.copyWith(
    displaySmall: GoogleFonts.sora(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      height: 1.05,
      color: BrandPalette.navy,
    ),
    headlineMedium: GoogleFonts.sora(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.15,
      color: BrandPalette.navy,
    ),
    titleLarge: GoogleFonts.spaceGrotesk(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: BrandPalette.ink,
    ),
    titleMedium: GoogleFonts.spaceGrotesk(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: BrandPalette.ink,
    ),
    bodyLarge: GoogleFonts.dmSans(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: BrandPalette.ink,
      height: 1.45,
    ),
    bodyMedium: GoogleFonts.dmSans(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: BrandPalette.ink,
      height: 1.4,
    ),
  );
}

typedef AddBusinessCallback =
    void Function({
      required String businessName,
      required String ownerName,
      required BillingPlan plan,
    });

typedef AddProductCallback =
    String? Function({
      required String name,
      required double price,
      required List<String> codes,
    });

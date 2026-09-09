import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system de las apps (ver docs/20 Tecnico/Design System de las apps).
/// Estilo Vibrant & block-based: naranja de marca + azul de confianza.
abstract final class AppColors {
  static const Color primary = Color(0xFFEA580C);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFFF97316);
  static const Color accent = Color(0xFF2563EB);
  static const Color background = Color(0xFFFFF7ED);
  static const Color foreground = Color(0xFF0F172A);
  static const Color muted = Color(0xFFFDF4F0);
  static const Color border = Color(0xFFFCEAE1);
  static const Color destructive = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color surface = Color(0xFFFFFFFF);
}

/// Colores por estado de pedido (coherentes con el backend).
Color orderStatusColor(String status) {
  switch (status) {
    case 'PENDING':
      return AppColors.primary;
    case 'ACCEPTED':
      return AppColors.accent;
    case 'PICKED_UP':
      return AppColors.secondary;
    case 'DELIVERED':
      return AppColors.success;
    case 'CANCELLED':
      return AppColors.destructive;
    default:
      return AppColors.foreground;
  }
}

/// Labels legibles por estado.
String orderStatusLabel(String status) {
  switch (status) {
    case 'PENDING':
      return 'Pendiente';
    case 'ACCEPTED':
      return 'Aceptado';
    case 'PICKED_UP':
      return 'Recogido';
    case 'DELIVERED':
      return 'Entregado';
    case 'CANCELLED':
      return 'Cancelado';
    default:
      return status;
  }
}

ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: brightness,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.secondary,
    surface: AppColors.surface,
    error: AppColors.destructive,
  ).copyWith(
    tertiary: AppColors.accent,
    surface: AppColors.muted,
  );

  final base = ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
  );

  return base.copyWith(
    textTheme: GoogleFonts.karlaTextTheme(base.textTheme).copyWith(
      displaySmall: GoogleFonts.playfairDisplaySc(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.foreground,
      ),
      headlineSmall: GoogleFonts.playfairDisplaySc(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.foreground,
      ),
      titleLarge: GoogleFonts.karla(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.foreground,
      ),
      bodyMedium: GoogleFonts.karla(fontSize: 16, color: AppColors.foreground),
      bodySmall: GoogleFonts.karla(fontSize: 14, color: AppColors.foreground),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.karla(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 2),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.karla(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.destructive),
      ),
    ),
    cardTheme: CardTheme(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.muted,
      selectedColor: AppColors.primary.withOpacity(0.15),
      labelStyle: GoogleFonts.karla(fontSize: 14, color: AppColors.foreground),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withOpacity(0.15),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (_) => GoogleFonts.karla(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
  );
}

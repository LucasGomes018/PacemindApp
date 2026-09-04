import 'package:flutter/material.dart';

class AppColors {
  // Cores principais
  static const Color primary = Color(0xFF0066FF);
  static const Color primaryLight = Color(0xFF3385FF);
  static const Color accent = Color(0xFF00C6FF);

  // Gradientes
  static const LinearGradient cardGradient = LinearGradient(
    colors: [
      Color(0xFF0066FF),
      Color(0xFF00C6FF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [
      Color(0xFF1E293B),
      Color(0xFF0F172A),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===== Tema Claro =====
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;
  static const Color text = Color(0xFF0F172A);
  static const Color secondaryText = Color(0xFF64748B);

  // ===== Tema Escuro =====
  static const Color darkBackground = Color(0xFF0A0F1D);
  static const Color darkSurface = Color(0xFF161F33);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkText = Color(0xFFF8FAFC);
  static const Color darkSecondaryText = Color(0xFF94A3B8);
}

class AppTextStyles {
  static const title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const subtitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const body = TextStyle(
    fontSize: 16,
  );
}

class AppTheme {
  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        cardColor: AppColors.card,
        dividerColor: const Color(0xFFE2E8F0),
        extensions: const [
          AppCustomTheme(
            cardBackground: AppColors.card,
            cardShadow: Color(0x14000000),
            avatarBackground: Color(0xFFEBF5FF),
            avatarIcon: AppColors.primary,
            sectionTitle: Color(0xFF1A237E),
            subtitleText: AppColors.secondaryText,
          ),
        ],
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          onSurface: AppColors.text,
          onPrimary: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.text,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(AppColors.primary),
          trackColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: .30)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.darkBackground,
        cardColor: AppColors.darkCard,
        dividerColor: const Color(0xFF334155),
        extensions: const [
          AppCustomTheme(
            cardBackground: AppColors.darkCard,
            cardShadow: Color(0x4D000000),
            avatarBackground: Color(0xFF1E3A8A),
            avatarIcon: Color(0xFF60A5FA),
            sectionTitle: Color(0xFF64B5F6),
            subtitleText: AppColors.darkSecondaryText,
          ),
        ],
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkText,
          onPrimary: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: AppColors.darkBackground,
          foregroundColor: AppColors.darkText,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(AppColors.primary),
          trackColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: .40)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      );
}

@immutable
class AppCustomTheme extends ThemeExtension<AppCustomTheme> {
  final Color cardBackground;
  final Color cardShadow;
  final Color avatarBackground;
  final Color avatarIcon;
  final Color sectionTitle;
  final Color subtitleText;

  const AppCustomTheme({
    required this.cardBackground,
    required this.cardShadow,
    required this.avatarBackground,
    required this.avatarIcon,
    required this.sectionTitle,
    required this.subtitleText,
  });

  @override
  AppCustomTheme copyWith({
    Color? cardBackground,
    Color? cardShadow,
    Color? avatarBackground,
    Color? avatarIcon,
    Color? sectionTitle,
    Color? subtitleText,
  }) {
    return AppCustomTheme(
      cardBackground: cardBackground ?? this.cardBackground,
      cardShadow: cardShadow ?? this.cardShadow,
      avatarBackground: avatarBackground ?? this.avatarBackground,
      avatarIcon: avatarIcon ?? this.avatarIcon,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      subtitleText: subtitleText ?? this.subtitleText,
    );
  }

  @override
  AppCustomTheme lerp(ThemeExtension<AppCustomTheme>? other, double t) {
    if (other is! AppCustomTheme) {
      return this;
    }
    return AppCustomTheme(
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t) ?? cardBackground,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t) ?? cardShadow,
      avatarBackground: Color.lerp(avatarBackground, other.avatarBackground, t) ?? avatarBackground,
      avatarIcon: Color.lerp(avatarIcon, other.avatarIcon, t) ?? avatarIcon,
      sectionTitle: Color.lerp(sectionTitle, other.sectionTitle, t) ?? sectionTitle,
      subtitleText: Color.lerp(subtitleText, other.subtitleText, t) ?? subtitleText,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppThemeType { amoledBlack, dark, light }

class ThemeState {
  final AppThemeType themeType;
  final Color accentColor;

  ThemeState({
    this.themeType = AppThemeType.amoledBlack,
    this.accentColor = const Color(0xFF007AFF), // Classic MX Blue
  });

  ThemeData get themeData {
    final isLight = themeType == AppThemeType.light;
    final isAmoled = themeType == AppThemeType.amoledBlack;

    final bgColor = isLight
        ? const Color(0xFFF7F8FA)
        : isAmoled
            ? Colors.black
            : const Color(0xFF161618);

    final surfaceColor = isLight
        ? Colors.white
        : isAmoled
            ? const Color(0xFF101010)
            : const Color(0xFF222225);

    return ThemeData(
      brightness: isLight ? Brightness.light : Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      primaryColor: accentColor,
      colorScheme: ColorScheme(
        brightness: isLight ? Brightness.light : Brightness.dark,
        primary: accentColor,
        onPrimary: Colors.white,
        secondary: accentColor,
        onSecondary: Colors.white,
        error: const Color(0xFFFF5252),
        onError: Colors.white,
        surface: surfaceColor,
        onSurface: isLight ? Colors.black87 : Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: isLight ? Colors.black87 : Colors.white),
        titleTextStyle: TextStyle(
          color: isLight ? Colors.black87 : Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardColor: surfaceColor,
      dividerColor: isLight ? const Color(0xFFE2E4E8) : const Color(0xFF2A2A2E),
    );
  }

  ThemeState copyWith({
    AppThemeType? themeType,
    Color? accentColor,
  }) {
    return ThemeState(
      themeType: themeType ?? this.themeType,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(ThemeState());

  void setThemeType(AppThemeType type) {
    state = state.copyWith(themeType: type);
  }

  void setAccentColor(Color color) {
    state = state.copyWith(accentColor: color);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});
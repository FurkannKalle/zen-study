import 'package:flutter/material.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get zenTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppConstants.backgroundZen,
      primaryColor: AppConstants.primaryAccent,
      
      // Font Family: Quicksand (Offline Local)
      fontFamily: 'Quicksand',
      textTheme: ThemeData.light().textTheme.copyWith(
        displayLarge: const TextStyle(fontFamily: 'Quicksand', color: AppConstants.textPrimary, fontWeight: FontWeight.bold),
        titleLarge: const TextStyle(fontFamily: 'Quicksand', color: AppConstants.textPrimary, fontWeight: FontWeight.w700),
        bodyLarge: const TextStyle(fontFamily: 'Quicksand', color: AppConstants.textPrimary),
        bodyMedium: const TextStyle(fontFamily: 'Quicksand', color: AppConstants.textSecondary),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppConstants.textPrimary,
        titleTextStyle: const TextStyle(
          fontFamily: 'Quicksand',
          color: AppConstants.textPrimary, 
          fontSize: 22, 
          fontWeight: FontWeight.w700
        ),
      ),
      
      cardTheme: CardThemeData(
        color: AppConstants.cardColor,
        elevation: 0, // Gölgelenmeyi manuel olarak Container'da daha yumuşak (soft shadow) ayarlıyoruz
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryAccent,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppConstants.primaryAccent.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Yumuşatılmış kenarlar
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontFamily: 'Quicksand', fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppConstants.primaryAccent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppConstants.secondaryAccent, width: 2),
        ),
        labelStyle: const TextStyle(color: AppConstants.textSecondary),
        hintStyle: const TextStyle(color: AppConstants.textSecondary),
      ),
    );
  }
}

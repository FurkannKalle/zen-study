import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themePrefKey = 'isDarkMode';
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadFromPrefs();
  }

  void _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themePrefKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePrefKey, _isDarkMode);
  }

  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF1A3626), // Koyu Orman Yeşili
      scaffoldBackgroundColor: const Color(0xFFF9F6F0), // Yulaf
      cardColor: const Color(0xFFFFFFFF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1A3626)),
      ),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1A3626),
        secondary: Color(0xFF8A9A5B), // Adaçayı
        surface: Color(0xFFF9F6F0),
        onPrimary: Color(0xFFF9F6F0),
        onSurface: Colors.black87,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF1A3626)),
      fontFamily: 'Quicksand',
      textTheme: ThemeData.light().textTheme.copyWith(
        bodyLarge: const TextStyle(fontFamily: 'Quicksand', color: Color(0xFF1A3626)),
        bodyMedium: const TextStyle(fontFamily: 'Quicksand', color: Color(0xFF1A3626)),
        titleLarge: const TextStyle(fontFamily: 'Quicksand', color: Color(0xFF1A3626), fontWeight: FontWeight.bold),
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFFF9F6F0), // Yulaf
      scaffoldBackgroundColor: const Color(0xFF0F1F16), // Gece Ormanı
      cardColor: const Color(0xFF183022), // Koyu Yeşilin bir tık açığı (Kartlar)
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFFF9F6F0)),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6B9A7B), // Pastel/Açık yeşil (Okunabilirlik için)
        secondary: Color(0xFF8A9A5B), 
        surface: Color(0xFF121212),
        onPrimary: Color(0xFF121212),
        onSurface: Color(0xFFF9F6F0),
      ),
      iconTheme: const IconThemeData(color: Color(0xFFF9F6F0)),
      fontFamily: 'Quicksand',
      textTheme: ThemeData.dark().textTheme.copyWith(
        bodyLarge: const TextStyle(fontFamily: 'Quicksand', color: Color(0xFFF9F6F0)),
        bodyMedium: const TextStyle(fontFamily: 'Quicksand', color: Color(0xFFF9F6F0)),
        titleLarge: const TextStyle(fontFamily: 'Quicksand', color: Color(0xFFF9F6F0), fontWeight: FontWeight.bold),
      ),
    );
  }
}

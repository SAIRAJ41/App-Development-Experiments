import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

//############################################################################
// 1. LUNARIS COLORS (STATIC COLORS)
//############################################################################

// --- DARK MODE COLORS ---
class LunarisColorsDark {
  static const Color backgroundStart = Color(0xFF0D0A1C); // Deep purple/blue
  static const Color backgroundEnd = Color(0xFF1A1438); // Darker purple/blue
  static const Color cardBackground = Color(0xFF1A1438); // Dark background for cards
  static const Color text = Colors.white;
  static const Color accentCyan = Color(0xFF00CBA7); // Brighter accent
  static const Color accentMagenta = Color(0xFFC700BA); // Deeper accent
}

// --- LIGHT MODE COLORS ---
class LunarisColorsLight {
  // --- UPDATED: Use solid sky blue colors ---
  static const Color backgroundStart = Color(0xFF87CEEB); // Sky Blue
  static const Color backgroundEnd = Color(0xFFADD8E6); // Lighter Sky Blue
  static const Color cardBackground = Color(0xFFFFFFFF); // White background for cards
  static const Color text = Color(0xFF333333); // Dark text
  static const Color accentViolet = Color(0xFF7B1FA2); // Deep violet accent
  static const Color accentMagenta = Color(0xFFC2185B); // Magenta accent
}


//############################################################################
// 2. THEME NOTIFIER (DYNAMIC THEME SWITCHING)
//############################################################################

// --- THEME DATA DEFINITIONS (MOVED OUTSIDE) ---
final ThemeData lunarisDarkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: LunarisColorsDark.backgroundStart,
  scaffoldBackgroundColor: LunarisColorsDark.backgroundStart, // Use a solid color
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: LunarisColorsDark.text),
    bodyMedium: TextStyle(color: LunarisColorsDark.text),
    bodySmall: TextStyle(color: LunarisColorsDark.text),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: LunarisColorsDark.accentCyan,
  ),
);

final ThemeData lunarisLightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: LunarisColorsLight.backgroundStart,
  scaffoldBackgroundColor: LunarisColorsLight.backgroundStart, // Use a solid color
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: LunarisColorsLight.text),
    bodyMedium: TextStyle(color: LunarisColorsLight.text),
    bodySmall: TextStyle(color: LunarisColorsLight.text),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: LunarisColorsLight.accentViolet,
  ),
);


class ThemeNotifier with ChangeNotifier {
  final SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system; // Default

  ThemeMode get themeMode => _themeMode;

  ThemeNotifier(this._prefs) {
    _loadThemeMode();
  }

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return; // No change
    _themeMode = mode;
    _saveThemeMode(_themeMode);
    notifyListeners();
  }

  void _loadThemeMode() {
    String? theme = _prefs.getString('themeMode');
    if (theme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (theme == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system; // Default to system theme
    }
    notifyListeners();
  }

  void _saveThemeMode(ThemeMode mode) {
    _prefs.setString('themeMode', mode.toString().split('.').last);
  }
}
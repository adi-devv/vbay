import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:vbay/theme/dark_mode.dart';
import 'package:vbay/theme/light_mode.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  final Box _settingsBox = Hive.box('settings');

  ThemeData _themeData;

  ThemeProvider() : _themeData = _loadTheme();

  static ThemeData _loadTheme() {
    final box = Hive.box('settings');
    bool isDark = box.get(_themeKey, defaultValue: false);
    print("Fetched theme from Hive: ${isDark ? 'Dark Mode' : 'Light Mode'}");

    return box.get(_themeKey, defaultValue: false) ? darkMode : lightMode;
  }

  ThemeData get themeData => _themeData;

  bool get isDarkMode => _themeData == darkMode;

  final Duration themeChangeDuration = const Duration(milliseconds: 300);

  set themeData(ThemeData themeData) {
    _themeData = themeData;
    _settingsBox.put(_themeKey, themeData == darkMode);
    notifyListeners();
  }

  void toggleTheme() {
    themeData = _themeData == lightMode ? darkMode : lightMode;
  }
}

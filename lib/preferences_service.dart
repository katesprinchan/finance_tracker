import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _keyTheme = 'theme';
  static const _keyLocale = 'locale';

  Future<void> saveTheme(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTheme, isDarkMode);
  }

  Future<bool> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTheme) ??
        false; // false by default for light theme
  }

  Future<void> saveLocale(int localeIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLocale, localeIndex);
  }

  Future<int> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLocale) ??
        0; // 0 by default for the first locale in the list
  }
}

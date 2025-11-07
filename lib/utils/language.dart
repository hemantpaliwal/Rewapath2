import 'package:shared_preferences/shared_preferences.dart';

class LanguageHelper {
  static bool isHindi = false;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    isHindi = prefs.getBool('isHindi') ?? false;
  }

  static Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    isHindi = !isHindi;
    await prefs.setBool('isHindi', isHindi);
  }

  static String t(String en, String hi) => isHindi ? hi : en;
}

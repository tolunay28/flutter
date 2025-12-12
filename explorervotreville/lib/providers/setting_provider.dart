import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _darkMode = false;
  bool get darkMode => _darkMode;

  // essayer plus tard de le suppr et voir si on en a besoin
  ThemeMode get themeMode => _darkMode ? ThemeMode.dark : ThemeMode.light;

  // Chargement des préférences sauvegardées
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Si aucune valeur n’existe, on reste en mode clair (false)
    _darkMode = prefs.getBool('darkMode') ?? false;

    notifyListeners();
  }

  /// Active / désactive le mode sombre

  Future<void> toggleDarkMode(bool value) async {
    _darkMode = value;

    notifyListeners();

    // Sauvegarde dans SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
  }
}

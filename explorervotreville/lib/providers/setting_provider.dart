import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/villes_meteo_api.dart';

class SettingsProvider extends ChangeNotifier {
  // theme
  bool _darkMode = false;
  bool get darkMode => _darkMode;
  ThemeMode get themeMode => _darkMode ? ThemeMode.dark : ThemeMode.light;

  //  ville par défaut + historique
  VilleResultat? _defaultCity; // dernière ville choisie
  VilleResultat? get defaultCity => _defaultCity;

  final List<VilleResultat> _recentCities = []; // dernières recherches
  List<VilleResultat> get recentCities => List.unmodifiable(_recentCities);

  // Clés SharedPreferences
  static const _kDarkMode = 'darkMode';
  static const _kDefaultCity = 'defaultCity'; // JSON ville
  static const _kRecentCities = 'recentCities'; // JSON list

  // À appeler au démarrage (dans main) pour charger les prefs
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // mode sombre
    _darkMode = prefs.getBool(_kDarkMode) ?? false;

    // ville par défaut
    final defaultJson = prefs.getString(_kDefaultCity);
    _defaultCity = defaultJson == null ? null : _villeFromJson(defaultJson);

    // dernières villes
    final recentList = prefs.getStringList(_kRecentCities) ?? [];
    _recentCities
      ..clear()
      ..addAll(recentList.map(_villeFromJson).whereType<VilleResultat>());

    notifyListeners();
  }

  // change la valeur de darkmode + sauvegarde
  Future<void> toggleDarkMode(bool value) async {
    _darkMode = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkMode, value);
  }

  // Enregistre la ville par défaut + la met aussi en tête de l’historique
  Future<void> setDefaultCity(VilleResultat ville) async {
    _defaultCity = ville;
    _pushRecent(ville); // on la met aussi dans l’historique
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDefaultCity, _villeToJson(ville));
    await prefs.setStringList(
      _kRecentCities,
      _recentCities.map(_villeToJson).toList(),
    );
  }

  // Ajoute une ville à l’historique (sans forcer default)
  Future<void> addRecentCity(VilleResultat ville) async {
    _pushRecent(ville);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kRecentCities,
      _recentCities.map(_villeToJson).toList(),
    );
  }

  // Vide l’historique
  Future<void> clearRecentCities() async {
    _recentCities.clear();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRecentCities);
  }

  //  Helpers JSON
  String _villeToJson(VilleResultat v) {
    final map = {
      'nom': v.nom,
      'pays': v.pays,
      'lat': v.lat,
      'lon': v.lon,
      'cle': v.cle, // très pratique
    };
    return jsonEncode(map);
  }

  VilleResultat? _villeFromJson(String s) {
    try {
      final map = jsonDecode(s) as Map<String, dynamic>;
      return VilleResultat(
        nom: map['nom'] as String,
        pays: map['pays'] as String,
        lat: (map['lat'] as num).toDouble(),
        lon: (map['lon'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  // Met la ville en tête, supprime doublon, limite taille
  void _pushRecent(VilleResultat ville) {
    _recentCities.removeWhere((v) => v.cle == ville.cle);
    _recentCities.insert(0, ville);

    const max = 5;
    // supprime entre max et .length
    if (_recentCities.length > max) {
      _recentCities.removeRange(max, _recentCities.length);
    }
  }
}

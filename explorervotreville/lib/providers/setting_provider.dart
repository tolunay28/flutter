import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/villes_meteo_api.dart';

class SettingsProvider extends ChangeNotifier {
  // theme
  bool _darkMode = false;
  bool get darkMode => _darkMode;
  ThemeMode get themeMode => _darkMode ? ThemeMode.dark : ThemeMode.light;

  //  ville par défaut (mise en avant)
  VilleResultat? _defaultCity; // dernière ville choisie
  VilleResultat? get defaultCity => _defaultCity;

  final List<VilleResultat> _favoriteCities = []; // favoris
  List<VilleResultat> get favoriteCities => List.unmodifiable(_favoriteCities);

  final List<VilleResultat> _recentCities = []; // dernières recherches
  List<VilleResultat> get recentCities => List.unmodifiable(_recentCities);

  // Clés SharedPreferences
  static const _kDarkMode = 'darkMode';
  static const _kDefaultCity = 'defaultCity'; // JSON ville
  static const _kFavoriteCities = 'favoriteCities'; // JSON list
  static const _kRecentCities = 'recentCities';

  // À appeler au démarrage (dans main) pour charger les prefs
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // mode sombre
    _darkMode = prefs.getBool(_kDarkMode) ?? false;

    // ville par défaut
    final defaultJson = prefs.getString(_kDefaultCity);
    _defaultCity = defaultJson == null ? null : _villeFromJson(defaultJson);

    // villes favorites
    final favList = prefs.getStringList(_kFavoriteCities) ?? [];
    _favoriteCities
      ..clear()
      ..addAll(favList.map(_villeFromJson).whereType<VilleResultat>());

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
  Future<void> setDefaultCity(VilleResultat? ville) async {
    _defaultCity = ville;
    if (ville != null) {
      _pushRecent(ville); // on la met aussi dans l’historique
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (ville == null) {
      await prefs.remove(_kDefaultCity);
    } else {
      await prefs.setString(_kDefaultCity, _villeToJson(ville));
    }
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

  // vide l’historique
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
    if (_favoriteCities.length > max) {
      _favoriteCities.removeRange(max, _favoriteCities.length);
    }
  }

  bool isFavoriteCity(VilleResultat ville) {
    return _favoriteCities.any((v) => v.cle == ville.cle);
  }

  Future<void> addFavoriteCity(VilleResultat ville) async {
    // évite doublon + met en tête
    _favoriteCities.removeWhere((v) => v.cle == ville.cle);
    _favoriteCities.insert(0, ville);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kFavoriteCities,
      _favoriteCities.map(_villeToJson).toList(),
    );
  }

  Future<void> removeFavoriteCity(VilleResultat ville) async {
    _favoriteCities.removeWhere((v) => v.cle == ville.cle);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kFavoriteCities,
      _favoriteCities.map(_villeToJson).toList(),
    );
  }

  // Remplace toute la liste d'un coup (pratique pour la page Favoris)
  Future<void> setFavoriteCities(List<VilleResultat> villes) async {
    _favoriteCities
      ..clear()
      ..addAll(villes);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kFavoriteCities,
      _favoriteCities.map(_villeToJson).toList(),
    );
  }
}

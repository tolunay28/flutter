import 'dart:convert';

import 'package:http/http.dart' as http;

/// Modèle pour une ville trouvée par l’API
class VilleResultat {
  final String nom;
  final String pays;
  final double lat;
  final double lon;

  VilleResultat({
    required this.nom,
    required this.pays,
    required this.lat,
    required this.lon,
  });

  String get cle => '$nom,$pays';

  factory VilleResultat.fromJson(Map<String, dynamic> json) {
    return VilleResultat(
      nom: json['name'] as String,
      pays: json['country'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }
}

/// Modèle pour la météo actuelle
class MeteoActuelle {
  final double temp;
  final double tempMin;
  final double tempMax;
  final String description;

  MeteoActuelle({
    required this.temp,
    required this.tempMin,
    required this.tempMax,
    required this.description,
  });
}

/// Service qui appelle OpenWeatherMap pour les villes et la météo
class VillesMeteoApi {
  static const String _apiKey = '5cbb00d4d5cacab55abc01536c30f740';

  final http.Client _client;

  VillesMeteoApi({http.Client? client}) : _client = client ?? http.Client();

  /// Recherche des villes par nom (géocodage direct)
  Future<List<VilleResultat>> rechercherVilles(String nomVille) async {
    final uri = Uri.https('api.openweathermap.org', '/geo/1.0/direct', {
      'q': nomVille,
      'limit': '5',
      'appid': _apiKey,
    });

    final resp = await _client.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Erreur API ville (${resp.statusCode})');
    }

    final data = jsonDecode(resp.body) as List<dynamic>;
    return data
        .map((e) => VilleResultat.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Météo actuelle pour une ville (par latitude / longitude)
  Future<MeteoActuelle> getMeteoPourVille(VilleResultat ville) async {
    final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
      'lat': ville.lat.toString(),
      'lon': ville.lon.toString(),
      'appid': _apiKey,
      'units': 'metric',
      'lang': 'fr',
    });

    final resp = await _client.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Erreur API météo (${resp.statusCode})');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final main = data['main'] as Map<String, dynamic>;
    final weatherList = data['weather'] as List<dynamic>;
    final weather = weatherList.isNotEmpty
        ? weatherList.first as Map<String, dynamic>
        : {};

    return MeteoActuelle(
      temp: (main['temp'] as num).toDouble(),
      tempMin: (main['temp_min'] as num).toDouble(),
      tempMax: (main['temp_max'] as num).toDouble(),
      description: (weather['description'] as String?) ?? 'Temps inconnu',
    );
  }
}

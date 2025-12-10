import 'dart:convert';

import 'package:explorervotreville/services/villes_meteo_api.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class AdresseResultat {
  final LatLng coordonnees;
  final String displayName;

  AdresseResultat({required this.coordonnees, required this.displayName});
}

class Map_api {
  // 1. Gérer la permission et récupérer la position GPS actuelle
  Future<LatLng?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Le service de localisation est désactivé.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permission de localisation refusée.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permission de localisation bloquée définitivement.');
    }

    // Si tout est bon, on récupère la position
    Position position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  // 2. Transformer un nom de ville en coordonnées (Nominatim)
  Future<LatLng?> getCoordinatesFromCity(String city) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$city&format=json&limit=1',
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'FlutterApp'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          return LatLng(lat, lon);
        }
      }
      return null; // Pas trouvé
    } catch (e) {
      throw Exception("Erreur lors de la recherche de coordonnées : $e");
    }
  }

  Future<AdresseResultat?> chercherAdresse(
    String query,
    VilleResultat ville,
  ) async {
    final fullQuery = "$query, ${ville.nom}, ${ville.pays}";
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent(fullQuery)}'
      '&format=json&limit=1',
    ); // q = param de recherche (la ville), encode... encode correctement les espaces,accents etc

    final response = await http.get(
      url,
      headers: {'User-Agent': 'ExplorezVotreVille/1.0 (akkayatoto@gmail.com)'},
    );

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as List<dynamic>;
    if (data.isEmpty) return null;

    final first = data.first as Map<String, dynamic>;
    final lat = double.tryParse(first['lat'] as String? ?? '');
    final lon = double.tryParse(first['lon'] as String? ?? '');
    final displayName = first['display_name'] as String? ?? query;

    if (lat == null || lon == null) return null;

    return AdresseResultat(
      coordonnees: LatLng(lat, lon),
      displayName: displayName,
    );
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/lieu.dart';

// overpass pour récupérer les lieux de l'api
class OverpassApi {
  final http.Client _client;
  OverpassApi({http.Client? client}) : _client = client ?? http.Client();

  // mapping catégorie en tag overpass
  static const Map<String, Map<String, String>> _categoryToTag = {
    'Musée': {'tourism': 'museum'},
    'Parc': {'leisure': 'park'},
    'Monument': {'historic': 'monument'},
    'Restaurant': {'amenity': 'restaurant'},
    'Bar': {'amenity': 'bar'},
    'Cinéma': {'amenity': 'cinema'},
    'Théâtre': {'amenity': 'theatre'},
    'Salle de concert': {'amenity': 'music_venue'},
    'Stade': {'leisure': 'stadium'},
    'Shopping': {'shop': 'mall'},
    'Point de vue': {'tourism': 'viewpoint'},
    'Autre': {'amenity': 'cafe'},
  }; // amenity = service accessible au public

  Future<List<Lieu>> rechercherLieuxAutour({
    required LatLng center,
    required int radiusMeters,
    required String categorie,
    required String cleVille,
  }) async {
    final tag = _categoryToTag[categorie] ?? _categoryToTag['Autre']!;
    final k = tag.keys.first;
    final v = tag.values.first;

    // Overpass query: nodes + ways + relations autour d’un point
    final query =
        '''
[out:json][timeout:25];
(
  node["$k"="$v"](around:$radiusMeters,${center.latitude},${center.longitude});
  way["$k"="$v"](around:$radiusMeters,${center.latitude},${center.longitude});
  relation["$k"="$v"](around:$radiusMeters,${center.latitude},${center.longitude});
);
out center 40;
''';

    final uri = Uri.parse('https://overpass-api.de/api/interpreter');

    final resp = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'User-Agent': 'ExplorezVotreVille/1.0',
      },
      body: 'data=${Uri.encodeComponent(query)}',
    );

    if (resp.statusCode != 200) {
      throw Exception('Overpass error ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final elements = (data['elements'] as List<dynamic>? ?? []);

    final lieux = <Lieu>[];

    for (final e in elements) {
      final el = e as Map<String, dynamic>;
      final tags = (el['tags'] as Map<String, dynamic>?) ?? {};

      final name = (tags['name'] as String?)?.trim();
      if (name == null || name.isEmpty) continue;

      // coords: node -> lat/lon, way/relation -> center.lat/center.lon
      double? lat = (el['lat'] as num?)?.toDouble();
      double? lon = (el['lon'] as num?)?.toDouble();

      final centerMap = el['center'] as Map<String, dynamic>?;
      lat ??= (centerMap?['lat'] as num?)?.toDouble();
      lon ??= (centerMap?['lon'] as num?)?.toDouble();

      final adresse = _formatAdresse(tags);

      lieux.add(
        Lieu(
          // id null (pas encore en DB)
          titre: name,
          categorie: categorie,
          cleVille: cleVille,
          adresse: adresse,
          latitude: lat,
          longitude: lon,
          // imageUrl: null (Wikimedia)
          description: _shortDesc(tags),
        ),
      );
    }

    return lieux;
  }

  String? _formatAdresse(Map<String, dynamic> tags) {
    final street = tags['addr:street'];
    final housenumber = tags['addr:housenumber'];
    final city = tags['addr:city'];
    final postcode = tags['addr:postcode'];

    final parts = <String>[];
    if (street != null) {
      parts.add('${street}${housenumber != null ? ' $housenumber' : ''}');
    }
    if (postcode != null || city != null) {
      parts.add('${postcode ?? ''} ${city ?? ''}'.trim());
    }
    final s = parts.join(', ').trim();
    return s.isEmpty ? null : s;
  }

  String? _shortDesc(Map<String, dynamic> tags) {
    // mini description utile (optionnel)
    final type =
        tags['tourism'] ??
        tags['amenity'] ??
        tags['historic'] ??
        tags['leisure'];
    return type == null ? null : 'Type OSM: $type';
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

class WikimediaApi {
  Future<String?> chercherImagePourLieu(
    String titreLieu, {
    String langue = 'fr', // fr.wikipedia.org par défaut
  }) async {
    if (titreLieu.trim().isEmpty) return null;

    // On cherche la page la plus pertinente pour ce titre
    final baseUrl = 'https://$langue.wikipedia.org/w/api.php';

    final searchUrl = Uri.parse(
      '$baseUrl'
      '?action=query' // interroge l'api
      '&format=json'
      '&list=search' // liste de recherche des res
      '&srsearch=${Uri.encodeComponent(titreLieu)}'
      '&srlimit=1' // prend le 1er res
      '&origin=*',
    );

    final searchResp = await http.get(searchUrl);
    if (searchResp.statusCode != 200) return null;

    final searchData = jsonDecode(searchResp.body) as Map<String, dynamic>;
    final query = searchData['query'] as Map<String, dynamic>?;
    final searchList = query?['search'] as List<dynamic>?;

    if (searchList == null || searchList.isEmpty) {
      return null; // aucune page trouvée
    }

    final firstResult = searchList.first as Map<String, dynamic>;
    final pageTitle = firstResult['title'] as String;

    // On récupère l'image (thumbnail) de cette page
    final imageUrl = Uri.parse(
      '$baseUrl'
      '?action=query'
      '&format=json'
      '&prop=pageimages' // on veut les images de la page
      '&titles=${Uri.encodeComponent(pageTitle)}'
      '&pithumbsize=600' // taille max de la miniature
      '&origin=*',
    );

    final imageResp = await http.get(imageUrl);
    if (imageResp.statusCode != 200) return null;

    final imageData = jsonDecode(imageResp.body) as Map<String, dynamic>;
    final pages =
        (imageData['query'] as Map<String, dynamic>?)?['pages']
            as Map<String, dynamic>?;

    if (pages == null) return null;

    // thumbnail contient source, hauteur, largeur
    for (final entry in pages.values) {
      // entry type dynamic et pages.values = toutes les pages wikipédia trouvées
      // lorsqu'une page wikipedia n'est pas null on récupère la source
      final page = entry as Map<String, dynamic>;
      final thumb = page['thumbnail'] as Map<String, dynamic>?; // miniature
      final source = thumb?['source'] as String?; // récupération du "jpg"
      if (source != null) return source; // on prend la première image trouvée
    }

    return null;
  }
}

class Lieu {
  final String titre;
  final String categorie;
  final String cleVille; // ex : "Paris,FR"
  final String? imageUrl;

  final String? adresse;
  final double? latitude;
  final double? longitude;
  final String? description;

  Lieu({
    required this.titre,
    required this.categorie,
    required this.cleVille,
    this.imageUrl,
    this.adresse,
    this.latitude,
    this.longitude,
    this.description,
  });
}

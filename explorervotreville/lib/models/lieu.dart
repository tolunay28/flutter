class Lieu {
  final String titre;
  final String categorie;
  final String cleVille; // ex : "Paris,FR"
  final String? imageUrl;

  Lieu({
    required this.titre,
    required this.categorie,
    required this.cleVille,
    this.imageUrl,
  });
}
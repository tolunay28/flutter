class Lieu {
  final int? id; // SQLite PK
  final String titre;
  final String categorie;
  final String cleVille; // ex: Paris,fr
  final String? imageUrl;
  final String? adresse;
  final double? latitude;
  final double? longitude;
  final String? description;

  Lieu({
    this.id,
    required this.titre,
    required this.categorie,
    required this.cleVille,
    this.imageUrl,
    this.adresse,
    this.latitude,
    this.longitude,
    this.description,
  });

  Lieu copyWith({
    int? id,
    String? titre,
    String? categorie,
    String? cleVille,
    String? imageUrl,
    String? adresse,
    double? latitude,
    double? longitude,
    String? description,
  }) {
    return Lieu(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      categorie: categorie ?? this.categorie,
      cleVille: cleVille ?? this.cleVille,
      imageUrl: imageUrl ?? this.imageUrl,
      adresse: adresse ?? this.adresse,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'titre': titre,
    'categorie': categorie,
    'cleVille': cleVille,
    'imageUrl': imageUrl,
    'adresse': adresse,
    'latitude': latitude,
    'longitude': longitude,
    'description': description,
  };

  //factory renvoie soit une nouvelle instance soit une déjà existante
  factory Lieu.fromMap(Map<String, dynamic> map) {
    return Lieu(
      id: map['id'] as int,
      titre: map['titre'],
      categorie: map['categorie'],
      cleVille: map['cleVille'],
      imageUrl: map['imageUrl'],
      adresse: map['adresse'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      description: map['description'],
    );
  }
}

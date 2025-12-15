import '../models/lieu.dart';
import 'app_database.dart';

class LieuRepository {
  Future<List<Lieu>> getLieuxPourVille(String? cleVille) async {
    if (cleVille == null || cleVille.trim().isEmpty) {
      return [];
    }
    final db = await AppDatabase.database;
    final maps = await db.query(
      'lieux',
      where: 'cleVille = ?', // ? endroit où l'arg va se placer
      whereArgs: [cleVille], // éviter requêtes sql malveillantes
    );
    return maps.map((map) => Lieu.fromMap(map)).toList();
  }

  Future<Lieu> insertLieu(Lieu lieu) async {
    final db = await AppDatabase.database;
    final id = await db.insert('lieux', lieu.toMap()); // insert renvoie id
    return lieu.copyWith(id: id);
  }

  Future<void> updateLieu(Lieu lieu) async {
    final db = await AppDatabase.database;
    await db.update(
      'lieux',
      lieu.toMap(),
      where: 'id = ?',
      whereArgs: [lieu.id],
    );
  }

  Future<bool> existeDejaLieu({
    required String cleVille,
    required String titre,
    double? latitude,
    double? longitude,
  }) async {
    final db = await AppDatabase.database;

    final result = await db.query(
      'lieux',
      where: '''
      cleVille = ?
      AND LOWER(titre) = LOWER(?)
      AND (
        (latitude IS NULL AND longitude IS NULL)
        OR (latitude = ? AND longitude = ?)
      )
    ''',
      whereArgs: [cleVille, titre, latitude, longitude],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<void> deleteLieu(int id) async {
    final db = await AppDatabase.database;
    await db.delete('lieux', where: 'id = ?', whereArgs: [id]);
  }
}

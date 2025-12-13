import '../models/lieu.dart';
import '../services/app_database.dart';

class LieuRepository {
  Future<List<Lieu>> getLieuxPourVille(String cleVille) async {
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

  Future<void> deleteLieu(int id) async {
    final db = await AppDatabase.database;
    await db.delete('lieux', where: 'id = ?', whereArgs: [id]);
  }
}

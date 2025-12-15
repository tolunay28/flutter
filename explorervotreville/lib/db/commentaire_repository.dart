import '../models/commentaire.dart';
import 'app_database.dart';

class CommentaireRepository {
  Future<List<Commentaire>> getByLieuId(int lieuId) async {
    final db = await AppDatabase.database;
    final maps = await db.query(
      'commentaires',
      where: 'lieuId = ?',
      whereArgs: [lieuId],
      orderBy: 'date DESC', // date les plus recentes en premier
    );
    return maps.map((m) => Commentaire.fromMap(m)).toList();
  }

  Future<Commentaire> insert(Commentaire c) async {
    final db = await AppDatabase.database;
    final id = await db.insert('commentaires', c.toMap());
    return c.copyWith(id: id);
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.database;
    await db.delete('commentaires', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllForLieu(int lieuId) async {
    final db = await AppDatabase.database;
    await db.delete('commentaires', where: 'lieuId = ?', whereArgs: [lieuId]);
  }
}

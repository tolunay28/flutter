import 'package:flutter/foundation.dart';

import '../models/lieu.dart';
import '../repositories/lieu_repository.dart';

class LieuxProvider extends ChangeNotifier {
  final _repo = LieuRepository();
  final Map<String, List<Lieu>> _cache = {};

  List<Lieu> lieuxPourVille(String cleVille) {
    return List.unmodifiable(_cache[cleVille] ?? []);
  }

  Future<void> chargerVille(String cleVille) async {
    final lieux = await _repo.getLieuxPourVille(cleVille);
    _cache[cleVille] = lieux;
    notifyListeners();
  }

  Future<bool> ajouterLieu(Lieu lieu) async {
    final existe = await _repo.existeDejaLieu(
      cleVille: lieu.cleVille,
      titre: lieu.titre,
      latitude: lieu.latitude,
      longitude: lieu.longitude,
    );

    if (existe) {
      print('Lieu déjà existant : ${lieu.titre}');
      return false;
    }

    final saved = await _repo.insertLieu(lieu);
    // permet d'initialiser une liste pour la ville si elle n'existe pas
    _cache.putIfAbsent(lieu.cleVille, () => []);
    _cache[lieu.cleVille]!.add(saved);

    notifyListeners();
    return true;
  }

  Future<void> mettreAJourLieu(Lieu lieu) async {
    if (lieu.id == null) {
      debugPrint('Tentative de mise à jour d’un lieu sans id (non persisté)');
      return;
    }
    await _repo.updateLieu(lieu);
    final list = _cache[lieu.cleVille];
    if (list == null) return;

    final index = list.indexWhere((l) => l.id == lieu.id);
    if (index == -1) return;

    final copy = [...list];
    copy[index] = lieu;
    _cache[lieu.cleVille] = copy;
    notifyListeners();
  }

  Future<void> supprimerLieu(Lieu lieu) async {
    if (lieu.id == null) return;
    await _repo.deleteLieu(lieu.id!);
    _cache[lieu.cleVille]?.removeWhere((l) => l.id == lieu.id);
    notifyListeners();
  }
}

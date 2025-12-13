import 'package:flutter/foundation.dart';

import '../models/lieu.dart';

class LieuxProvider extends ChangeNotifier {
  final Map<String, List<Lieu>> _lieuxParVille = {};

  // Lecture (on renvoie une copie non modifiable)
  List<Lieu> lieuxPourVille(String cleVille) {
    final list = _lieuxParVille[cleVille] ?? [];
    return List.unmodifiable(list);
  }

  void ajouterLieu(Lieu lieu) {
    final cle = lieu.cleVille;
    final list = _lieuxParVille[cle] ?? [];
    _lieuxParVille[cle] = [...list, lieu];
    notifyListeners();
  }

  void mettreAJourLieu(Lieu ancien, Lieu nouveau) {
    final cle = ancien.cleVille;
    final list = _lieuxParVille[cle];
    if (list == null) return;

    final index = list.indexOf(ancien);
    if (index == -1) return;

    final copy = List<Lieu>.from(list);
    copy[index] = nouveau;
    _lieuxParVille[cle] = copy;
    notifyListeners();
  }

  void supprimerLieu(Lieu lieu) {
    final cle = lieu.cleVille;
    final list = _lieuxParVille[cle];
    if (list == null) return;

    _lieuxParVille[cle] = list.where((x) => x != lieu).toList();
    notifyListeners();
  }

  // clear pour debug (optionnel si jamais on en a besoin)
  void clearAll() {
    _lieuxParVille.clear();
    notifyListeners();
  }
}

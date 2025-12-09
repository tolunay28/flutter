import 'package:flutter/material.dart';

import '../services/villes_meteo_api.dart';

/// Lieu enregistré localement
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

// modif pageprincipale avant c'était mainpage
class PagePrincipale extends StatefulWidget {
  const PagePrincipale({super.key});

  @override
  State<PagePrincipale> createState() => _PagePrincipaleState();
}

class _PagePrincipaleState extends State<PagePrincipale> {
  final TextEditingController _villeController = TextEditingController(
    text: 'Giresun',
  );
  final VillesMeteoApi _api = VillesMeteoApi();

  VilleResultat? _villeSelectionnee;
  MeteoActuelle? _meteo;

  bool _loadingVille = false;
  bool _loadingMeteo = false;

  // Lieux par ville (clé: "Nom,Pays")
  final Map<String, List<Lieu>> _lieuxParVille = {};

  // Suggestions de villes (autocomplétion)
  List<VilleResultat> _suggestions = [];
  bool _loadingSuggestions = false;
  String _lastSuggestQuery = '';

  @override
  void initState() {
    super.initState();
    _rechercherVille(forceNom: _villeController.text); // charge Paris au début
  }

  @override
  void dispose() {
    _villeController.dispose();
    super.dispose();
  }

  List<Lieu> get _lieuxPourVilleSelectionnee {
    final cle = _villeSelectionnee?.cle;
    if (cle == null) return [];
    return _lieuxParVille[cle] ?? [];
  }

  // =========================
  // AUTOCOMPLÉTION A PARTIR DE 3 LETTRES
  // =========================
  Future<void> _mettreAJourSuggestions(String input) async {
    final q = input.trim();
    if (q.length < 3) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    _lastSuggestQuery = q;
    setState(() {
      _loadingSuggestions = true;
    });

    try {
      final resultats = await _api.rechercherVilles(q);
      if (!mounted) return;

      // Si entre-temps l'utilisateur a tapé autre chose, on ignore
      if (q != _lastSuggestQuery) return;

      setState(() {
        _suggestions = resultats;
        _loadingSuggestions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingSuggestions = false;
        _suggestions = [];
      });
    }
  }

  // =========================
  // RECHERCHE "VALIDÉE" (bouton recherche ou submit)
  // =========================
  Future<void> _rechercherVille({String? forceNom}) async {
    final nomSaisi = forceNom ?? _villeController.text.trim();
    if (nomSaisi.isEmpty) return;

    setState(() {
      _loadingVille = true;
    });

    try {
      final resultats = await _api.rechercherVilles(nomSaisi);

      if (!mounted) return;

      if (resultats.isEmpty) {
        setState(() {
          _loadingVille = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Aucune ville trouvée')));
        return;
      }

      if (resultats.length == 1) {
        _choisirVille(resultats.first);
      } else {
        // Plusieurs villes : on propose un choix
        _afficherDialogChoixVille(resultats);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingVille = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la recherche : $e')),
      );
    }
  }

  void _choisirVille(VilleResultat ville) {
    setState(() {
      _villeSelectionnee = ville;
      _loadingVille = false;
      _suggestions = []; // on cache les suggestions après choix
      _villeController.text = ville.nom;
    });
    _chargerMeteoPourVille(ville);
  }

  Future<void> _afficherDialogChoixVille(List<VilleResultat> resultats) async {
    final villeChoisie = await showDialog<VilleResultat>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Choisissez une ville'),
          children: [
            for (final v in resultats)
              SimpleDialogOption(
                onPressed: () => Navigator.of(ctx).pop(v),
                child: Text('${v.nom} (${v.pays})'),
              ),
          ],
        );
      },
    );

    if (villeChoisie != null) {
      _choisirVille(villeChoisie);
    } else {
      setState(() {
        _loadingVille = false;
      });
    }
  }

  Future<void> _chargerMeteoPourVille(VilleResultat ville) async {
    setState(() {
      _loadingMeteo = true;
    });

    try {
      final meteo = await _api.getMeteoPourVille(ville);
      if (!mounted) return;
      setState(() {
        _meteo = meteo;
        _loadingMeteo = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMeteo = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur météo : $e')));
    }
  }

  // =========================
  // AJOUT DE LIEU (via FloatingActionButton)
  // =========================
  void _ouvrirDialogAjoutLieu() {
    if (_villeSelectionnee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez d\'abord une ville')),
      );
      return;
    }

    final titreController = TextEditingController();
    final categorieController = TextEditingController();
    final imageController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Ajouter un lieu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titreController,
                  decoration: const InputDecoration(
                    labelText: 'Titre du lieu',
                    prefixIcon: Icon(Icons.place),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: categorieController,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie (restaurant, parc...)',
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: imageController,
                  decoration: const InputDecoration(
                    labelText: 'URL de l’image (optionnel)',
                    prefixIcon: Icon(Icons.image),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ville : ${_villeSelectionnee!.nom} (${_villeSelectionnee!.pays})',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                final titre = titreController.text.trim();
                final cat = categorieController.text.trim();
                final img = imageController.text.trim();

                if (titre.isEmpty || cat.isEmpty) return;

                final cle = _villeSelectionnee!.cle;
                final liste = _lieuxParVille[cle] ?? [];

                setState(() {
                  liste.add(
                    Lieu(
                      titre: titre,
                      categorie: cat,
                      cleVille: cle,
                      imageUrl: img.isEmpty ? null : img,
                    ),
                  );
                  _lieuxParVille[cle] = liste;
                });

                Navigator.of(ctx).pop();
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ville = _villeSelectionnee;
    final lieuxVille = _lieuxPourVilleSelectionnee;

    return Scaffold(
      appBar: AppBar(title: const Text('ExplorezVotreVille')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Champ de saisie ville
              TextField(
                controller: _villeController,
                decoration: InputDecoration(
                  labelText: 'Rechercher une ville',
                  prefixIcon: const Icon(Icons.location_city),
                  suffixIcon: _loadingVille
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _rechercherVille,
                        ),
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.search,
                onChanged: _mettreAJourSuggestions, // 🔹 autocomplétion
                onSubmitted: (_) => _rechercherVille(),
              ),

              // Suggestions de villes (sous le TextField)
              if (_loadingSuggestions)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (_suggestions.isNotEmpty)
                Card(
                  margin: const EdgeInsets.only(top: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final v = _suggestions[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on),
                          title: Text('${v.nom} (${v.pays})'),
                          onTap: () => _choisirVille(v), // 🔹 clique suggestion
                        );
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Ville + météo
              if (ville != null)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${ville.nom} (${ville.pays})',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              if (_loadingMeteo)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: LinearProgressIndicator(minHeight: 3),
                                )
                              else if (_meteo != null)
                                Text(
                                  'Temps : ${_meteo!.temp.round()}°C '
                                  '(min ${_meteo!.tempMin.round()}°C, max ${_meteo!.tempMax.round()}°C)\n'
                                  'Temps : ${_meteo!.description}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                )
                              else
                                Text(
                                  'Météo non disponible',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              Text(
                ville == null
                    ? 'Aucune ville sélectionnée'
                    : 'Lieux enregistrés à ${ville.nom}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              // Liste des lieux
              Expanded(
                child: ville == null
                    ? const Center(
                        child: Text('Recherchez une ville pour commencer.'),
                      )
                    : lieuxVille.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun lieu enregistré pour cette ville.\nAjoutez-en avec le bouton +',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        itemCount: lieuxVille.length,
                        itemBuilder: (context, index) {
                          final lieu = lieuxVille[index];
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.95, end: 1),
                            duration: Duration(milliseconds: 250 + index * 40),
                            builder: (context, valeur, child) {
                              return Transform.scale(
                                scale: valeur,
                                child: child,
                              );
                            },
                            child: _LieuCard(lieu: lieu),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),

      // 🔹 BOUTON POUR AJOUTER DES LIEUX
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ouvrirDialogAjoutLieu,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Ajouter un lieu'),
      ),
    );
  }
}

class _LieuCard extends StatelessWidget {
  final Lieu lieu;
  const _LieuCard({required this.lieu});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      // rend la card cliquable
      onTap: () {
        Navigator.pushNamed(
          context,
          '/page_detail', // route nommée
          arguments: lieu, // on passe l'objet Lieu à la page détail
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: lieu.imageUrl != null
                  ? Image.network(
                      lieu.imageUrl!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.contain, // a mettre
                    )
                  : Container(
                      height: 160,
                      width: double.infinity,
                      color: cs.surfaceContainerHighest,
                      child: const Icon(Icons.photo, size: 48),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lieu.titre,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lieu.categorie,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: cs.outline),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

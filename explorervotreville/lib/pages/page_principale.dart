import 'package:explorervotreville/services/wikimedia_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/lieu.dart';
import '../providers/setting_provider.dart';
import '../services/map_api.dart';
import '../services/villes_meteo_api.dart';

// modif pageprincipale avant c'était mainpage
class PagePrincipale extends StatefulWidget {
  const PagePrincipale({super.key});

  @override
  State<PagePrincipale> createState() => _PagePrincipaleState();
}

class _PagePrincipaleState extends State<PagePrincipale> {
  final TextEditingController _villeController = TextEditingController(
    text: '',
  );
  final VillesMeteoApi _api = VillesMeteoApi();
  final Map_api _map_api = Map_api();
  final WikimediaApi _wikimediaApi = WikimediaApi();
  final MapController _mapController = MapController();

  LatLng _center = const LatLng(
    48.8566,
    2.3522,
  ); // Coordonnées par défaut : Paris

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

  static const List<String> _categories = [
    'Musée',
    'Salle de concert',
    'Théâtre',
    'Cinéma',
    'Parc',
    'Stade',
    'Monument',
    'Restaurant',
    'Bar',
    'Shopping',
    'Point de vue',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _getInitLocation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // attend que la page avant d'executer le code en dessous
      final saved = context.read<SettingsProvider>().defaultCity;
      if (saved != null) {
        _choisirVille(saved);
      }
    });
  }

  @override
  void dispose() {
    _villeController.dispose();
    super.dispose();
  }

  List<Lieu> get _lieuxPourVilleSelectionnee {
    final cle = _villeSelectionnee?.cle; // cle = nom,pays
    if (cle == null) return [];
    return _lieuxParVille[cle] ?? [];
  }

  // autocomplétion à partir de 3 lettres
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

  // bouton recherche ou submit
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

  Future<void> _choisirVille(VilleResultat ville) async {
    final newCenter = LatLng(ville.lat, ville.lon);
    setState(() {
      _villeSelectionnee = ville;
      _loadingVille = false;
      _suggestions = []; // on cache les suggestions après choix
      _villeController.text = ville.nom;
      _center = newCenter;
    });
    _mapController.move(newCenter, 12.0);
    await _chargerMeteoPourVille(ville);
    //ajoute en historique
    await context.read<SettingsProvider>().addRecentCity(ville);
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
      await _choisirVille(villeChoisie);
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

  void _mettreAJourLieu(Lieu ancien, Lieu nouveau) {
    final cle = ancien.cleVille; // ex: "Paris,FR"
    final liste = _lieuxParVille[cle];
    if (liste == null) return;

    final index = liste.indexOf(ancien); // cherche la pos de l'objet ancien
    if (index == -1) return; // s'il n'est pas trouvé = -1 (on ne fait rien)

    setState(() {
      liste[index] = nouveau; //
      _lieuxParVille[cle] = List.from(
        liste,
      ); // List.from au cas où le rebuild ne fonctionnerait pas juste avec l'affectation
    });
  }

  Future<void> _getInitLocation() async {
    try {
      // Une seule ligne pour tout faire
      final position = await _map_api.getCurrentPosition();

      if (position != null) {
        setState(() {
          _center = position;
          // Plus besoin de gérer _latitude/_longitude en String séparés car LatLng est partout
        });
        _mapController.move(_center, 12.0);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())), // Affiche l'erreur du service
      );
    }
  }

  // ajout de lieu (via FloatingActionButton)
  void _ouvrirDialogAjoutLieu() {
    if (_villeSelectionnee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez d\'abord une ville')),
      );
      return;
    }

    final titreController = TextEditingController();
    final imageController = TextEditingController();
    final adresseController = TextEditingController();
    final descriptionController = TextEditingController();
    String? categorieSelectionnee = _categories.first;
    LatLng? positionSelectionnee;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          // " rafraichir" tout le dialog (dropdown + carte) dans le dialog sans créer un widget séparé
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Ajouter un lieu'),
              content: SizedBox(
                width: 500,
                height: 550,
                child: SingleChildScrollView(
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

                      // bouton pour liste déroulante
                      DropdownButtonFormField<String>(
                        initialValue: categorieSelectionnee,
                        decoration: const InputDecoration(
                          labelText: 'Catégorie',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (value) {
                          setLocalState(() {
                            categorieSelectionnee = value;
                          });
                        },
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        controller: adresseController,
                        decoration: const InputDecoration(
                          labelText: 'Adresse (optionnel)',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                      ),
                      const SizedBox(height: 8),

                      //  ajouter un lieu depuis la carte
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.map),
                            label: Text(
                              positionSelectionnee == null
                                  ? "Choisir sur la carte"
                                  : "Modifier la position",
                            ),
                            onPressed: () async {
                              // centre = ville sélectionnée si possible, sinon centre actuel de la map
                              final center = _villeSelectionnee != null
                                  ? LatLng(
                                      _villeSelectionnee!.lat,
                                      _villeSelectionnee!.lon,
                                    )
                                  : _center;

                              final picked = await Navigator.pushNamed(
                                ctx,
                                '/page_selection_position',
                                arguments: positionSelectionnee ?? center,
                              );

                              if (picked is LatLng) {
                                setLocalState(() {
                                  positionSelectionnee = picked;
                                });
                              }
                            },
                          ),

                          if (positionSelectionnee != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              "Lat: ${positionSelectionnee!.latitude.toStringAsFixed(5)}, "
                              "Lon: ${positionSelectionnee!.longitude.toStringAsFixed(5)}",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: imageController,
                              decoration: const InputDecoration(
                                labelText:
                                    'URL de l’image (optionnel) recherche automatique  -> \n (recherche conseillé pour les lieux connus) ',
                                prefixIcon: Icon(Icons.image),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Chercher une image avec Wikimedia',
                            icon: const Icon(Icons.image_search),
                            onPressed: () async {
                              final titre = titreController.text.trim();
                              if (titre.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Veuillez d’abord saisir un titre de lieu.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              // Appel à Wikimedia
                              final urlImage = await _wikimediaApi
                                  .chercherImagePourLieu(titre);

                              if (!mounted) return;

                              if (urlImage != null) {
                                setLocalState(() {
                                  imageController.text = urlImage;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Image trouvée via Wikimedia ',
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Aucune image trouvée pour ce lieu sur Wikimedia. Veuillez saisir vous-même une URL '
                                      'd’image si vous souhaitez ajouter une photo au lieu.',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description du lieu (optionnel)',
                          prefixIcon: Icon(Icons.description),
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () async {
                    final titre = titreController.text.trim();
                    final cat = categorieSelectionnee;
                    final img = imageController.text.trim();
                    final adresseSaisie = adresseController.text.trim();
                    final description = descriptionController.text.trim();

                    if (titre.isEmpty || cat == null) return;

                    double? lat;
                    double? lon;
                    String? adresseComplete;

                    //  On choisit quoi envoyer à Nominatim :
                    //  - si l'utilisateur a mis une adresse : on la prend
                    //  - sinon : on essaye avec le titre du lieu (pour les lieux connus aucun problème)
                    //  - Priorité à la position choisie sur la carte
                    if (positionSelectionnee != null) {
                      lat = positionSelectionnee!.latitude;
                      lon = positionSelectionnee!.longitude;

                      adresseComplete = adresseSaisie.isEmpty
                          ? 'Position choisie sur la carte'
                          : adresseSaisie;
                    } else {
                      // Sinon, on tente Nominatim avec juste le titre du lieu
                      String requetePourNominatim = adresseSaisie.isNotEmpty
                          ? adresseSaisie
                          : titre;

                      final resultat = await _map_api.chercherAdresse(
                        requetePourNominatim,
                        _villeSelectionnee!,
                      );

                      if (resultat != null) {
                        lat = resultat.coordonnees.latitude;
                        lon = resultat.coordonnees.longitude;
                        adresseComplete = resultat
                            .displayName; // texte long, type "Rue X, Ville, Pays"
                      } else {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Adresse introuvable pour "$requetePourNominatim". '
                              'Le lieu sera ajouté sans position précise.',
                            ),
                          ),
                        );
                      }
                    }

                    final cle = _villeSelectionnee!.cle;
                    final liste = _lieuxParVille[cle] ?? [];

                    setState(() {
                      liste.add(
                        Lieu(
                          titre: titre,
                          categorie: cat,
                          cleVille: cle,
                          imageUrl: img.isEmpty ? null : img,
                          adresse:
                              adresseComplete ??
                              (adresseSaisie.isEmpty ? null : adresseSaisie),
                          latitude: lat,
                          longitude: lon,
                          description: description.isEmpty ? null : description,
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
      },
    );
  }

  // build
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ville = _villeSelectionnee;
    final lieuxVille = _lieuxPourVilleSelectionnee;
    final recents = context.watch<SettingsProvider>().recentCities;

    return Scaffold(
      appBar: AppBar(title: const Text('ExplorezVotreVille')),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Paramètres',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),

              SwitchListTile(
                title: const Text('Mode sombre'),
                value: context.watch<SettingsProvider>().darkMode,
                onChanged: (value) async {
                  await context.read<SettingsProvider>().toggleDarkMode(value);
                },
                secondary: const Icon(Icons.dark_mode),
              ),
            ],
          ),
        ),
      ),
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
                onChanged: _mettreAJourSuggestions, // autocomplétion
                onSubmitted: (_) => _rechercherVille(),
              ),

              // Suggestions de villes
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
                          onTap: () async =>
                              await _choisirVille(v), // clique suggestion
                        );
                      },
                    ),
                  ),
                ),
              // villes récentes
              if (recents.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, // hor
                  runSpacing: 8, // vertical
                  children: recents.take(5).map((v) {
                    return ActionChip(
                      label: Text('${v.nom} (${v.pays})'),
                      onPressed: () async => await _choisirVille(v),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 16),
              //map
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(initialCenter: _center, initialZoom: 9.0),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
                      retinaMode: true,
                      subdomains: const ['a', 'b', 'c', 'd'],
                      // attributionBuilder: (_) {
                      //   return Text("© OpenStreetMap contributors | © Carto");
                      // },
                    ),
                    MarkerLayer(
                      markers: [
                        // marker de la ville (position courante)
                        Marker(
                          point: _center,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_city,
                            size: 35,
                            color: Colors.red,
                          ),
                        ),

                        // markers pour les lieux de la ville
                        if (ville != null)
                          ..._lieuxPourVilleSelectionnee // markers attend une liste d'objet, (...)on la génére avec les lieux de la ville
                              .where(
                                (l) =>
                                    l.latitude != null && l.longitude != null,
                              )
                              .map(
                                (lieu) => Marker(
                                  width: 40,
                                  height: 40,
                                  point: LatLng(
                                    lieu.latitude!,
                                    lieu.longitude!,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/page_detail',
                                        arguments: lieu,
                                      );
                                    },
                                    child: const Icon(
                                      Icons.place,
                                      size: 34,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ),

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
                    : GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 320, // largeur max d’une carte
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio:
                              0.75, // ajuste la forme (plus ou moins haute)
                        ),
                        itemCount: lieuxVille.length,
                        itemBuilder: (context, index) {
                          final lieu = lieuxVille[index];
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.95, end: 1),
                            duration: Duration(
                              milliseconds: 250 + index * 40,
                            ), // ajoute 40 ms pour chaque lieu a l'affichage
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

      // Bouton pour ajouter des lieux
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
      onTap: () async {
        // On récupère navigator et state avant l'await car context dans await peut être problématique
        final navigator = Navigator.of(context);
        //Récupérer le parent PagePrincipale pour mettre à jour les lieux
        final state = context.findAncestorStateOfType<_PagePrincipaleState>();

        final resultat = await navigator.pushNamed(
          '/page_detail',
          arguments: lieu,
        );

        if (resultat is Lieu && state != null) {
          state._mettreAJourLieu(lieu, resultat);
        }
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

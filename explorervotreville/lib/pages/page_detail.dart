import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/lieu.dart';

class PageDetail extends StatefulWidget {
  final Lieu lieu;

  const PageDetail({super.key, required this.lieu});

  @override
  State<PageDetail> createState() => _PageDetailState();
}

class _PageDetailState extends State<PageDetail>
    with SingleTickerProviderStateMixin {
  // on crée une animation explicite donc on utilse single...
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  final TextEditingController _commentController = TextEditingController();
  double _noteCourante = 3.0;
  double _noteMoyenne = 3.0;

  final MapController _mapController = MapController();
  late final LatLng _center;

  final List<_Commentaire> _commentaires = [];

  String? _adresseActuelle;

  @override
  void initState() {
    super.initState();

    final lieu = widget.lieu; // widget permet de recuperer le lieu en param
    _adresseActuelle = lieu.adresse;

    if (lieu.latitude != null && lieu.longitude != null) {
      _center = LatLng(lieu.latitude!, lieu.longitude!);
    } else {
      // Fallback : le centre de la ville ou une valeur par défaut
      _center = const LatLng(48.8566, 2.3522); // Paris
    }

    // Animation explicite fade + slide
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      // commence transparente et fini opaque
      parent: _controller,
      curve: Curves.easeOut, // commence rapidement puis ralentit.
    );

    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.05), //(X horizontal, Y vertical)
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        ); // de bas en haut

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _ajouterCommentaire() {
    final texte = _commentController.text.trim();
    if (texte.isEmpty) return;

    setState(() {
      _commentaires.add(
        _Commentaire(texte: texte, note: _noteCourante, date: DateTime.now()),
      );

      final total = _commentaires.fold<double>(0, (sum, c) => sum + c.note);
      _noteMoyenne = total / _commentaires.length;

      _commentController.clear();
      _noteCourante = _noteMoyenne;
    });
  }

  void _modifierAdresse() async {
    // on part de _adresseActuelle (si déjà modifiée)
    final controller = TextEditingController(text: _adresseActuelle ?? '');

    final nouvelleAdresse = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Modifier l'adresse du lieu"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Adresse ou nom du lieu',
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop(controller.text.trim());
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );

    if (nouvelleAdresse == null || nouvelleAdresse.isEmpty) return;

    if (!mounted) return;

    //on met à jour l’adresse affichée dans la page
    setState(() {
      _adresseActuelle = nouvelleAdresse;
      // si ton modèle Lieu a des champs non-final, tu pourrais aussi faire :
      // widget.lieu.adresse = nouvelleAdresse;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Adresse mise à jour (localement) : $nouvelleAdresse\n"
          "(à persister + géolocaliser plus tard).",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lieu = widget.lieu;

    return Scaffold(
      appBar: AppBar(title: Text(lieu.titre)),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              // permet de scroller le widget
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // met a gauche
                children: [
                  // image
                  ClipRRect(
                    // permet d'arrondir l'image (container a ces bords arrondi mais pas l'image)
                    borderRadius: BorderRadius.circular(16),
                    child: lieu.imageUrl != null
                        ? Image.network(
                            lieu.imageUrl!,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.contain, // pareil dans page_principal
                          )
                        : Container(
                            height: 220,
                            width: double.infinity,
                            color: cs.surfaceContainerHighest,
                            child: const Icon(Icons.photo, size: 64),
                          ),
                  ),

                  const SizedBox(height: 16),

                  // titre + catégorie + note
                  Row(
                    children: [
                      Expanded(
                        //prend tout l'espace dispo
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lieu.titre,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    // ? pour eviter de crash si c'est nul
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lieu.categorie,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: cs.primary),
                            ),
                          ],
                        ),
                      ),

                      // note animée
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _noteMoyenne >= 4
                              ? cs.primaryContainer
                              : cs.secondaryContainer, // plus 'claire'
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              _noteMoyenne.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // adresse
                  if (_adresseActuelle != null &&
                      _adresseActuelle!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, size: 18),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            lieu.adresse!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),

                  //description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lieu.description ?? "Aucune description n'a été trouvée.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 16),

                  //  carte
                  if (lieu.latitude != null && lieu.longitude != null) ...[
                    SizedBox(
                      height: 200,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _center,
                          initialZoom: 15.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
                            retinaMode: true,
                            subdomains: const ['a', 'b', 'c', 'd'],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _center,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Position inconnue pour ce lieu",
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Aucune adresse ou coordonnées n'ont été renseignées.",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: _modifierAdresse,
                                    icon: const Icon(Icons.edit_location_alt),
                                    label: const Text("Modifier l'adresse"),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // commentaires
                  Text(
                    'Commentaires',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_commentaires.isEmpty)
                    Text(
                      'Aucun commentaire pour le moment.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    ListView.separated(
                      shrinkWrap:
                          true, // prend seulement la taille(hauteur) nécessaire
                      physics:
                          const NeverScrollableScrollPhysics(), // car dans SingleChildScrollView
                      itemCount: _commentaires.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _CommentaireCard(
                          commentaire: _commentaires[index],
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // ajouter commentaire
                  Text(
                    'Ajouter un commentaire',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _commentController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText:
                                  'Votre commentaire…', // texte grisé avant une saisie
                              border:
                                  OutlineInputBorder(), // cadre autour du champs
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'Note : ${_noteCourante.toStringAsFixed(1)}', // (avec une seule décimale)
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),

                          Slider(
                            min: 0,
                            max: 5,
                            divisions:
                                10, // permet d'obtenir le cran des notes (max / div) = 0.5
                            value: _noteCourante,
                            onChanged: (v) {
                              setState(() => _noteCourante = v);
                            },
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: _ajouterCommentaire,
                              icon: const Icon(Icons.send),
                              label: const Text('Publier'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ======== COMMENTAIRES ========

class _Commentaire {
  final String texte;
  final double note;
  final DateTime date;

  _Commentaire({required this.texte, required this.note, required this.date});
}

class _CommentaireCard extends StatelessWidget {
  final _Commentaire commentaire;

  const _CommentaireCard({required this.commentaire});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.person, color: cs.primary),
            const SizedBox(width: 8),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: cs.primary),
                      const SizedBox(width: 4),
                      Text(
                        commentaire.note.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(commentaire.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.outline,
                        ), // outline = grisé
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    commentaire.texte,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    // format simple JJ/MM/AA  ,padleft ajoute 0 si le jour est < 10
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString().padLeft(2, '0');

    return '$day/$month/$year';
  }
}

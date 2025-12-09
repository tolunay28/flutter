import 'package:flutter/material.dart';
import '../models/lieu.dart';
import 'page_principale.dart';

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

  final List<_Commentaire> _commentaires = [];

  @override
  void initState() {
    super.initState();

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

                  // description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Description à venir… (en attendant, ceci est un texte par défaut).',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 16),

                  //  carte
                  Text(
                    'Localisation (carte à venir)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize
                            .min, // taille réduit au minimum nécéssaire
                        children: [
                          Icon(Icons.map, color: cs.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Carte à venir…',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // commentaires LIRE A PARTIR D ICI LA SUITE
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
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _commentaires.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _CommentaireCard(
                          commentaire: _commentaires[index],
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // AJOUT COMMENTAIRE
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
                              hintText: 'Votre commentaire…',
                              border: OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'Note : ${_noteCourante.toStringAsFixed(1)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),

                          Slider(
                            min: 0,
                            max: 5,
                            divisions: 10,
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
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: cs.outline),
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
    // format simple JJ/MM
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month';
  }
}


// todo mettre le bouton "publier" visible meme quand l'écran est a la moitié ------ pareil pour le bouton ajouter lieu dans la page principale
// cf si possibilté de gérer l'image en plein écran 
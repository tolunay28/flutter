import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/setting_provider.dart';
import '../services/villes_meteo_api.dart';

class PageVillesFavorites extends StatefulWidget {
  const PageVillesFavorites({super.key});

  @override
  State<PageVillesFavorites> createState() => _PageVillesFavoritesState();
}

class _PageVillesFavoritesState extends State<PageVillesFavorites>
    with SingleTickerProviderStateMixin {
  late List<VilleResultat> _draft; // copie locale modifiable
  final Set<String> _markedForRemoval = {}; // cle villes "grisées"

  // animation
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _draft = List<VilleResultat>.from(settings.favoriteCities);

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
    super.dispose();
  }

  Future<void> _commitOnExit() async {
    final settings = context.read<SettingsProvider>();
    final defaultCity = settings.defaultCity;

    // On retire les villes marquées "gris"
    final kept = _draft
        .where((v) => !_markedForRemoval.contains(v.cle))
        .toList();

    // Si la ville ++ a été supprimée → on la remet à null
    if (defaultCity != null && _markedForRemoval.contains(defaultCity.cle)) {
      await settings.setDefaultCity(null);
    }

    // On met à jour les favoris
    await settings.setFavoriteCities(kept);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final defaultCity = settings.defaultCity;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        // Quand on quitte la page : suppression définitive des grises
        if (didPop) {
          await _commitOnExit();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Villes favorites')),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _draft.isEmpty
                  ? const Center(
                      child: Text(
                        "Aucune ville favorite.\nAjoute-en depuis la page principale ",
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _draft.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final v = _draft[index];

                        final isMarkedGrey = _markedForRemoval.contains(v.cle);
                        final isDefault = defaultCity?.cle == v.cle;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.location_city),
                            title: Text('${v.nom} (${v.pays})'),
                            subtitle: Text(
                              'Lat ${v.lat.toStringAsFixed(3)} • Lon ${v.lon.toStringAsFixed(3)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ville ++ (une seule)
                                IconButton(
                                  tooltip: 'Définir comme ville ++',
                                  icon: Icon(
                                    isDefault
                                        ? Icons.push_pin
                                        : Icons.push_pin_outlined,
                                    color: isDefault
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                  onPressed: () async {
                                    await context
                                        .read<SettingsProvider>()
                                        .setDefaultCity(v);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${v.nom} est la ville mise en avant',
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                // jaune si conservée, grise si marquée suppression
                                IconButton(
                                  tooltip: isMarkedGrey
                                      ? 'Annuler la suppression'
                                      : 'Retirer des favoris',
                                  icon: Icon(
                                    isMarkedGrey
                                        ? Icons.star_border
                                        : Icons.star,
                                    color: isMarkedGrey
                                        ? Colors.grey
                                        : Colors.amber,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (isMarkedGrey) {
                                        _markedForRemoval.remove(
                                          v.cle,
                                        ); // redevient jaune
                                      } else {
                                        _markedForRemoval.add(
                                          v.cle,
                                        ); // devient grise
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

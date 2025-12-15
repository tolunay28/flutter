import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/setting_provider.dart';
import '../services/villes_meteo_api.dart';

class PageVillesFavorites extends StatefulWidget {
  const PageVillesFavorites({super.key});

  @override
  State<PageVillesFavorites> createState() => _PageVillesFavoritesState();
}

class _PageVillesFavoritesState extends State<PageVillesFavorites> {
  late List<VilleResultat> _draft; // copie locale modifiable
  final Set<String> _markedForRemoval = {}; // cle villes "grisées"

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _draft = List<VilleResultat>.from(settings.favoriteCities);
  }

  Future<void> _commitOnExit() async {
    // On retire les villes marquées "gris"
    final kept = _draft
        .where((v) => !_markedForRemoval.contains(v.cle))
        .toList();

    // Si la ville ++ a été supprimée des favoris, on la laisse en defaultCity
    // (tu peux choisir de la remettre à null si tu veux, mais on reste simple)

    await context.read<SettingsProvider>().setFavoriteCities(kept);
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
        body: _draft.isEmpty
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
                              isMarkedGrey ? Icons.star_border : Icons.star,
                              color: isMarkedGrey ? Colors.grey : Colors.amber,
                            ),
                            onPressed: () {
                              setState(() {
                                if (isMarkedGrey) {
                                  _markedForRemoval.remove(
                                    v.cle,
                                  ); // redevient jaune
                                } else {
                                  _markedForRemoval.add(v.cle); // devient grise
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
    );
  }
}

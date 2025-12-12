import 'package:explorervotreville/pages/page_detail.dart';
import 'package:explorervotreville/pages/page_selection_position.dart';
import 'package:explorervotreville/providers/setting_provider.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'models/lieu.dart';
import 'pages/page_accueil.dart';
import 'pages/page_principale.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On crée le provider et on charge les prefs AVANT runApp
  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: const ExplorezVotreVilleApp(),
    ),
  );
}

class ExplorezVotreVilleApp extends StatelessWidget {
  const ExplorezVotreVilleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // on récupère le thème global depuis le provider
    final darkMode = context.watch<SettingsProvider>().darkMode;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ExplorezVotreVille',
      theme: darkMode
          ? ThemeData.dark(useMaterial3: true)
          : ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      initialRoute: '/',
      routes: {
        // uniquement les pages statiques (sans parametres)
        '/': (_) => const PageAccueil(),
        '/page_principale': (_) => const PagePrincipale(),
      },

      onGenerateRoute: (settings) {
        // pour utiliser pushNamed avec parametre car il ne gere pas tout seul les parametres
        if (settings.name == '/page_detail') {
          final lieu = settings.arguments as Lieu;
          return MaterialPageRoute(builder: (_) => PageDetail(lieu: lieu));
        }

        if (settings.name == '/page_selection_position') {
          final initial = settings.arguments as LatLng?;
          return MaterialPageRoute(
            builder: (_) => PageSelectionPosition(
              initialCenter:
                  initial ?? const LatLng(48.8566, 2.3522), // Paris par défaut
            ),
          );
        }
        return null;
      },
    );
  }
}

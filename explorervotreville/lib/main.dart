import 'package:explorervotreville/pages/page_detail.dart';
import 'package:explorervotreville/pages/page_selection_position.dart';
import 'package:explorervotreville/providers/lieux_provider.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'models/lieu.dart';
import 'pages/page_accueil.dart';
import 'pages/page_principale.dart';
import 'providers/setting_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // permet de créer le pont entre dart et IOS/Android etc

  // On initialise le provider avant runApp (SharedPreferences)
  final settings = SettingsProvider();
  await settings.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(create: (_) => LieuxProvider()),
      ],
      child: const ExplorezVotreVilleApp(),
    ),
  );
}

class ExplorezVotreVilleApp extends StatelessWidget {
  const ExplorezVotreVilleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ExplorezVotreVille',

      // thème clair + sombre
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: settings.themeMode, // SharedPreferences

      initialRoute: '/',
      routes: {
        // uniquement les pages statiques (sans parametres)
        '/': (_) => const PageAccueil(),
        '/page_principale': (_) => const PagePrincipale(),
      },

      onGenerateRoute: (settingsRoute) {
        // pour utiliser pushNamed avec parametre car il ne gere pas tout seul les parametres
        if (settingsRoute.name == '/page_detail') {
          final lieu = settingsRoute.arguments as Lieu;
          return MaterialPageRoute(builder: (_) => PageDetail(lieu: lieu));
        }

        if (settingsRoute.name == '/page_selection_position') {
          final initial = settingsRoute.arguments as LatLng?;
          return MaterialPageRoute(
            builder: (_) => PageSelectionPosition(
              initialCenter: initial ?? const LatLng(48.8566, 2.3522), // Paris
            ),
          );
        }
        return null;
      },
    );
  }
}

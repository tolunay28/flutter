import 'package:explorervotreville/pages/page_detail.dart';
import 'package:flutter/material.dart';

import 'pages/page_accueil.dart';
import 'pages/page_principale.dart';

void main() {
  runApp(const ExplorezVotreVilleApp());
}

class ExplorezVotreVilleApp extends StatelessWidget {
  const ExplorezVotreVilleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ExplorezVotreVille',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
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
        return null;
      },
    );
  }
}

// modif faites au niveau des noms + generateroute

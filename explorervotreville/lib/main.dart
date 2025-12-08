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
        '/': (_) => const PageAccueil(),
        '/main': (_) => const MainPage(),
      },
    );
  }
}

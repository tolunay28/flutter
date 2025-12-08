import 'package:flutter/material.dart';

import 'pages/main_page.dart';
import 'pages/page_accueil.dart';

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

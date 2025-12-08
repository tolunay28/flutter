import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PageAccueil extends StatelessWidget {
  const PageAccueil({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme; // eviter repet de cette ligne

    return Scaffold(
      backgroundColor:
          cs.surfaceContainerHighest, // ou cs.surface si tu veux plus clair
      body: Stack(
        children: [
          // ANIMATION DE FOND PLEIN ÉCRAN
          Positioned.fill(
            // utiliser dans stack pour dire au widget de prendre toute la place dispo dans le parent (ici tout l'écran)
            child: Lottie.asset(
              'assets/animations/background.json',
              fit: BoxFit
                  .contain, // permet d'afficher toute l'animation quelque soit la taille de l'écran
              repeat: true,
            ),
          ),

          // CONTENU PAR-DESSUS (protégé par SafeArea)
          SafeArea(
            // padding automatique pour eviter que les textes/image ... soit pas cachés
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start, // met en haut
                  crossAxisAlignment: CrossAxisAlignment
                      .center, // centre horizontalement dans un column
                  children: [
                    const SizedBox(height: 24),

                    Text(
                      'ExplorezVotreVille',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium // style typographique pour titre moyen
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    AnimatedTextKit(
                      isRepeatingAnimation: true,
                      repeatForever: true,
                      pause: const Duration(milliseconds: 900),
                      animatedTexts: [
                        TyperAnimatedText(
                          'Découvrez des lieux incroyables...',
                          speed: const Duration(milliseconds: 40),
                          textStyle: Theme.of(context).textTheme.titleMedium,
                        ),
                        TyperAnimatedText(
                          'Enregistrer vos favoris...',
                          speed: const Duration(milliseconds: 40),
                          textStyle: Theme.of(context).textTheme.titleMedium,
                        ),
                        TyperAnimatedText(
                          'Commentez et partagez !',
                          speed: const Duration(milliseconds: 40),
                          textStyle: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),

                    SizedBox(
                      width: 150,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Commencer'),
                        onPressed: () => Navigator.pushReplacementNamed(
                          context,
                          '/main',
                        ), // pas de bouton back qui s'affiche avec pushReplacement
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(vertical: 16),
                          ),
                          textStyle: WidgetStateProperty.all(
                            const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

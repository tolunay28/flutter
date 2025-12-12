*** Brouillon ***

📡 API & Services — Choix techniques

Cette application utilise plusieurs services externes pour offrir une expérience riche : recherche de villes, météo en temps réel, géocodage d'adresses et récupération d’images.
Les choix techniques suivants privilégient la gratuité, la simplicité et la fiabilité.

🌍 1. Recherche de villes & météo
API : OpenWeatherMap (Geocoding + Weather API)

OpenWeatherMap permet :

la recherche de villes (géocodage),

la récupération de la météo actuelle.

Pourquoi OpenWeatherMap ?

API gratuite avec un bon quota

Données météo fiables

Une seule API pour coordonnées + météo

Documentation claire

Clé API gratuite suffisante

Exemple d’appel (géocodage)
final url = Uri.parse(
  'https://api.openweathermap.org/geo/1.0/direct?q=$query&limit=5&appid=$apiKey',
);

🗺️ 2. Géocodage d’adresses
API : Nominatim (OpenStreetMap)

Utilisée pour :

trouver des coordonnées à partir d'une adresse,

interpréter un nom de lieu,

obtenir une adresse complète (display_name).

⚠️ Elle exige l’ajout d’un User-Agent personnalisé.

Pourquoi Nominatim ?

100 % gratuit

Pas de clé API

Basé sur OpenStreetMap (open data)

Très bon pour rechercher des lieux connus ou approximatifs

Exemple d’appel
final url = Uri.parse(
  'https://nominatim.openstreetmap.org/search'
  '?q=${Uri.encodeComponent(query)}'
  '&format=json&limit=1',
);

🖼️ 3. Recherche automatique d’images
API : Wikimedia / Wikipedia

Si un lieu est ajouté sans image, l’app tente :

de trouver une page Wikipédia correspondant au lieu,

d’en extraire la miniature.

Pourquoi Wikimedia ?

Gratuit, pas de clé API

Idéal pour les monuments, musées, places, etc.

Images libres selon licence Wikimedia

Exemple (recherche d’une page)
final searchUrl = Uri.parse(
  'https://fr.wikipedia.org/w/api.php'
  '?action=query&list=search&format=json'
  '&srsearch=${Uri.encodeComponent(titre)}'
  '&srlimit=1'
);

🧭 4. Localisation de l’utilisateur
Package : Geolocator

Permet de :

demander la permission GPS,

récupérer la position de l’utilisateur,

centrer la carte automatiquement.

Pourquoi Geolocator ?

Facile à intégrer

Gère toutes les permissions

Compatible Android & iOS

Position position = await Geolocator.getCurrentPosition();
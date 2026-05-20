# 🎵 DonZiker - Lecteur de Musique Premium

![DonZiker Banner](https://img.shields.io/badge/Flutter-3.x-blue?style=for-the-badge&logo=flutter)
![Status](https://img.shields.io/badge/Status-Version_1.0.0-green?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-orange?style=for-the-badge)

**DonZiker** est un lecteur de musique moderne, performant et élégant conçu avec Flutter. Il offre une expérience immersive de type Spotify tout en intégrant des fonctionnalités avancées pour les mélomanes et les étudiants (Mode Révision).

---

## ✨ Fonctionnalités Clés

### 🎶 Expérience de Lecture
- **Lecture Premium** : Support de `just_audio` pour une qualité sonore exceptionnelle.
- **Background Service** : Continuez à écouter votre musique même quand l'application est en arrière-plan ou que l'écran est éteint.
- **Mini-Lecteur Persistant** : Contrôlez votre musique depuis n'importe quel écran de l'application.

### 🎓 Mode Révision (Unique)
- **Boucle A-B** : Sélectionnez un segment précis d'une chanson pour le répéter à l'infini. Idéal pour apprendre des paroles ou des partitions.
- **Contrôle de Vitesse** : Ralentissez (0.5x) ou accélérez (2.0x) la lecture sans changer la tonalité.

### 🎨 Design & Personnalisation
- **Interface Spotify-like** : Design sombre, dégradés adaptatifs et bannières héroïques.
- **Thèmes Dynamiques** : Basculez entre le mode Clair et Sombre.
- **Couleurs d'Accentuation** : Personnalisez l'application avec votre couleur préférée (Rouge, Bleu, Vert, etc.).

### 📂 Gestion de Bibliothèque (100 % locale)
- **Aucune musique intégrée** : DonZiker lit uniquement les fichiers déjà sur votre téléphone.
- **Scan & Rescan** : Détection automatique des fichiers audio locaux.
- **Vues** : Chansons, Albums, Artistes, Dossiers, Genres, Playlists personnalisées, Vidéos.
- **Playlists SQLite** : Créer, renommer, supprimer, ajouter des titres.
- **Recherche** : Titre, artiste, album, chemin.
- **Favoris, Historique, Stats** : Données locales uniquement.
- **Paroles `.lrc`** : Fichier du même nom à côté du morceau sur l'appareil.
- **Exclusion de dossiers** : Masquer WhatsApp, notifications, etc.

---

## 🛠️ Stack Technique

- **Framework** : [Flutter](https://flutter.dev/)
- **Gestion d'État** : [Provider](https://pub.dev/packages/provider)
- **Moteur Audio** : [Just Audio](https://pub.dev/packages/just_audio) & [Audio Service](https://pub.dev/packages/audio_service)
- **Base de Données locale** : [Shared Preferences](https://pub.dev/packages/shared_preferences)
- **Permissions** : [Permission Handler](https://pub.dev/packages/permission_handler)
- **UI Components** : Material 3, Google Fonts.

---

## 🚀 Installation & Lancement

### Prérequis
- Flutter SDK (version 3.19+)
- Gradle 8.13+
- Android SDK 21+ (Lollipop)

### Étapes
1. **Cloner le projet**
   ```bash
   git clone https://github.com/votre-repo/donziker.git
   cd donziker
   ```

2. **Installer les dépendances**
   ```bash
   flutter pub get
   ```

3. **Lancer l'application**
   ```bash
   flutter run
   ```

---

## 📱 Configuration Android

Pour assurer le bon fonctionnement de la lecture en arrière-plan, vérifiez les points suivants dans `android/app/build.gradle.kts` :
- `minSdk = 21`
- `compileSdk = flutter.compileSdkVersion`

Le fichier `AndroidManifest.xml` est déjà configuré pour inclure les services `AudioService` et les permissions nécessaires.

---

## 🤝 Contribution

Les contributions, rapports de bugs et suggestions sont les bienvenus ! 
N'hésitez pas à ouvrir une *Issue* ou à soumettre une *Pull Request*.

---

## 👤 Auteur

**DonChaminade** - *Design & Développement*

---

## 📄 License

Distribué sous la licence MIT. Voir `LICENSE` pour plus d'informations.

---
*Fait avec ❤️ pour les passionnés de musique.*

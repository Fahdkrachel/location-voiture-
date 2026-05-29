# BOUSSELHA CARS — Frontend Flutter

Ce répertoire contient l'application cliente de bureau (Windows Desktop) développée en **Flutter** pour le système **BOUSSELHA CARS**.

## 📌 Informations de démarrage rapide

Pour comprendre l'architecture globale, la configuration de l'API avec Dio, la gestion d'état avec Riverpod et les étapes de build en release, merci de consulter le **README principal** à la racine du projet :

👉 **[README Principal du Monorepo](../README.md)**

## ⚡ Commandes de base

### 1. Télécharger les dépendances
```bash
flutter pub get
```

### 2. Lancer l'application en mode développement (Windows)
```bash
flutter run -d windows
```

### 3. Compiler pour la production (Générer le .exe)
```bash
flutter build windows --release
```
L'exécutable `.exe` sera généré dans `build/windows/x64/runner/Release/bousselha_flutter.exe`.

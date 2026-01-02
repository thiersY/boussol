# 🧭 Boussole Pro High-Precision

Une application de boussole moderne, fluide et ultra-précise développée avec Flutter. Conçue pour offrir une expérience utilisateur native avec des outils de navigation avancés.



## ✨ Fonctionnalités

* **Fluidité 60 FPS** : Utilisation d'algorithmes de lissage (Low-pass filter) et de `RepaintBoundary` pour une rotation parfaite sans saccades.
* **Niveau à Bulle Intégré** : Un indicateur central dynamique utilisant l'accéléromètre pour vérifier l'horizontalité de l'appareil.
* **Détecteur de Champ Magnétique (µT)** : Mesure en temps réel de la force magnétique ambiante pour détecter les interférences métalliques.
* **Design Premium** : Interface sombre (Dark Mode) avec typographie dynamique et cadran dont les chiffres suivent l'arc de rotation. (parfait pour les ecran amoled)
* **Étalonnage Intelligent** : Écran d'assistance pour calibrer les capteurs magnétiques.

## 🚀 Performance & Optimisation

L'application a été optimisée pour réduire son empreinte mémoire et maximiser les performances graphiques :
* **Taille réduite** : APK optimisé à ~15 Mo (via split-per-abi).
* **GPU Rendering** : Les calculs complexes du cadran sont isolés pour ne pas surcharger le processeur principal.
* **Obfuscation** : Code binaire protégé et compressé.

## 🛠️ Installation

1.  Téléchargez le dernier APK depuis la section [Releases](https://github.com/thiersY/boussol/releases).
2.  Installez le fichier `app-arm64-v8a-release.apk` sur votre appareil Android.
3.  Autorisez l'accès aux capteurs si demandé.

## 📖 Développement (Build local)

Si vous souhaitez modifier le projet :

### Prérequis
* Flutter SDK (^3.10.4)
* Un appareil Android physique (les simulateurs ne supportent pas les magnétomètres)

### Cloner le projet
```bash
git clone [https://github.com/thiersY/boussol.git](https://github.com/thiersY/boussol.git)
cd boussol

# Nyx — téléchargements

**Nyx est une médiathèque familiale privée** : les films et les séries d'un serveur de maison, à
parcourir, regarder, reprendre et regarder ensemble. Ce dépôt ne contient que les
**installeurs** de l'application. Le code est ailleurs, et le serveur n'est ouvert que sur
invitation.

> Sans invitation, l'application ne sert à rien : elle ne contient aucun film et ne se connecte à
> rien par elle-même.

## Télécharger

➡️ **[La dernière version](https://github.com/MarcBelleperche/Nyx-releases/releases)**, dans
la section *Releases*.

| Système | Fichier | État |
|---|---|---|
| Windows 10 / 11 (64 bits) | `Nyx_<version>_x64-setup.exe` | bêta |
| iPhone, Apple TV | par TestFlight, sur invitation | bêta |

## Installer sur Windows

1. Télécharge `Nyx_…_x64-setup.exe` depuis la dernière release, puis lance-le. Il s'installe
   pour ton compte Windows seulement, sans droits d'administrateur.
2. ⚠️ **Windows va prévenir** (« Windows a protégé votre ordinateur ») : l'installeur n'est pas
   encore signé. Clique sur **Informations complémentaires**, puis **Exécuter quand même**.
3. Le lecteur vidéo, [mpv](https://mpv.io), est inclus : il n'y a rien d'autre à installer.

## Entrer dans Nyx

La personne qui t'invite te donne deux choses :

- **l'adresse du serveur** ;
- **un code d'invitation** de douze caractères. Il sert une seule fois et expire au bout de sept
  jours.

À l'ouverture, choisis **« J'ai un code d'invitation »**, puis saisis l'adresse et le code.
Majuscules, espaces et tirets n'ont pas d'importance. Ton compte est créé : tu choisis ensuite
ton nom, tes genres et ta langue.

Si tu avais déjà un compte sur le Plex de la maison, **« Se connecter avec Plex »** retrouve ton
historique. Pour ajouter un appareil à un compte qui existe déjà, utilise **« Avec ton
iPhone »** : un QR à scanner depuis un appareil déjà relié.

## Ce qui marche

- Le catalogue, les fiches, la recherche et la lecture directe des fichiers, sans transcodage.
- **Regarder ensemble**, synchronisé, avec les autres comptes de la maison.
- Les **recommandations** entre comptes, et les **demandes** de films ou de séries, avec leur
  suivi.
- Tes **statistiques**, qui se remplissent au fil de ce que tu regardes.

## Vie privée

- L'application ne parle qu'au serveur que tu lui donnes. **Aucune télémétrie, aucune
  publicité.**
- Ton accès est rangé dans le trousseau de Windows, pas dans un fichier.
- Ce que tu regardes est enregistré sur le serveur de la maison, pour tes reprises et tes
  statistiques. Le classement de la maison ne te montre que si tu l'acceptes.

## Un souci ?

Dis-le à la personne qui t'a invité, avec l'heure et ce que tu faisais. ⚠️ N'envoie jamais une
capture qui montrerait une adresse contenant `jeton=` : c'est ta clé.

## Licences

L'installeur Windows embarque une copie non modifiée de **mpv**, logiciel libre sous licence GPL
version 2 ou ultérieure. Ses sources : <https://github.com/mpv-player/mpv>, et la construction
Windows utilisée : <https://github.com/shinchiro/mpv-winbuild-cmake>. La version exacte figure
dans les notes de chaque release.

# Nyx

**Nyx est une médiathèque personnelle** : tes films et tes séries, sur ton serveur, à parcourir,
regarder, reprendre et regarder ensemble, sur tous tes écrans.

Ce dépôt contient ce qu'il faut pour **utiliser** Nyx — les applications et le serveur —, pas son
code.

---

## Le principe

```
   ta machine (NAS, mini-PC, serveur)                      tes écrans
 ┌──────────────────────────────────────┐
 │  tes dossiers de films et de séries  │        ┌───────────────────────────┐
 │                │                     │        │  PC · iPhone · iPad · Mac │
 │                ▼                     │◀──────▶│  Apple TV · Android       │
 │  le serveur Nyx                      │        └───────────────────────────┘
 │  catalogue, comptes, reprises,       │
 │  statistiques, séances partagées     │──▶ TMDB · Radarr · Sonarr · Plex
 └──────────────────────────────────────┘     (selon ce que tu as)
```

- **Le serveur** tourne chez toi. Il parcourt tes dossiers, reconnaît chaque film et chaque série,
  et tient le catalogue, les comptes, ce que chacun a vu et où il en est.
- **Les applications** lisent le **fichier d'origine**, avec un vrai lecteur vidéo. Rien n'est
  transcodé : l'image et le son arrivent tels qu'ils sont sur le disque, 4K et Dolby Vision
  compris.
- **Chacun son compte** : sa reprise, ses statistiques, ses recommandations. On regarde aussi
  **ensemble**, chacun sur son écran, synchronisé.
- **Radarr et Sonarr sont facultatifs.** Sans eux, Nyx partage ce que tu as. Avec eux, il sait
  aussi **demander** un film ou une série et suivre son téléchargement.
- **On entre sur invitation.** Le serveur n'est ouvert qu'aux personnes que tu invites, et à
  leurs appareils.

---

## Les applications

| Appareil | Où la trouver | État |
|---|---|---|
| **Windows** 10 / 11 (64 bits) | [Dernière version](https://github.com/MarcBelleperche/Nyx-releases/releases/latest) — `Nyx_<version>_x64-setup.exe` | bêta |
| **iPhone**, **iPad** | TestFlight, sur invitation | bêta |
| **Mac** | TestFlight, sur invitation | bêta |
| **Apple TV** | TestFlight, sur invitation | bêta |
| **Android**, **Android TV** | bientôt | en préparation |
| **Le serveur** (Linux, Docker) | [`installe.sh`](installe.sh) et l'image `ghcr.io/marcbelleperche/nyx-serveur` | bêta |

> Sans serveur, une application ne sert à rien : elle ne contient aucun film et ne se connecte à
> rien par elle-même.

### Installer sur Windows

1. Télécharge `Nyx_…_x64-setup.exe` depuis la
   [dernière version](https://github.com/MarcBelleperche/Nyx-releases/releases/latest), puis
   lance-le. Il s'installe pour ton compte Windows seulement, sans droits d'administrateur.
2. ⚠️ **Windows va prévenir** (« Windows a protégé votre ordinateur ») : l'installeur n'est pas
   encore signé. Clique sur **Informations complémentaires**, puis **Exécuter quand même**.
3. Le lecteur vidéo, [mpv](https://mpv.io), est inclus : il n'y a rien d'autre à installer.

L'application se met ensuite à jour seule : elle propose la nouvelle version à l'ouverture, jamais
pendant une lecture.

### Entrer dans un Nyx

La personne qui t'invite te donne **l'adresse de son serveur** et **un code d'invitation** de
douze caractères (il sert une seule fois et expire au bout de sept jours). À l'ouverture,
choisis **« J'ai un code d'invitation »**, puis saisis l'adresse et le code. Majuscules, espaces et
tirets n'ont pas d'importance. Tu choisis ensuite ton nom, tes genres et ta langue.

- **Tu avais un compte sur le Plex de ce serveur ?** « Se connecter avec Plex » retrouve ton
  compte et ton historique.
- **Un appareil de plus pour ton compte ?** Relie-le depuis un appareil déjà connecté, par un QR
  ou un code à six chiffres.

---

## Héberger ton Nyx

Le serveur s'installe en une commande. Un assistant pose ses questions dans le terminal, vérifie
chaque réponse, et n'installe rien avant la dernière.

### Ce qu'il te faut

| | |
|---|---|
| Une machine Linux allumée en permanence | NAS, mini-PC ou serveur — Intel/AMD ou ARM 64 bits |
| Docker et `docker compose` | <https://docs.docker.com/engine/install/> |
| Tes dossiers de films et de séries | lisibles depuis cette machine |
| Un jeton de lecture TMDB | gratuit : themoviedb.org › Paramètres › API › « Jeton d'accès en lecture ». **Nécessaire sans Radarr ni Sonarr** : c'est lui qui reconnaît les fichiers. |
| Radarr, Sonarr, Plex | facultatifs |

### Installer

```sh
curl -fsSLO https://raw.githubusercontent.com/MarcBelleperche/Nyx-releases/main/installe.sh
chmod +x installe.sh
./installe.sh ~/nyx
```

L'assistant demande, dans l'ordre :

1. **le nom** de l'installation et **le port** (il propose le premier port libre) ;
2. **le dossier des films** et **celui des séries** — il les parcourt et compte les vidéos ;
3. **le jeton TMDB** — vérifié, jamais affiché ;
4. **Radarr et Sonarr**, s'ils sont là : leur adresse et leur `config.xml` (la clé d'API y est
   lue, jamais tapée). Il y crée deux profils de qualité, « Nyx » et « Nyx VF » — une seule
   question, le 4K ou non —, ou reprend ceux qui existent ;
5. **Plex**, s'il est là : reprendre ses comptes, ce qu'ils ont vu, leurs playlists et les
   génériques. Le propriétaire du Plex devient le compte parent de Nyx ;
6. **un nom public en HTTPS**, si tu veux y accéder depuis Internet.

Puis il montre un **récapitulatif**, installe, démarre Nyx, annonce la base de données créée, et
**propose de relier ton premier appareil** par un QR ou un code à six chiffres.
**Ctrl+C quitte à tout instant.**

🔴 `nyx.env`, dans le dossier d'installation, porte les clés de ton serveur. Il n'est lisible que
par toi : ne le copie nulle part.

### Ce que fait Nyx ensuite

- **Il reconnaît seul ce qui arrive sur le disque.** Un fichier dont il n'est pas sûr — nom
  ambigu, remake, plusieurs épisodes dans un fichier — attend dans **« À décider »**, qu'un parent
  tranche depuis l'application.
- **Avec Radarr et Sonarr**, il reprend leur bibliothèque, et les applications proposent
  « Demander », la montée en qualité et les épisodes manquants.
- **Pour inviter quelqu'un**, crée un code depuis ton Profil, dans l'application.

### Au quotidien

| Commande | |
|---|---|
| `./installe.sh --mettre-a-jour ~/nyx` | la dernière version : base sauvegardée, réglages gardés, appareils toujours reliés |
| `./installe.sh --modifier ~/nyx` | revenir sur une étape : dossiers, TMDB, Radarr, Sonarr, Plex, accès Internet, port |
| `./installe.sh --exposer ~/nyx` | donner, changer ou retirer le nom public en HTTPS |
| `./installe.sh --parent ~/nyx` | relier un appareil parent de plus |

Une installation n'est **jamais écrasée** : relancer l'assistant sur un dossier déjà installé le
met à jour. S'il trouve un autre Nyx sur la machine, il propose de le mettre à jour, ou d'en
installer un second à part.

### Depuis Internet

Pour que `https://<ton-nom>` réponde de l'extérieur :

1. **DNS** : un enregistrement A de ce nom vers l'adresse IP publique de ta box, **sans proxy** ;
2. **box** : le port TCP **443** redirigé vers la machine de Nyx.

Nyx obtient seul son certificat HTTPS par ce port. 🔴 Ne redirige **jamais** le port de Nyx
(8088…) : il parle en clair, sans chiffrement.

---

## Vie privée

- **Tout reste chez toi** : la base, les comptes, ce que chacun regarde. Les seuls services
  extérieurs joints par le serveur sont ceux que tu configures : TMDB, Radarr, Sonarr, Plex.
- Les applications ne parlent qu'au serveur que tu leur donnes. **Aucune télémétrie, aucune
  publicité.**
- Sur Windows, ton accès est rangé dans le trousseau du système, pas dans un fichier.
- Le classement partagé entre comptes ne montre que ceux qui l'acceptent.

## Un souci ?

Dis-le à la personne qui t'a invité, avec l'heure et ce que tu faisais. ⚠️ N'envoie jamais une
capture montrant une adresse qui contient `jeton=`, ni le contenu de `nyx.env` : ce sont des clés.

## Licences

- L'installeur Windows embarque une copie non modifiée de **mpv**, logiciel libre sous licence
  GPL version 2 ou ultérieure. Ses sources : <https://github.com/mpv-player/mpv>, et la
  construction Windows utilisée : <https://github.com/shinchiro/mpv-winbuild-cmake>. La version
  exacte figure dans les notes de chaque release.
- L'image du serveur repose sur **Node.js** (licence MIT) et **Alpine Linux**. La porte est
  l'image officielle de **Caddy** (licence Apache 2.0), téléchargée telle quelle depuis Docker Hub

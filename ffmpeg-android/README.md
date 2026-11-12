# FFmpeg dans Nyx pour Android

Ce dossier est **la source complète des bibliothèques FFmpeg** livrées dans l'application Nyx pour
Android et Android TV : de quoi savoir d'où elles viennent, les reconstruire à l'identique, et les
remplacer par les tiennes.

---

## Ce que c'est

- **FFmpeg 8.1.3, non modifié**, sous **licence LGPL version 2.1 ou ultérieure**. Il est configuré
  sans `--enable-gpl`, `--enable-nonfree` ni `--enable-version3`, ce que disent les `config.h` de
  [`configuration/`](configuration).
- **À quoi il sert** : Nyx pour Android lit les films avec Media3 (ExoPlayer) et les décodeurs du
  téléphone. FFmpeg ne sert qu'à **décoder certains sons** que le téléphone ne sait pas décoder
  lui-même, comme le TrueHD ou le DTS. Il ne touche ni à l'image, ni au réseau.
- **Onze décodeurs audio**, rien d'autre : `flac alac pcm_mulaw pcm_alaw mp3 aac ac3 eac3 dca mlp truehd`.
- **En bibliothèques partagées**, séparées et remplaçables, pour chaque ABI (`arm64-v8a`,
  `armeabi-v7a`, `x86`, `x86_64`) :
  - `libavutil.so` (libavutil 60.26.103), `libswresample.so` (libswresample 6.3.103) et
    `libavcodec.so` (libavcodec 62.28.103) : FFmpeg ;
  - `libffmpegJNI.so` : le pont de Media3 entre Java et FFmpeg, qui dépend des trois autres.
- Elles arrivent dans l'application par une extension Android (AAR),
  `fr.divinit.nyx:media3-ffmpeg-decoder:1.9.4+2`. L'application en montre l'origine et les licences
  dans **Profil › Licences et sources**, au téléphone comme à la TV.

## D'où vient chaque morceau

| Morceau | Origine | Licence |
|---|---|---|
| **FFmpeg 8.1.3** | <https://ffmpeg.org/releases/ffmpeg-8.1.3.tar.xz>, signée par la clé de publication de FFmpeg (empreinte `FCF9 86EA 15E6 E293 A564 4F10 B432 2F04 D676 58D8`). La même archive, à l'octet, avec sa signature : [pièces jointes de la release `ffmpeg-android-1.9.4-2`](https://github.com/MarcBelleperche/Nyx-releases/releases/tag/ffmpeg-android-1.9.4-2) | LGPL 2.1 ou ultérieure |
| **Le pont JNI et les classes Java** | [androidx/media](https://github.com/androidx/media) (Media3), tag `1.9.4`, commit `75ccb55ec085d76cbbf12e2f1af8241d378a753a`, module `libraries/decoder_ffmpeg`. `ffmpeg_jni.cc` et les classes Java sont pris tels quels ; seul `CMakeLists.txt` change (ci-dessous) | Apache 2.0 |
| **La chaîne d'outils** | Android NDK r27 pour Linux, la plateforme Android 35, et Debian trixie : l'image `debian:trixie-20261005-slim` épinglée par son empreinte, ses paquets pris dans l'instantané `snapshot.debian.org` du 5 octobre 2026. Chaque téléchargement est vérifié par sa somme ([`recette/versions.sh`](recette/versions.sh)) | — |

L'archive de FFmpeg pèse 11 732 036 octets. Sa somme SHA-256 :
`7138d28c96d9d3e3af4ee3d8cad72741f8ffb40da90c1112235dea3ecd3178a3`.

## Ce que contient ce dossier

| | |
|---|---|
| [`recette/`](recette) | Les scripts exacts qui ont construit les bibliothèques livrées |
| [`recette/versions.sh`](recette/versions.sh) | Tout ce qui est figé : versions, sommes, clé de signature, image, décodeurs, ABI |
| [`recette/construire.sh`](recette/construire.sh) | Le point d'entrée : construit l'atelier Docker, puis lance la compilation |
| [`recette/Dockerfile`](recette/Dockerfile) | L'atelier : Debian, le NDK, la plateforme Android, de quoi configurer FFmpeg |
| [`recette/compiler.sh`](recette/compiler.sh) | Dans le conteneur : sources vérifiées, FFmpeg par ABI, pont JNI, vérifications, AAR |
| [`recette/jni/CMakeLists.txt`](recette/jni/CMakeLists.txt) | Le `CMakeLists.txt` de Media3, modifié : bibliothèques de FFmpeg **partagées** au lieu de statiques, aucun RPATH, l'emplacement de FFmpeg passé en variable. Il reste sous Apache 2.0 |
| [`recette/assembler-aar.py`](recette/assembler-aar.py) | Un zip reproductible (date, ordre et droits fixes) pour l'AAR |
| [`configuration/<abi>/`](configuration) | Les traces de la construction : `config.h`, `config.mak`, `codec_list.c`, `parser_list.c` et la sortie de `configure` |
| [`SHA256SUMS`](SHA256SUMS) | Les sommes de l'archive, de sa signature, des seize `.so` et de l'AAR |
| [`licences/`](licences) | La LGPL 2.1 (`COPYING.LGPLv2.1`), la licence de FFmpeg (`LICENSE-FFmpeg.md`) et l'Apache 2.0 de Media3 |

## Reconstruire

Il faut **Docker** et un shell bash : Linux, macOS, ou Windows avec Git Bash. Rien d'autre : le NDK,
Java et les outils de FFmpeg sont dans l'atelier.

```sh
git clone --branch ffmpeg-android-1.9.4-2 https://github.com/MarcBelleperche/Nyx-releases.git
ici="$PWD/Nyx-releases/ffmpeg-android"
bash "$ici/recette/construire.sh" ~/ffmpeg-travail
(cd ~/ffmpeg-travail && sha256sum -c "$ici/SHA256SUMS")
```

- Le dossier de travail est **le seul monté** dans le conteneur. Il reçoit les sources dans
  `sources/` et les résultats dans `sortie/` : les `.so` dans `sortie/jni/<abi>/`, l'AAR et son POM
  dans `sortie/maven/`, les traces dans `sortie/configuration/`.
- Le premier passage télécharge environ 700 Mo : les paquets Debian, le NDK, la plateforme Android,
  l'archive de FFmpeg (de ffmpeg.org, sinon de la release ci-dessus), Media3 depuis GitHub, et les
  quelques bibliothèques Java qui servent à compiler l'extension. **Tout est vérifié** : sommes,
  signature de FFmpeg, commit de Media3. Compte 10 à 20 minutes.
- `compiler.sh` **échoue** plutôt que de livrer un binaire douteux : licence LGPL dans `config.h`,
  liste exacte des décodeurs, nom de chaque bibliothèque (SONAME), dépendances du pont,
  alignement des segments sur des pages de 16 Kio.
- **La construction est reproductible** : elle redonne les mêmes octets, et `sha256sum -c` doit
  répondre `OK` partout.
- Avec une ABI après le dossier (`construire.sh ~/ffmpeg-travail arm64-v8a`), seules ses
  bibliothèques se construisent, sans AAR.

## Remplacer les bibliothèques (LGPL 2.1, § 6)

Tu as le droit de modifier FFmpeg, de le relier à l'application à la place de celui-ci, et de faire
l'ingénierie inverse nécessaire pour déboguer tes modifications.

- **Ce que charge l'application** : `libavutil.so`, `libswresample.so` et `libavcodec.so`, chacune un
  fichier à part dans `lib/<abi>/` de l'APK. `libffmpegJNI.so` les trouve par leur nom, sans numéro
  de version.
- **Construire les tiennes** : change la source de FFmpeg, ou les options de `configure` dans
  `recette/compiler.sh`, puis lance la recette. Tes bibliothèques sont dans `sortie/jni/<abi>/`.
  ⚠️ Garde les mêmes versions majeures (libavcodec 62, libavutil 60, libswresample 6) : le pont est
  compilé contre elles, et les noms sans version ne protègent pas d'un mélange.
- **Les mettre dans l'application** :
  1. Récupère les APK de l'application installée. Depuis Google Play, il y en a plusieurs, et les
     bibliothèques sont dans celui de l'ABI de l'appareil (`split_config.arm64_v8a.apk`, par
     exemple) : `adb shell pm path fr.divinit.nyx`, puis `adb pull`.
  2. Remplace les fichiers de `lib/<abi>/` par les tiens.
  3. Réaligne l'APK (`zipalign -P 16 -f 4`) : les bibliothèques y restent non compressées, sur des
     pages de 16 Kio.
  4. Signe **tous** les APK avec ta propre clé (`apksigner sign`). Android exige la même clé pour
     tous les morceaux, et refuse une mise à jour signée autrement : désinstalle d'abord
     l'application.
  5. Installe-les ensemble : `adb install-multiple *.apk`.

## Licences

- **FFmpeg** : LGPL 2.1 ou ultérieure ([`licences/COPYING.LGPLv2.1`](licences/COPYING.LGPLv2.1)).
  Certains fichiers de FFmpeg sont sous des licences plus permissives (MIT, BSD) ; aucune de ses
  parties sous GPL n'est compilée ([`licences/LICENSE-FFmpeg.md`](licences/LICENSE-FFmpeg.md)).
- **Le pont et les classes de Media3**, et `recette/jni/CMakeLists.txt` qui en dérive : Apache 2.0
  ([`licences/Apache-2.0-Media3.txt`](licences/Apache-2.0-Media3.txt)).

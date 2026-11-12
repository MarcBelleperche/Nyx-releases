# Ce que l'extension FFmpeg embarque, figé : versions, sommes de contrôle, décodeurs.
# Lu par construire.sh (hors du conteneur) et par compiler.sh (dans le conteneur).
#
# 📌 Les empreintes sont écrites par groupes : la garde au commit refuse une longue suite
# de chiffres et de lettres. Les scripts retirent les espaces avant de comparer.

# FFmpeg, l'archive publiée par ffmpeg.org, signée par sa clé de publication.
FFMPEG_VERSION="8.1.3"
FFMPEG_SHA256="7138d28c 96d9d3e3 af4ee3d8 cad72741 f8ffb40d a90c1112 235dea3e cd3178a3"
FFMPEG_CLE="FCF9 86EA 15E6 E293 A564 4F10 B432 2F04 D676 58D8"

# 🔴 Media3 : le même tag que `media3` dans gradle/libs.versions.toml. Le pont JNI et
# les classes Java de l'extension (Apache 2.0) en viennent, inchangés.
MEDIA3_TAG="1.9.4"
MEDIA3_COMMIT="75ccb55e c085d76c bbf12e2f 1af8241d 378a753a"

# Le NDK de Linux (archive de Google, somme publiée dans son manifeste du SDK).
NDK_VERSION="r27"
NDK_SHA1="5e5cd517 bdb98d7e 0faf2c49 4a304129 1e71bdcc"

# La plateforme Android pour compiler les classes Java (compileSdk de Media3 1.9.4).
PLATEFORME="35"
PLATEFORME_ZIP="platform-35_r02.zip"
PLATEFORME_SHA1="0bb560a9 0a7a2cbd 0dd83482 24d518b6 38fe7949"

# L'image de base, datée, et ses paquets pris dans l'instantané Debian du même jour :
# make, cmake et javac ne changent plus d'une construction à l'autre. 🔴 L'image est épinglée
# par son empreinte (l'index multi-architecture de Docker Hub) : une étiquette se déplace,
# une empreinte non. construire.sh les joint : `debian:…-slim@sha256:…`.
IMAGE_DE_BASE="debian:trixie-20261005-slim"
IMAGE_DE_BASE_EMPREINTE="sha256:a29215f6 a35e51e2 2adffa17 f89e9d2e f06214e6 4a2bad10 d765c46a ea49f11f"
INSTANTANE_DEBIAN="20261005T000000Z"

# Ce qu'il faut pour compiler les classes Java de l'extension (rien n'est embarqué) :
# adresse et SHA-256. Les AAR de Media3 sont au même tag que l'extension.
CLASSPATH_JAVA=(
  "https://dl.google.com/android/maven2/androidx/media3/media3-common/1.9.4/media3-common-1.9.4.aar|7a75d020 0839800f eae0cc15 bfc61661 66475994 515ef951 83b27abe 0527c188"
  "https://dl.google.com/android/maven2/androidx/media3/media3-decoder/1.9.4/media3-decoder-1.9.4.aar|2337461b 4ed4ec3c d32330cd 530d9b47 1d5d45b7 6410f6e0 d66f1331 c9a0bc08"
  "https://dl.google.com/android/maven2/androidx/media3/media3-exoplayer/1.9.4/media3-exoplayer-1.9.4.aar|f362b5e0 afa17654 234ecc6d 61c4d57b 7e299b3f ea550f44 09c7d2b1 be7283cd"
  "https://dl.google.com/android/maven2/androidx/media3/media3-container/1.9.4/media3-container-1.9.4.aar|f73cea4f e8a2bf9e b6462bfb 7a547d1a af55395d 0007eed6 fadb129b 56927c0d"
  "https://dl.google.com/android/maven2/androidx/media3/media3-datasource/1.9.4/media3-datasource-1.9.4.aar|ccaf5530 a31e64df fe2a803f eeeb654e 7e81fc4a 2597f6d9 29ce7a9a ba7ff13e"
  "https://dl.google.com/android/maven2/androidx/media3/media3-extractor/1.9.4/media3-extractor-1.9.4.aar|fb1d260c ea679efd 3568b4b4 b02c9aa1 dd84cef8 47cd50f9 3f50ca02 e59cb20b"
  "https://dl.google.com/android/maven2/androidx/annotation/annotation-jvm/1.9.1/annotation-jvm-1.9.1.jar|1e343917 ebf27ba9 6fe4dc52 b1cad7fd 32b738fb c6355bb6 cd5b3b30 5d7212d0"
  "https://repo1.maven.org/maven2/org/checkerframework/checker-qual/3.43.0/checker-qual-3.43.0.jar|3fbc2e98 f05854c3 df16df9a baa955b9 1b15b3ec ac336232 08ed6424 640ef0f6"
  "https://repo1.maven.org/maven2/com/google/guava/guava/33.3.1-android/guava-33.3.1-android.jar|2c3e41d1 b380f204 4d257947 a3aa82da bf3ae4b9 78622745 254aa18b 6cf89ab0"
)

# L'artefact produit, comme une dépendance Maven ordinaire. Le « +2 » change quand la
# recette change sans que les versions bougent (+2 : la source publique dans SOURCE.txt).
GROUPE_AAR="fr.divinit.nyx"
NOM_AAR="media3-ffmpeg-decoder"
VERSION_AAR="1.9.4+2"
# La somme de l'AAR que cette recette produit, à l'octet. Vérifiée par compiler.sh en fin de
# construction, et par un test de l'application sur l'AAR rangé dans tiers/maven.
# 📌 Elle n'entre pas dans l'AAR : l'écrire ici ne change pas ce qu'on construit.
AAR_SHA256="63454b81 0d81bc05 f82097a8 65e3acfe e2cd2298 3c7004c1 30002454 13d9257c"

# 🔴 La source publique du binaire livré (LGPL 2.1, § 6) : la recette et l'archive exacte de
# FFmpeg, servies par nous sur le dépôt public de Nyx, sous une étiquette par version de
# l'AAR. SOURCE.txt, dans l'AAR puis dans l'APK, cite ces adresses ; compiler.sh vérifie
# qu'elles portent l'étiquette et la version.
ETIQUETTE="ffmpeg-android-1.9.4-2"
RECETTE_URL="https://github.com/MarcBelleperche/Nyx-releases/tree/ffmpeg-android-1.9.4-2/ffmpeg-android"
ARCHIVE_URL="https://github.com/MarcBelleperche/Nyx-releases/releases/download/ffmpeg-android-1.9.4-2/ffmpeg-8.1.3.tar.xz"
ARCHIVE_ORIGINE="https://ffmpeg.org/releases/ffmpeg-8.1.3.tar.xz"

# Le niveau d'API visé par les .so : le minSdk de l'application.
API_MIN="29"

# Les décodeurs : exactement ceux du décodeur de Jellyfin (1.9.0+1), aucun de perdu.
# Media3 n'appelle FFmpeg que pour l'audio (FfmpegLibrary.getCodecName) ; un décodeur
# qu'il ne sait pas nommer ne servirait jamais.
DECODEURS=(flac alac pcm_mulaw pcm_alaw mp3 aac ac3 eac3 dca mlp truehd)

ABIS=(arm64-v8a armeabi-v7a x86 x86_64)

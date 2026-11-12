#!/usr/bin/env bash
# Construit, dans le conteneur, l'extension FFmpeg de Media3 sous LGPL :
#   1. les sources, vérifiées (somme et signature de FFmpeg, commit de Media3) ;
#   2. FFmpeg en bibliothèques partagées, pour chaque ABI ;
#   3. le pont JNI de Media3, relié contre elles ;
#   4. les vérifications : licence, décodeurs, noms des bibliothèques, pages de 16 Kio ;
#   5. l'AAR et son POM, rangés comme dans un dépôt Maven.
#
# Lancé par construire.sh : compiler.sh [abi…] (toutes les ABI de versions.sh sinon).
# 🔴 Une construction partielle (quelques ABI) compile et vérifie les .so, mais n'écrit ni
# l'AAR ni le POM : un AAR à qui manquerait une ABI ne doit jamais entrer dans tiers/maven.
#
# 📌 /travail est le seul dossier monté. Les sources téléchargées y restent : ce sont les
# sources exactes du binaire, à fournir avec lui. On compile dans /construction, à
# l'intérieur du conteneur : le configure de FFmpeg est lent sur un dossier de Windows.
set -euo pipefail
. /atelier/versions.sh
TOUTES_LES_ABIS=("${ABIS[@]}")
[ $# -gt 0 ] && ABIS=("$@")

sans_espaces() { printf '%s' "$1" | tr -d ' '; }
echec() { echo "compiler.sh : $*" >&2; exit 1; }
triees() { printf '%s\n' "$@" | LC_ALL=C sort -u; }

# La liste complète de versions.sh, dans n'importe quel ordre : alors seulement, l'AAR.
complete=0
[ "$(triees "${ABIS[@]}")" = "$(triees "${TOUTES_LES_ABIS[@]}")" ] && complete=1
[ "${#ABIS[@]}" -eq "${#TOUTES_LES_ABIS[@]}" ] || complete=0

# Les adresses publiques que SOURCE.txt citera : celles de cette version, pas d'une autre.
[ "$ETIQUETTE" = "ffmpeg-android-${VERSION_AAR//+/-}" ] \
  || echec "l'étiquette $ETIQUETTE ne correspond pas à la version $VERSION_AAR."
case "$RECETTE_URL" in */tree/"$ETIQUETTE"/ffmpeg-android) ;; *) echec "RECETTE_URL ne pointe pas sur l'étiquette $ETIQUETTE." ;; esac
case "$ARCHIVE_URL" in */releases/download/"$ETIQUETTE"/ffmpeg-"$FFMPEG_VERSION".tar.xz) ;; *) echec "ARCHIVE_URL ne pointe pas sur l'archive de l'étiquette $ETIQUETTE." ;; esac
case "$ARCHIVE_ORIGINE" in */ffmpeg-"$FFMPEG_VERSION".tar.xz) ;; *) echec "ARCHIVE_ORIGINE n'est pas l'archive de FFmpeg $FFMPEG_VERSION." ;; esac

NDK=/opt/ndk
TC=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin
SOURCES=/travail/sources
SORTIE=/travail/sortie
CONSTRUCTION=/construction
mkdir -p "$SOURCES/classpath" "$CONSTRUCTION"
rm -rf "$SORTIE"
mkdir -p "$SORTIE"

# — 1. Les sources ———————————————————————————————————————————————————————————————
archive="$SOURCES/ffmpeg-$FFMPEG_VERSION.tar.xz"
# De ffmpeg.org, sinon de notre copie : la somme et la signature tranchent, pas l'adresse.
[ -f "$archive" ] || curl -fsSL -o "$archive" "$ARCHIVE_ORIGINE" || curl -fsSL -o "$archive" "$ARCHIVE_URL"
[ -f "$archive.asc" ] || curl -fsSL -o "$archive.asc" "$ARCHIVE_ORIGINE.asc" || curl -fsSL -o "$archive.asc" "$ARCHIVE_URL.asc"
[ -f "$SOURCES/ffmpeg-devel.asc" ] || curl -fsSL -o "$SOURCES/ffmpeg-devel.asc" "https://ffmpeg.org/ffmpeg-devel.asc"
echo "$(sans_espaces "$FFMPEG_SHA256")  $archive" | sha256sum -c --quiet - \
  || echec "l'archive de FFmpeg n'a pas la somme attendue."
GNUPGHOME="$(mktemp -d)"
export GNUPGHOME
gpg --quiet --import "$SOURCES/ffmpeg-devel.asc" 2>/dev/null
# 📌 Pas de `grep -q` derrière un tube : avec pipefail, il peut faire échouer à tort la
# commande qui écrit encore. On garde la sortie, puis on y cherche.
verification="$(gpg --status-fd 1 --verify "$archive.asc" "$archive" 2>/dev/null || true)"
grep -qF "VALIDSIG $(sans_espaces "$FFMPEG_CLE")" <<<"$verification" \
  || echec "l'archive de FFmpeg n'est pas signée par sa clé de publication."

media3="$SOURCES/media3-$MEDIA3_TAG"
if [ ! -d "$media3/.git" ]; then
  git clone --quiet --depth 1 --branch "$MEDIA3_TAG" --filter=blob:none --sparse \
    https://github.com/androidx/media "$media3"
fi
git -C "$media3" sparse-checkout set libraries/decoder_ffmpeg
[ "$(git -C "$media3" rev-parse HEAD)" = "$(sans_espaces "$MEDIA3_COMMIT")" ] \
  || echec "le tag $MEDIA3_TAG de Media3 ne pointe pas sur le commit attendu."
module="$media3/libraries/decoder_ffmpeg/src/main"

classpath=""
for entree in "${CLASSPATH_JAVA[@]}"; do
  url="${entree%%|*}"
  fichier="$SOURCES/classpath/${url##*/}"
  [ -f "$fichier" ] || curl -fsSL -o "$fichier" "$url"
  echo "$(sans_espaces "${entree#*|}")  $fichier" | sha256sum -c --quiet - \
    || echec "${url##*/} n'a pas la somme attendue."
  case "$fichier" in
    *.aar) unzip -p "$fichier" classes.jar > "$CONSTRUCTION/$(basename "$fichier" .aar).jar"
           classpath="$classpath:$CONSTRUCTION/$(basename "$fichier" .aar).jar" ;;
    *)     classpath="$classpath:$fichier" ;;
  esac
done

# — 2. FFmpeg, en bibliothèques partagées ———————————————————————————————————————————
# Les options de build_ffmpeg.sh de Media3, sauf : partagé au lieu de statique, la
# licence dite explicitement, rien de détecté d'office (seuls les fils d'exécution sont
# demandés), pas de symboles de débogage, pages de 16 Kio. `--disable-postproc` de
# Media3 n'existe plus depuis FFmpeg 8 : libpostproc a quitté l'arbre.
options=(
  --target-os=android
  --enable-shared --disable-static --enable-pic
  --disable-gpl --disable-nonfree --disable-version3
  --disable-everything --disable-autodetect --enable-pthreads
  --disable-programs --disable-doc --disable-debug --disable-symver
  --disable-avdevice --disable-avformat --disable-swscale --disable-avfilter --disable-network
  --disable-v4l2-m2m --disable-vulkan
  --enable-swresample
  --nm="$TC/llvm-nm" --ar="$TC/llvm-ar" --ranlib="$TC/llvm-ranlib" --strip="$TC/llvm-strip"
)
for decodeur in "${DECODEURS[@]}"; do options+=("--enable-decoder=$decodeur"); done

aar="$CONSTRUCTION/aar"
mkdir -p "$aar"
tar -xJf "$archive" -C "$CONSTRUCTION"
ffmpeg="$CONSTRUCTION/ffmpeg-$FFMPEG_VERSION"

for abi in "${ABIS[@]}"; do
  echo "— $abi"
  liens="-Wl,-z,max-page-size=16384"
  case "$abi" in
    arm64-v8a)   cible=aarch64-linux-android;    propres=(--arch=aarch64 --cpu=armv8-a) ;;
    armeabi-v7a) cible=armv7a-linux-androideabi; propres=(--arch=arm --cpu=armv7-a
                   --extra-cflags="-march=armv7-a -mfloat-abi=softfp")
                 liens="$liens -Wl,--fix-cortex-a8" ;;
    # Comme Media3 : pas d'assembleur sur x86 (relocations de texte refusées par Android).
    x86)         cible=i686-linux-android;       propres=(--arch=x86 --cpu=i686 --disable-asm) ;;
    x86_64)      cible=x86_64-linux-android;     propres=(--arch=x86_64 --cpu=x86-64 --disable-asm) ;;
    *)           echec "ABI inconnue : $abi" ;;
  esac
  installe="$CONSTRUCTION/installe/$abi"
  traces="$SORTIE/configuration/$abi"
  mkdir -p "$traces"

  (
    cd "$ffmpeg"
    ./configure --prefix="$installe" --cross-prefix="$TC/$cible$API_MIN-" \
      --extra-ldflags="$liens" "${propres[@]}" "${options[@]}" > "$traces/configure.txt"
    make -j"$(nproc)" > /dev/null
    make install-libs install-headers > /dev/null
    cp config.h ffbuild/config.mak libavcodec/codec_list.c libavcodec/parser_list.c "$traces/"
    make distclean > /dev/null
  )

  # — 3. Le pont JNI ——————————————————————————————————————————————————————————————
  cmake -S /atelier/jni -B "$CONSTRUCTION/jni-$abi" -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI="$abi" -DANDROID_PLATFORM="android-$API_MIN" -DCMAKE_BUILD_TYPE=Release \
    -DFFMPEG_INSTALLE="$installe" -DMEDIA3_JNI="$module/jni" > /dev/null
  cmake --build "$CONSTRUCTION/jni-$abi" > /dev/null

  mkdir -p "$aar/jni/$abi"
  cp "$installe"/lib/libavutil.so "$installe"/lib/libswresample.so "$installe"/lib/libavcodec.so "$aar/jni/$abi/"
  "$TC/llvm-strip" --strip-unneeded -o "$aar/jni/$abi/libffmpegJNI.so" "$CONSTRUCTION/jni-$abi/libffmpegJNI.so"

  # — 4. Les vérifications ————————————————————————————————————————————————————————
  for ligne in '#define CONFIG_GPL 0' '#define CONFIG_NONFREE 0' '#define CONFIG_VERSION3 0' \
               '#define FFMPEG_LICENSE "LGPL version 2.1 or later"'; do
    grep -qxF "$ligne" "$traces/config.h" || echec "$abi : « $ligne » absent de config.h."
  done
  voulus="$(printf '%s\n' "${DECODEURS[@]}" | LC_ALL=C sort)"
  obtenus="$(grep -oE 'ff_[a-z0-9_]+_decoder' "$traces/codec_list.c" | sed 's/^ff_//; s/_decoder$//' | LC_ALL=C sort)"
  [ "$voulus" = "$obtenus" ] || echec "$abi : les décodeurs ne sont pas ceux de versions.sh."
  for so in "$aar/jni/$abi"/*.so; do
    nom="$(basename "$so")"
    grep -qF "Library soname: [$nom]" <<<"$("$TC/llvm-readelf" -d "$so")" \
      || echec "$abi : $nom n'a pas « $nom » pour nom (SONAME)."
    awk '$1 == "LOAD" && $NF != "0x4000" { exit 1 }' <<<"$("$TC/llvm-readelf" -lW "$so")" \
      || echec "$abi : $nom n'est pas aligné sur des pages de 16 Kio."
  done
  dynamique_jni="$("$TC/llvm-readelf" -d "$aar/jni/$abi/libffmpegJNI.so")"
  for dependance in libavcodec.so libavutil.so libswresample.so; do
    grep -qF "Shared library: [$dependance]" <<<"$dynamique_jni" \
      || echec "$abi : libffmpegJNI.so ne dépend pas de $dependance : FFmpeg y serait lié en statique."
  done
done

# Les .so à part, pour les mesurer et les comparer d'une construction à l'autre.
cp -r "$aar/jni" "$SORTIE/jni"

if [ "$complete" -ne 1 ]; then
  (cd "$SORTIE" && find . -type f ! -name SHA256SUMS | LC_ALL=C sort | xargs sha256sum > SHA256SUMS)
  echo "— Construction partielle (${ABIS[*]}) : les .so sont vérifiés, mais ni AAR ni POM."
  echo "  L'AAR ne se fait qu'avec toutes les ABI de versions.sh : ${TOUTES_LES_ABIS[*]}."
  (cd "$SORTIE/jni" && find . -name '*.so' | LC_ALL=C sort | xargs stat -c '%10s  %n')
  exit 0
fi

# — 5. L'AAR et son POM ———————————————————————————————————————————————————————————
# Les classes Java de Media3, inchangées et dans leur paquet : DefaultRenderersFactory
# cherche androidx.media3.decoder.ffmpeg.FfmpegAudioRenderer par son nom.
mkdir -p "$CONSTRUCTION/classes"
find "$module/java" -name '*.java' | LC_ALL=C sort > "$CONSTRUCTION/sources-java.txt"
# 🔴 `--release 8`, android.jar sur le classpath : les classes de Java viennent du JDK. Contre
# android.jar en bootclasspath, javac ne trouve pas `LambdaMetafactory.metafactory`, qu'il lui
# faut pour chaque lambda (« Unable to find method metafactory ») — AGP y ajoute le
# core-lambda-stubs.jar des build-tools, que l'atelier n'a pas. D8 désucre les lambdas au
# build de l'application, comme pour toute dépendance.
javac --release 8 -classpath "/opt/android/android.jar${classpath}" \
  -encoding UTF-8 -nowarn -Xlint:-options -d "$CONSTRUCTION/classes" @"$CONSTRUCTION/sources-java.txt"
python3 -I /atelier/assembler-aar.py "$aar/classes.jar" "$CONSTRUCTION/classes"

cat > "$aar/AndroidManifest.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="androidx.media3.decoder.ffmpeg">

    <uses-sdk android:minSdkVersion="$API_MIN" />

</manifest>
EOF
cp "$media3/libraries/decoder_ffmpeg/proguard-rules.txt" "$aar/proguard.txt"
: > "$aar/R.txt"
mkdir -p "$aar/META-INF/com/android/build/gradle"
cat > "$aar/META-INF/com/android/build/gradle/aar-metadata.properties" <<EOF
aarFormatVersion=1.0
aarMetadataVersion=1.0
minCompileSdk=$PLATEFORME
minCompileSdkExtension=0
minAndroidGradlePluginVersion=1.0.0
coreLibraryDesugaringEnabled=false
EOF

# 🔴 Les textes de la LGPL voyagent avec le binaire : ils entrent dans l'APK par les
# assets, et l'écran « Licences et sources » peut les montrer tels quels.
licences="$aar/assets/licences/ffmpeg"
mkdir -p "$licences"
cp "$ffmpeg/COPYING.LGPLv2.1" "$ffmpeg/LICENSE.md" "$licences/"
# 📌 Des lignes « Clé : valeur » : l'application lit « Version », « Recette » et « Archive »
# pour les montrer (kit/format, Licences.kt). Ne pas renommer ces clés sans elle.
cat > "$licences/SOURCE.txt" <<EOF
FFmpeg $FFMPEG_VERSION, non modifié, sous licence LGPL 2.1 ou ultérieure.
Lié dynamiquement : libavutil.so, libswresample.so, libavcodec.so, remplaçables.

Version : FFmpeg $FFMPEG_VERSION
Recette : $RECETTE_URL
Archive : $ARCHIVE_URL
Signature : $ARCHIVE_URL.asc
Origine : $ARCHIVE_ORIGINE
SHA-256 : $FFMPEG_SHA256
Étiquette : $ETIQUETTE (extension $VERSION_AAR)

Décodeurs : ${DECODEURS[*]}
Pont JNI et classes Java : androidx/media, tag $MEDIA3_TAG, commit $MEDIA3_COMMIT (Apache 2.0).
ffmpeg_jni.cc et les classes Java sont inchangés ; le CMakeLists.txt de la recette relie le pont
aux bibliothèques partagées.
EOF

depot="$SORTIE/maven/${GROUPE_AAR//.//}/$NOM_AAR/$VERSION_AAR"
mkdir -p "$depot"
python3 -I /atelier/assembler-aar.py "$depot/$NOM_AAR-$VERSION_AAR.aar" "$aar"
cat > "$depot/$NOM_AAR-$VERSION_AAR.pom" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>$GROUPE_AAR</groupId>
  <artifactId>$NOM_AAR</artifactId>
  <version>$VERSION_AAR</version>
  <packaging>aar</packaging>
  <name>Décodeur FFmpeg de Media3 pour Nyx</name>
  <description>L'extension decoder_ffmpeg de Media3 $MEDIA3_TAG, FFmpeg $FFMPEG_VERSION en bibliothèques partagées (LGPL 2.1 ou ultérieure).</description>
  <licenses>
    <license>
      <name>Apache License 2.0 (Media3)</name>
      <url>https://www.apache.org/licenses/LICENSE-2.0.txt</url>
    </license>
    <license>
      <name>GNU Lesser General Public License 2.1 or later (FFmpeg)</name>
      <url>https://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt</url>
    </license>
  </licenses>
  <dependencies>
    <dependency>
      <groupId>androidx.media3</groupId>
      <artifactId>media3-decoder</artifactId>
      <version>$MEDIA3_TAG</version>
      <scope>compile</scope>
      <type>aar</type>
    </dependency>
    <dependency>
      <groupId>androidx.media3</groupId>
      <artifactId>media3-exoplayer</artifactId>
      <version>$MEDIA3_TAG</version>
      <scope>compile</scope>
      <type>aar</type>
    </dependency>
  </dependencies>
</project>
EOF

(cd "$SORTIE" && find . -type f ! -name SHA256SUMS | LC_ALL=C sort | xargs sha256sum > SHA256SUMS)

echo "— Tailles"
(cd "$SORTIE/jni" && find . -name '*.so' | LC_ALL=C sort | xargs stat -c '%10s  %n')
stat -c '%10s  %n' "$depot/$NOM_AAR-$VERSION_AAR.aar"

# La somme attendue (versions.sh) : la même à l'octet, ou la recette a bougé.
obtenue="$(sha256sum "$depot/$NOM_AAR-$VERSION_AAR.aar" | cut -d' ' -f1)"
echo "— AAR $VERSION_AAR : $(printf '%s' "$obtenue" | sed 's/.\{8\}/& /g; s/ $//')"
if [ -z "$AAR_SHA256" ]; then
  echo "  Aucune somme attendue dans versions.sh (AAR_SHA256) : écris celle-ci, par groupes."
elif [ "$obtenue" = "$(sans_espaces "$AAR_SHA256")" ]; then
  echo "  Conforme à versions.sh, à l'octet."
else
  echec "l'AAR n'a pas la somme de versions.sh (AAR_SHA256) : la recette ou l'atelier ont bougé."
fi

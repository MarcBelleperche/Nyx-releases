#!/usr/bin/env bash
# Construit l'extension FFmpeg de Nyx (LGPL) dans un conteneur Docker : FFmpeg en
# bibliothèques partagées, le pont JNI de Media3 relié contre elles, puis l'AAR et son
# POM, rangés comme dans un dépôt Maven.
#
# Usage : outils/ffmpeg/construire.sh <dossier de travail> [abi…]
#   Le dossier de travail reçoit les sources téléchargées (sources/) et les sorties
#   (sortie/). Il est hors du dépôt et c'est le seul dossier monté dans le conteneur.
#
# Il faut Docker, rien d'autre : le NDK, Java et les outils de FFmpeg sont dans l'image.
# Voir docs/ffmpeg-lgpl.md.
set -euo pipefail
ici="$(cd "$(dirname "$0")" && pwd)"
. "$ici/versions.sh"

if [ $# -lt 1 ]; then
  sed -n '6,8p' "$0" >&2
  exit 2
fi
travail="$1"
shift
mkdir -p "$travail"

sans_espaces() { printf '%s' "$1" | tr -d ' '; }
# Sous Git Bash, Docker veut un chemin Windows ; ailleurs, le chemin tel quel.
chemin_pour_docker() { (cd "$1" && { pwd -W 2>/dev/null || pwd; }); }

image="nyx-ffmpeg:$FFMPEG_VERSION-media3-$MEDIA3_TAG"
export MSYS_NO_PATHCONV=1

# 🔴 L'image de base par son empreinte, pas par son étiquette seule.
docker build --tag "$image" \
  --build-arg IMAGE_DE_BASE="$IMAGE_DE_BASE@$(sans_espaces "$IMAGE_DE_BASE_EMPREINTE")" \
  --build-arg INSTANTANE_DEBIAN="$INSTANTANE_DEBIAN" \
  --build-arg NDK_VERSION="$NDK_VERSION" \
  --build-arg NDK_SHA1="$(sans_espaces "$NDK_SHA1")" \
  --build-arg PLATEFORME_ZIP="$PLATEFORME_ZIP" \
  --build-arg PLATEFORME_SHA1="$(sans_espaces "$PLATEFORME_SHA1")" \
  "$(chemin_pour_docker "$ici")"

# Les fichiers écrits dans le dossier de travail appartiennent à qui lance la construction, pas
# à root : `--user`, avec un HOME inscriptible, partout où l'identifiant de l'hôte a un sens
# (Linux, macOS). ⚠️ Pas sous Windows (Git Bash, MSYS, Cygwin) : `id -u` y est inventé, Docker
# Desktop garde le propriétaire root des fichiers déjà écrits, et `rm -rf sortie` échouerait.
utilisateur=()
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) ;;
  *) if uid="$(id -u 2>/dev/null)" && gid="$(id -g 2>/dev/null)" && [ "$uid" != 0 ]; then
       utilisateur=(--user "$uid:$gid" --env HOME=/tmp)
     fi ;;
esac

# (`${…+…}` : un tableau vide sous `set -u` échoue avec le bash 3 de macOS.)
docker run --rm ${utilisateur[@]+"${utilisateur[@]}"} \
  --mount "type=bind,source=$(chemin_pour_docker "$travail"),target=/travail" \
  "$image" "$@"

echo "Sorties : $travail/sortie (le dépôt Maven dans sortie/maven, les sommes dans sortie/SHA256SUMS)."

# L'atelier de l'extension FFmpeg : Debian daté, le NDK d'Android pour Linux, la
# plateforme Android pour compiler les classes Java, et de quoi configurer FFmpeg.
#
# Construit et lancé par construire.sh, qui passe les versions de versions.sh.
# 📌 Rien d'autre n'entre : Debian (instantané daté), Google (NDK, plateforme), puis, au
# moment de compiler, ffmpeg.org, GitHub (androidx/media), le dépôt Maven de Google et
# Maven Central.
ARG IMAGE_DE_BASE
FROM ${IMAGE_DE_BASE}

# Les paquets de l'instantané Debian du jour de l'image, pas ceux du jour de la
# construction : deux constructions à six mois d'écart prennent les mêmes outils.
ARG INSTANTANE_DEBIAN
RUN sed -i \
      -e "s|http://deb.debian.org/debian-security\$|http://snapshot.debian.org/archive/debian-security/${INSTANTANE_DEBIAN}|" \
      -e "s|http://deb.debian.org/debian\$|http://snapshot.debian.org/archive/debian/${INSTANTANE_DEBIAN}|" \
      /etc/apt/sources.list.d/debian.sources \
 && apt-get -o Acquire::Check-Valid-Until=false update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git gnupg unzip xz-utils python3 \
      make gcc libc6-dev cmake ninja-build \
      openjdk-21-jdk-headless \
 && rm -rf /var/lib/apt/lists/* \
 && git config --system --add safe.directory '*'

ARG NDK_VERSION
ARG NDK_SHA1
RUN curl -fsSL -o /tmp/ndk.zip "https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux.zip" \
 && echo "${NDK_SHA1}  /tmp/ndk.zip" | sha1sum -c - \
 && unzip -q /tmp/ndk.zip -d /opt \
 && mv "/opt/android-ndk-${NDK_VERSION}" /opt/ndk \
 && rm /tmp/ndk.zip

ARG PLATEFORME_ZIP
ARG PLATEFORME_SHA1
RUN curl -fsSL -o /tmp/plateforme.zip "https://dl.google.com/android/repository/${PLATEFORME_ZIP}" \
 && echo "${PLATEFORME_SHA1}  /tmp/plateforme.zip" | sha1sum -c - \
 && mkdir -p /opt/android \
 && unzip -q -j /tmp/plateforme.zip '*/android.jar' -d /opt/android \
 && rm /tmp/plateforme.zip

# Le dossier de compilation, inscriptible par l'utilisateur que passe `docker run --user`
# (construire.sh) : le conteneur ne tourne pas en root.
RUN mkdir -p /construction && chmod 1777 /construction

COPY versions.sh compiler.sh assembler-aar.py /atelier/
COPY jni/CMakeLists.txt /atelier/jni/
ENTRYPOINT ["bash", "/atelier/compiler.sh"]

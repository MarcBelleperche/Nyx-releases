# Le pont JNI de Media3 (ffmpeg_jni.cc, inchangé), relié aux bibliothèques PARTAGÉES de
# FFmpeg plutôt qu'à leurs archives statiques : libffmpegJNI.so ne contient plus FFmpeg,
# il en dépend (DT_NEEDED), et chaque bibliothèque de FFmpeg reste un fichier qu'on peut
# remplacer dans l'APK. C'est la condition de la LGPL pour une application distribuée.
#
# Dérivé de libraries/decoder_ffmpeg/src/main/jni/CMakeLists.txt de androidx/media
# (Apache 2.0) ; seuls changent STATIC → SHARED, l'emplacement de FFmpeg et le RPATH.
#
# Variables attendues :
#   FFMPEG_INSTALLE  l'installation de FFmpeg pour cette ABI (include/, lib/)
#   MEDIA3_JNI       le dossier jni du module decoder_ffmpeg de Media3
cmake_minimum_required(VERSION 3.21.0 FATAL_ERROR)

set(CMAKE_CXX_STANDARD 11)
# Les chemins absolus de la construction n'ont rien à faire dans le binaire : sur
# l'appareil, les bibliothèques se trouvent dans le dossier natif de l'application.
set(CMAKE_SKIP_BUILD_RPATH ON)

project(libffmpegJNI C CXX)

foreach(ffmpeg_lib avutil swresample avcodec)
    add_library(${ffmpeg_lib} SHARED IMPORTED)
    set_target_properties(${ffmpeg_lib} PROPERTIES
        IMPORTED_LOCATION ${FFMPEG_INSTALLE}/lib/lib${ffmpeg_lib}.so)
endforeach()

include_directories(${FFMPEG_INSTALLE}/include)
find_library(android_log_lib log)

add_library(ffmpegJNI SHARED ${MEDIA3_JNI}/ffmpeg_jni.cc)

target_link_libraries(ffmpegJNI
                      PRIVATE android
                      PRIVATE swresample
                      PRIVATE avcodec
                      PRIVATE avutil
                      PRIVATE ${android_log_lib})

# Repris de Media3 (NDK 23.1 et plus, arm64-v8a).
if(ANDROID_ABI STREQUAL "arm64-v8a")
    target_link_options(ffmpegJNI PRIVATE "-Wl,-Bsymbolic")
endif()

# Pages de 16 Kio (Android 15 et plus, exigé par Google Play).
target_link_options(ffmpegJNI PRIVATE "-Wl,-z,max-page-size=16384")

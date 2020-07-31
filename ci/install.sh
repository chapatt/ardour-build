#!/bin/bash

# we assuem ardour source code is located at /home/ardour
# and this script is /home/ardour-build/install.sh
# and mingw packages will be saved at /home/mingw-pkgs

rawurlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  # echo "${encoded}"    # You can either set a return variable (FASTER) 
  REPLY="${encoded}"   #+or echo the result (EASIER)... or both... :p
}

ROOT=/home/ardour
ARCH=x86_64 # i686 or x86_64
XARCH=win64 # win32 or win64
WARCH=w64 # w32 or w64

if [ ! -d "/home/mingw-pkgs" ]; then
	mkdir -p /home/mingw-pkgs
fi

if [ ! -d "${ROOT}/win-stack-${WARCH}" ]; then
	mkdir -p ${ROOT}/win-stack-${WARCH}
fi

pushd "`/usr/bin/dirname \"$0\"`" > /dev/null; this_script_dir="`pwd`"; popd > /dev/null
cd $this_script_dir/../mingw-pkgs
pwd

# https://repo.msys2.org/mingw
# https://mirrors.tuna.tsinghua.edu.cn/msys2/mingw
# https://mirrors.ustc.edu.cn/msys2/mingw
MIRROR="https://repo.msys2.org/mingw"

# Mingw packages
FLAC="mingw-w64-${ARCH}-flac-1.3.3-1-any.pkg.tar.xz"
BOOST="mingw-w64-${ARCH}-boost-1.73.0-4-any.pkg.tar.zst"
PCRE="mingw-w64-${ARCH}-pcre-8.44-1-any.pkg.tar.xz"
GLIB2="mingw-w64-${ARCH}-glib2-2.64.3-1-any.pkg.tar.zst"
# url encoded
LIBSIGCPP="mingw-w64-${ARCH}-libsigc++-2.10.3-1-any.pkg.tar.xz"
GLIBMM="mingw-w64-${ARCH}-glibmm-2.64.2-1-any.pkg.tar.xz"
LIBFFI="mingw-w64-${ARCH}-libffi-3.3-1-any.pkg.tar.xz"
LIBSNDFILE="mingw-w64-${ARCH}-libsndfile-1.0.28-1-any.pkg.tar.xz"
GCCLIBS="mingw-w64-${ARCH}-gcc-libs-10.2.0-1-any.pkg.tar.zst"
FONTCONFIG="mingw-w64-${ARCH}-fontconfig-2.13.92-1-any.pkg.tar.zst"
BROTLI="mingw-w64-${ARCH}-brotli-1.0.7-4-any.pkg.tar.xz"
GRAPHITE2="mingw-w64-${ARCH}-graphite2-1.3.14-1-any.pkg.tar.xz"
LIBPNG="mingw-w64-${ARCH}-libpng-1.6.37-3-any.pkg.tar.xz"
HARFBUZZ="mingw-w64-${ARCH}-harfbuzz-2.6.8-1-any.pkg.tar.zst"
BZIP2="mingw-w64-${ARCH}-bzip2-1.0.8-1-any.pkg.tar.xz"
FREETYPE="mingw-w64-${ARCH}-freetype-2.10.2-2-any.pkg.tar.zst"
LZO2="mingw-w64-${ARCH}-lzo2-2.10-1-any.pkg.tar.xz"
ZLIB="mingw-w64-${ARCH}-zlib-1.2.11-7-any.pkg.tar.xz"
PIXMAN="mingw-w64-${ARCH}-pixman-0.40.0-1-any.pkg.tar.xz"
CAIRO="mingw-w64-${ARCH}-cairo-1.16.0-3-any.pkg.tar.zst"
CAIROMM="mingw-w64-${ARCH}-cairomm-1.12.2-2-any.pkg.tar.xz"
READLINE="mingw-w64-${ARCH}-readline-8.0.004-1-any.pkg.tar.xz"
TERMCAP="mingw-w64-${ARCH}-termcap-1.3.1-5-any.pkg.tar.xz"
EXPAT="mingw-w64-${ARCH}-expat-2.2.9-1-any.pkg.tar.xz"
LIBICONV="mingw-w64-${ARCH}-libiconv-1.16-1-any.pkg.tar.xz"
GETTEXT="mingw-w64-${ARCH}-gettext-0.19.8.1-9-any.pkg.tar.zst"
LIBTRE="mingw-w64-${ARCH}-libtre-git-r128.6fb7206-2-any.pkg.tar.xz"
# provided regex.h
LIBSYSTRE="mingw-w64-${ARCH}-libsystre-1.0.1-4-any.pkg.tar.xz"
RUBBERBAND="mingw-w64-${ARCH}-rubberband-1.8.2-1-any.pkg.tar.xz"
LIBARCHIVE="mingw-w64-${ARCH}-libarchive-3.4.3-1-any.pkg.tar.zst"
CURL="mingw-w64-${ARCH}-curl-7.71.0-1-any.pkg.tar.zst"
TAGLIB="mingw-w64-${ARCH}-taglib-1.11.1-1-any.pkg.tar.xz"
VAMP_PLUGIN_SDK="mingw-w64-${ARCH}-vamp-plugin-sdk-2.9.0-1-any.pkg.tar.xz"
FFTW="mingw-w64-${ARCH}-fftw-3.3.8-2-any.pkg.tar.zst"
LIBXML2="mingw-w64-${ARCH}-libxml2-2.9.10-4-any.pkg.tar.zst"
CPPUNIT="mingw-w64-${ARCH}-cppunit-1.15.1-1-any.pkg.tar.xz"
LIBUSB="mingw-w64-${ARCH}-libusb-1.0.23-1-any.pkg.tar.xz"
LIBWEBSOCKETS="mingw-w64-${ARCH}-libwebsockets-4.0.20-1-any.pkg.tar.zst"
GDK_PIXBUF2="mingw-w64-${ARCH}-gdk-pixbuf2-2.40.0-1-any.pkg.tar.xz"
ATK="mingw-w64-${ARCH}-atk-2.36.0-1-any.pkg.tar.xz"
ATKMM="mingw-w64-${ARCH}-atkmm-2.28.0-1-any.pkg.tar.xz"
GTK2="mingw-w64-${ARCH}-gtk2-2.24.32-4-any.pkg.tar.xz"
GTKMM="mingw-w64-${ARCH}-gtkmm-2.24.5-2-any.pkg.tar.xz"
FRIBIDI="mingw-w64-${ARCH}-fribidi-1.0.9-1-any.pkg.tar.xz"
LIBDATRIE="mingw-w64-${ARCH}-libdatrie-0.2.12-1-any.pkg.tar.xz"
LIBTHAI="mingw-w64-${ARCH}-libthai-0.1.28-2-any.pkg.tar.xz"
PANGO="mingw-w64-${ARCH}-pango-1.43.0-3-any.pkg.tar.xz"
PANGOMM="mingw-w64-${ARCH}-pangomm-2.42.1-1-any.pkg.tar.xz"
LIBSAMPLERATE="mingw-w64-${ARCH}-libsamplerate-0.1.9-1-any.pkg.tar.xz"
FFMPEG="mingw-w64-${ARCH}-ffmpeg-4.3-2-any.pkg.tar.zst"
LIBVORBIS="mingw-w64-${ARCH}-libvorbis-1.3.6-1-any.pkg.tar.xz"
PORTAUDIO="mingw-w64-${ARCH}-portaudio-190600_20161030-3-any.pkg.tar.xz"
OPUS="mingw-w64-${ARCH}-opus-1.3.1-1-any.pkg.tar.xz"
CELT="mingw-w64-${ARCH}-celt-0.11.3-4-any.pkg.tar.xz"
LIBOGG="mingw-w64-${ARCH}-libogg-1.3.4-3-any.pkg.tar.xz"

ZSTD="mingw-w64-${ARCH}-zstd-1.4.5-1-any.pkg.tar.zst"
LZ4="mingw-w64-${ARCH}-lz4-1.9.2-1-any.pkg.tar.xz"
SPEEX="mingw-w64-${ARCH}-speex-1.2.0-1-any.pkg.tar.xz"
LIBUNISTRING="mingw-w64-${ARCH}-libunistring-0.9.10-2-any.pkg.tar.zst"
XZ="mingw-w64-${ARCH}-xz-5.2.5-1-any.pkg.tar.xz"
LIBSSH2="mingw-w64-${ARCH}-libssh2-1.9.0-2-any.pkg.tar.zst"
LIBPSL="mingw-w64-${ARCH}-libpsl-0.21.0-2-any.pkg.tar.xz"
NGHTTP2="mingw-w64-${ARCH}-nghttp2-1.41.0-1-any.pkg.tar.zst"
LIBIDN2="mingw-w64-${ARCH}-libidn2-2.3.0-1-any.pkg.tar.xz"
OPENSSL="mingw-w64-${ARCH}-openssl-1.1.1.g-1-any.pkg.tar.xz"
LIBJPEG_TURBO="mingw-w64-${ARCH}-libjpeg-turbo-2.0.5-1-any.pkg.tar.zst"
LIBTIFF="mingw-w64-${ARCH}-libtiff-4.1.0-1-any.pkg.tar.xz"

JACK="mingw64-jack-1.9.10.24.g042b6aa-lp152.1.30.noarch.rpm"
JACK_DEVEL="mingw64-jack-devel-1.9.10.24.g042b6aa-lp152.1.30.noarch.rpm"

LIBLO="mingw-w64-liblo-0.28-3-any.pkg.tar.xz"

# source library
# LIBLO="liblo-0.30.tar.gz"
LV2="lv2-1.18.0.tar.bz2"
SERD="serd-0.30.4-g227565f.tar.bz2"
SORD="sord-0.16.4-g61d9657.tar.bz2"
SRATOM="sratom-0.6.4-g2ed87d0.tar.bz2"
LILV="lilv-0.24.8-g20f2351.tar.bz2"
SUIL="suil-0.10.7-gb402ae4.tar.bz2"
# AUBIO="aubio-0.4.7.tar.bz2"
AUBIO="aubio-0.4.6-${XARCH}.zip"

cd /home/mingw-pkgs

if [ ! -f "${FLAC}" ]; then
	wget ${MIRROR}/${ARCH}/${FLAC}
fi

if [ ! -f "${BOOST}" ]; then
	wget ${MIRROR}/${ARCH}/${BOOST}
fi

if [ ! -f "${PCRE}" ]; then
	wget ${MIRROR}/${ARCH}/${PCRE}
fi

if [ ! -f "${GLIB2}" ]; then
	wget ${MIRROR}/${ARCH}/${GLIB2}
fi

if [ ! -f "${LIBSIGCPP}" ]; then
	# mingw-w64-${ARCH}-libsigc++
	rawurlencode ${LIBSIGCPP}
	LIBSIGCPP_URLENCODE=${REPLY}
	wget ${MIRROR}/${ARCH}/${LIBSIGCPP_URLENCODE}
fi

if [ ! -f "${GLIBMM}" ]; then
	wget ${MIRROR}/${ARCH}/${GLIBMM}
fi

if [ ! -f "${LIBFFI}" ]; then
	wget ${MIRROR}/${ARCH}/${LIBFFI}
fi

if [ ! -f "${LIBSNDFILE}" ]; then
	wget ${MIRROR}/${ARCH}/${LIBSNDFILE}
fi

if [ ! -f "${GCCLIBS}" ]; then
	wget ${MIRROR}/${ARCH}/${GCCLIBS}
fi

if [ ! -f "${FONTCONFIG}" ]; then
	wget ${MIRROR}/${ARCH}/${FONTCONFIG}
fi

if [ ! -f "${BROTLI}" ]; then
	wget ${MIRROR}/${ARCH}/${BROTLI}
fi

if [ ! -f "${GRAPHITE2}" ]; then
	wget ${MIRROR}/${ARCH}/${GRAPHITE2}
fi

if [ ! -f "${LIBPNG}" ]; then
	wget ${MIRROR}/${ARCH}/${LIBPNG}
fi

if [ ! -f "${HARFBUZZ}" ]; then
	wget ${MIRROR}/${ARCH}/${HARFBUZZ}
fi

if [ ! -f "${BZIP2}" ]; then
	wget ${MIRROR}/${ARCH}/${BZIP2}
fi

if [ ! -f "${FREETYPE}" ]; then
	wget ${MIRROR}/${ARCH}/${FREETYPE}
fi

if [ ! -f "${LZO2}" ]; then
	wget ${MIRROR}/${ARCH}/${LZO2}
fi

if [ ! -f "${ZLIB}" ]; then
	wget ${MIRROR}/${ARCH}/${ZLIB}
fi

if [ ! -f "${PIXMAN}" ]; then
	wget ${MIRROR}/${ARCH}/${PIXMAN}
fi

if [ ! -f "${CAIRO}" ]; then
	wget ${MIRROR}/${ARCH}/${CAIRO}
fi

if [ ! -f "${CAIROMM}" ]; then
	wget ${MIRROR}/${ARCH}/${CAIROMM}
fi

if [ ! -f "${READLINE}" ]; then
	wget ${MIRROR}/${ARCH}/${READLINE}
fi

if [ ! -f "${TERMCAP}" ]; then
	wget ${MIRROR}/${ARCH}/${TERMCAP}
fi

if [ ! -f "${EXPAT}" ]; then
	wget ${MIRROR}/${ARCH}/${EXPAT}
fi

if [ ! -f "${LIBICONV}" ]; then
	wget ${MIRROR}/${ARCH}/${LIBICONV}
fi

if [ ! -f "${GETTEXT}" ]; then
	wget ${MIRROR}/${ARCH}/${GETTEXT}
fi

if [ ! -f "${LIBTRE}" ]; then
	# mingw-w64-${ARCH}-libtre
	wget ${MIRROR}/${ARCH}/${LIBTRE}
fi

if [ ! -f "${LIBSYSTRE}" ]; then
	# mingw-w64-${ARCH}-libgnurx
	wget ${MIRROR}/${ARCH}/${LIBSYSTRE}
fi

if [ ! -f "${RUBBERBAND}" ]; then
	wget ${MIRROR}/${ARCH}/${RUBBERBAND}
fi

if [ ! -f "${LIBARCHIVE}" ]; then
	wget ${MIRROR}/${ARCH}/${LIBARCHIVE}
fi

if [ ! -f "${CURL}" ]; then
	wget ${MIRROR}/${ARCH}/${CURL}
fi

if [ ! -f "${TAGLIB}" ]; then
	wget ${MIRROR}/${ARCH}/${TAGLIB}
fi

if [ ! -f "${VAMP_PLUGIN_SDK}" ]; then
	wget ${MIRROR}/${ARCH}/${VAMP_PLUGIN_SDK}
fi

if [ ! -f "${FFTW}" ]; then
	wget ${MIRROR}/${ARCH}/${FFTW}
fi

# if [ ! -f "${LIBLO}" ]; then
# 	# liblo source build
# 	wget https://github.com/radarsat1/liblo/releases/download/0.30/${LIBLO}
# fi

if [ ! -f "${LIBXML2}" ]; then
	wget ${MIRROR}/${ARCH}/${LIBXML2}
fi

if [ ! -f "${CPPUNIT}" ]; then
	wget ${MIRROR}/${ARCH}/${CPPUNIT}
fi

if [ ! -f "${LIBUSB}" ]; then
	wget ${MIRROR}/${ARCH}/${LIBUSB}
fi

if [ ! -f "${LIBWEBSOCKETS}" ]; then
	wget ${MIRROR}/${ARCH}/${LIBWEBSOCKETS}
fi

if [ ! -f "${GDK_PIXBUF2}" ]; then
	wget ${MIRROR}/${ARCH}/${GDK_PIXBUF2}
fi

if [ ! -f "${ATK}" ]; then
	wget ${MIRROR}/${ARCH}/${ATK}
fi

if [ ! -f "${ATKMM}" ]; then
	wget ${MIRROR}/${ARCH}/${ATKMM}
fi

if [ ! -f "${GTK2}" ]; then
	wget ${MIRROR}/${ARCH}/${GTK2}
fi

if [ ! -f "${GTKMM}" ]; then
	wget ${MIRROR}/${ARCH}/${GTKMM}
fi

if [ ! -f "${FRIBIDI}" ]; then
	wget ${MIRROR}/${ARCH}/${FRIBIDI}
fi

if [ ! -f "${LIBICONV}" ]; then
	wget ${MIRROR}/${ARCH}/${LIBICONV}
fi

if [ ! -f "${LIBDATRIE}" ]; then
	wget ${MIRROR}/${ARCH}/${LIBDATRIE}
fi

if [ ! -f "${LIBTHAI}" ]; then
	wget ${MIRROR}/${ARCH}/${LIBTHAI}
fi

if [ ! -f "${PANGO}" ]; then
	wget ${MIRROR}/${ARCH}/${PANGO}
fi

if [ ! -f "${PANGOMM}" ]; then
	wget ${MIRROR}/${ARCH}/${PANGOMM}
fi

if [ ! -f "${LV2}" ]; then
	# lv2 source build
	wget https://lv2plug.in/spec/${LV2}
fi

if [ ! -f "${AUBIO}" ]; then
	# aubio source build
	# wget https://aubio.org/pub/${AUBIO}
	wget https://aubio.org/bin/0.4.6/${AUBIO}
fi

if [ ! -f "${LIBSAMPLERATE}" ]; then
	wget ${MIRROR}/${ARCH}/${LIBSAMPLERATE}
fi

if [ ! -f "${FFMPEG}" ]; then
	wget ${MIRROR}/${ARCH}/${FFMPEG}
fi

if [ ! -f "${LIBVORBIS}" ]; then
	wget ${MIRROR}/${ARCH}/${LIBVORBIS}
fi

if [ ! -f "${PORTAUDIO}" ]; then
	wget ${MIRROR}/${ARCH}/${PORTAUDIO}
fi

if [ ! -f "${OPUS}" ]; then
	wget ${MIRROR}/${ARCH}/${OPUS}
fi

if [ ! -f "${CELT}" ]; then
	wget ${MIRROR}/${ARCH}/${CELT}
fi

if [ ! -f "${LIBOGG}" ]; then
	wget ${MIRROR}/${ARCH}/${LIBOGG}
fi

if [ ! -f "${ZSTD}" ]; then
	wget ${MIRROR}/${ARCH}/${ZSTD}
fi

if [ ! -f "${LZ4}" ]; then
	wget ${MIRROR}/${ARCH}/${LZ4}
fi

if [ ! -f "${SPEEX}" ]; then
	wget ${MIRROR}/${ARCH}/${SPEEX}
fi

if [ ! -f "${LIBUNISTRING}" ]; then
	wget ${MIRROR}/${ARCH}/${LIBUNISTRING}
fi

if [ ! -f "${XZ}" ]; then
	wget ${MIRROR}/${ARCH}/${XZ}
fi

if [ ! -f "${LIBSSH2}" ]; then
	wget ${MIRROR}/${ARCH}/${LIBSSH2}
fi

if [ ! -f "${LIBPSL}" ]; then
	wget ${MIRROR}/${ARCH}/${LIBPSL}
fi

if [ ! -f "${NGHTTP2}" ]; then
	wget ${MIRROR}/${ARCH}/${NGHTTP2}
fi

if [ ! -f "${LIBIDN2}" ]; then
	wget ${MIRROR}/${ARCH}/${LIBIDN2}
fi

if [ ! -f "${OPENSSL}" ]; then
	wget ${MIRROR}/${ARCH}/${OPENSSL}
fi

if [ ! -f "${LIBJPEG_TURBO}" ]; then
	wget ${MIRROR}/${ARCH}/${LIBJPEG_TURBO}
fi

if [ ! -f "${LIBTIFF}" ]; then
	wget ${MIRROR}/${ARCH}/${LIBTIFF}
fi

if [ ! -f "${JACK}" ]; then
	# mingw64-jack
	wget https://download.opensuse.org/repositories/windows:/mingw:/${XARCH}/openSUSE_Leap_15.2/noarch/${JACK}
fi

if [ ! -f "${JACK_DEVEL}" ]; then
	# mingw64-jack-devel
	wget https://download.opensuse.org/repositories/windows:/mingw:/${XARCH}/openSUSE_Leap_15.2/noarch/${JACK_DEVEL}
fi

if [ ! -f "${LIBLO}" ]; then
	# suil source build
	wget https://master.dl.sourceforge.net/project/janfla/aur/mingw/${LIBLO}
fi

if [ ! -f "${SERD}" ]; then
	# serd source build
	wget https://ardour.org/files/deps/${SERD}
fi

if [ ! -f "${SORD}" ]; then
	# sord source build
	wget https://ardour.org/files/deps/${SORD}
fi

if [ ! -f "${SRATOM}" ]; then
	# sratom source build`
	wget https://ardour.org/files/deps/${SRATOM}
fi

if [ ! -f "${LILV}" ]; then
	# lilv source build
	wget https://ardour.org/files/deps/${LILV}
fi

if [ ! -f "${SUIL}" ]; then
	# suil source build
	wget https://ardour.org/files/deps/${SUIL}
fi

cd ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${FLAC} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -I zstd -xf /home/mingw-pkgs/${BOOST} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${PCRE} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -I zstd -xf /home/mingw-pkgs/${GLIB2} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/
mv ${ROOT}/win-stack-${WARCH}/lib/glib-2.0/include/glibconfig.h ${ROOT}/win-stack-${WARCH}/include
rm -rf ${ROOT}/win-stack-${WARCH}/lib/glib-2.0
rsync -av --remove-source-files ${ROOT}/win-stack-${WARCH}/include/gio-win32-2.0/* ${ROOT}/win-stack-${WARCH}/include
rsync -av --remove-source-files ${ROOT}/win-stack-${WARCH}/include/glib-2.0/* ${ROOT}/win-stack-${WARCH}/include
rm -rf ${ROOT}/win-stack-${WARCH}/include/gio-win32-2.0
rm -rf ${ROOT}/win-stack-${WARCH}/include/glib-2.0

tar -xJf /home/mingw-pkgs/${LIBSIGCPP} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/
mv ${ROOT}/win-stack-${WARCH}/lib/sigc++-2.0/include/sigc++config.h ${ROOT}/win-stack-${WARCH}/include
rm -rf ${ROOT}/win-stack-${WARCH}/lib/sigc++-2.0
mv ${ROOT}/win-stack-${WARCH}/include/sigc++-2.0/sigc++ ${ROOT}/win-stack-${WARCH}/include
rm -rf ${ROOT}/win-stack-${WARCH}/include/sigc++-2.0

tar -xJf /home/mingw-pkgs/${GLIBMM} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/
mv ${ROOT}/win-stack-${WARCH}/lib/giomm-2.4/include/giommconfig.h ${ROOT}/win-stack-${WARCH}/include
mv ${ROOT}/win-stack-${WARCH}/lib/glibmm-2.4/include/glibmmconfig.h ${ROOT}/win-stack-${WARCH}/include
rsync -av --remove-source-files ${ROOT}/win-stack-${WARCH}/lib/glibmm-2.4/proc ${ROOT}/win-stack-${WARCH}
rm -rf ${ROOT}/win-stack-${WARCH}/lib/giomm-2.4
rm -rf ${ROOT}/win-stack-${WARCH}/lib/glibmm-2.4
rsync -av --remove-source-files ${ROOT}/win-stack-${WARCH}/include/giomm-2.4/* ${ROOT}/win-stack-${WARCH}/include
rsync -av --remove-source-files ${ROOT}/win-stack-${WARCH}/include/glibmm-2.4/* ${ROOT}/win-stack-${WARCH}/include
rm -rf ${ROOT}/win-stack-${WARCH}/include/giomm-2.4
rm -rf ${ROOT}/win-stack-${WARCH}/include/glibmm-2.4

tar -xJf /home/mingw-pkgs/${LIBFFI} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${LIBSNDFILE} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -I zstd -xf /home/mingw-pkgs/${GCCLIBS} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -I zstd -xf /home/mingw-pkgs/${FONTCONFIG} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${BROTLI} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${GRAPHITE2} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${LIBPNG} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -I zstd -xf /home/mingw-pkgs/${HARFBUZZ} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${BZIP2} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -I zstd -xf /home/mingw-pkgs/${FREETYPE} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/
mv ${ROOT}/win-stack-${WARCH}/include/freetype2/* ${ROOT}/win-stack-${WARCH}/include
rm -rf ${ROOT}/win-stack-${WARCH}/include/freetype2

tar -xJf /home/mingw-pkgs/${LZO2} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${ZLIB} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${PIXMAN} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -I zstd -xf /home/mingw-pkgs/${CAIRO} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/
cp ${ROOT}/win-stack-${WARCH}/include/cairo/* ${ROOT}/win-stack-${WARCH}/include

tar -xJf /home/mingw-pkgs/${CAIROMM} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/
mv ${ROOT}/win-stack-${WARCH}/lib/cairomm-1.0/include/cairommconfig.h ${ROOT}/win-stack-${WARCH}/include
rm -rf ${ROOT}/win-stack-${WARCH}/lib/cairomm-1.0
mv ${ROOT}/win-stack-${WARCH}/include/cairomm-1.0/* ${ROOT}/win-stack-${WARCH}/include
rm -rf ${ROOT}/win-stack-${WARCH}/include/cairomm-1.0

tar -xJf /home/mingw-pkgs/${READLINE} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${TERMCAP} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${EXPAT} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${LIBICONV} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -I zstd -xf /home/mingw-pkgs/${GETTEXT} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${LIBTRE} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${LIBSYSTRE} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${RUBBERBAND} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -I zstd -xf /home/mingw-pkgs/${LIBARCHIVE} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -I zstd -xf /home/mingw-pkgs/${CURL} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${TAGLIB} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${VAMP_PLUGIN_SDK} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -I zstd -xf /home/mingw-pkgs/${FFTW} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -I zstd -xf /home/mingw-pkgs/${LIBXML2} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/
mv ${ROOT}/win-stack-${WARCH}/include/libxml2/* ${ROOT}/win-stack-${WARCH}/include
rm -rf ${ROOT}/win-stack-${WARCH}/include/libxml2

tar -xJf /home/mingw-pkgs/${CPPUNIT} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${LIBUSB} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/
mv ${ROOT}/win-stack-${WARCH}/include/libusb-1.0/* ${ROOT}/win-stack-${WARCH}/include
rm -rf ${ROOT}/win-stack-${WARCH}/include/libusb-1.0

tar -I zstd -xf /home/mingw-pkgs/${LIBWEBSOCKETS} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${GDK_PIXBUF2} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/
mv ${ROOT}/win-stack-${WARCH}/include/gdk-pixbuf-2.0/* ${ROOT}/win-stack-${WARCH}/include
rm -rf ${ROOT}/win-stack-${WARCH}/include/gdk-pixbuf-2.0

tar -xJf /home/mingw-pkgs/${ATK} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/
mv ${ROOT}/win-stack-${WARCH}/include/atk-1.0/* ${ROOT}/win-stack-${WARCH}/include
rm -rf ${ROOT}/win-stack-${WARCH}/include/atk-1.0

tar -xJf /home/mingw-pkgs/${ATKMM} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/
mv ${ROOT}/win-stack-${WARCH}/include/atkmm-1.6/* ${ROOT}/win-stack-${WARCH}/include
rm -rf ${ROOT}/win-stack-${WARCH}/include/atkmm-1.6
mv ${ROOT}/win-stack-${WARCH}/lib/atkmm-1.6/include/atkmmconfig.h ${ROOT}/win-stack-${WARCH}/include
rsync -av --remove-source-files ${ROOT}/win-stack-${WARCH}/lib/atkmm-1.6/proc ${ROOT}/win-stack-${WARCH}
rm -rf ${ROOT}/win-stack-${WARCH}/lib/atkmm-1.6

tar -xJf /home/mingw-pkgs/${GTK2} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/
mv ${ROOT}/win-stack-${WARCH}/include/gail-1.0/* ${ROOT}/win-stack-${WARCH}/include
mv ${ROOT}/win-stack-${WARCH}/include/gtk-2.0/* ${ROOT}/win-stack-${WARCH}/include
rm -rf ${ROOT}/win-stack-${WARCH}/include/gail-1.0
rm -rf ${ROOT}/win-stack-${WARCH}/include/gtk-2.0
mv ${ROOT}/win-stack-${WARCH}/lib/gtk-2.0/include/gdkconfig.h ${ROOT}/win-stack-${WARCH}/include
rm -rf ${ROOT}/win-stack-${WARCH}/lib/gtk-2.0/include

tar -xJf /home/mingw-pkgs/${GTKMM} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/
mv ${ROOT}/win-stack-${WARCH}/include/gdkmm-2.4/* ${ROOT}/win-stack-${WARCH}/include
mv ${ROOT}/win-stack-${WARCH}/include/gtkmm-2.4/* ${ROOT}/win-stack-${WARCH}/include
rm -rf ${ROOT}/win-stack-${WARCH}/include/gdkmm-2.4
rm -rf ${ROOT}/win-stack-${WARCH}/include/gtkmm-2.4
mv ${ROOT}/win-stack-${WARCH}/lib/gdkmm-2.4/include/gdkmmconfig.h ${ROOT}/win-stack-${WARCH}/include
mv ${ROOT}/win-stack-${WARCH}/lib/gtkmm-2.4/include/gtkmmconfig.h ${ROOT}/win-stack-${WARCH}/include
rsync -av --remove-source-files ${ROOT}/win-stack-${WARCH}/lib/gtkmm-2.4/proc ${ROOT}/win-stack-${WARCH}
rm -rf ${ROOT}/win-stack-${WARCH}/lib/gdkmm-2.4
rm -rf ${ROOT}/win-stack-${WARCH}/lib/gtkmm-2.4

tar -xJf /home/mingw-pkgs/${FRIBIDI} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${LIBDATRIE} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${LIBTHAI} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${PANGO} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/
mv ${ROOT}/win-stack-${WARCH}/include/pango-1.0/* ${ROOT}/win-stack-${WARCH}/include
rm -rf ${ROOT}/win-stack-${WARCH}/include/pango-1.0

tar -xJf /home/mingw-pkgs/${PANGOMM} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/
mv ${ROOT}/win-stack-${WARCH}/include/pangomm-1.4/* ${ROOT}/win-stack-${WARCH}/include
rm -rf ${ROOT}/win-stack-${WARCH}/include/pangomm-1.4
mv ${ROOT}/win-stack-${WARCH}/lib/pangomm-1.4/include/pangommconfig.h ${ROOT}/win-stack-${WARCH}/include
rsync -av --remove-source-files ${ROOT}/win-stack-${WARCH}/lib/pangomm-1.4/proc ${ROOT}/win-stack-${WARCH}
rm -rf ${ROOT}/win-stack-${WARCH}/lib/pangomm-1.4

tar -xJf /home/mingw-pkgs/${LIBSAMPLERATE} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -I zstd -xf /home/mingw-pkgs/${FFMPEG} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${LIBVORBIS} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${PORTAUDIO} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${OPUS} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${CELT} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${LIBOGG} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -I zstd -xf /home/mingw-pkgs/${ZSTD} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${LZ4} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${SPEEX} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -I zstd -xf /home/mingw-pkgs/${LIBUNISTRING} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${XZ} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -I zstd -xf /home/mingw-pkgs/${LIBSSH2} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${LIBPSL} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -I zstd -xf /home/mingw-pkgs/${NGHTTP2} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${LIBIDN2} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xJf /home/mingw-pkgs/${OPENSSL} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -I zstd -xf /home/mingw-pkgs/${LIBJPEG_TURBO} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

tar -xjf /home/mingw-pkgs/${LIBTIFF} --strip-components 1 -C ${ROOT}/win-stack-${WARCH}/

rpm2cpio /home/mingw-pkgs/${JACK} | cpio -D ${ROOT}/win-stack-${WARCH}/ -div
rsync -av --remove-source-files ${ROOT}/win-stack-${WARCH}/usr/${ARCH}-w64-mingw32/sys-root/mingw/bin/* ${ROOT}/win-stack-${WARCH}/bin
rm -rf  ${ROOT}/win-stack-${WARCH}/usr/${ARCH}-w64-mingw32

rpm2cpio /home/mingw-pkgs/${JACK_DEVEL} | cpio -D ${ROOT}/win-stack-${WARCH}/ -div
rsync -av --remove-source-files ${ROOT}/win-stack-${WARCH}/usr/${ARCH}-w64-mingw32/sys-root/mingw/include/* ${ROOT}/win-stack-${WARCH}/include
rsync -av --remove-source-files ${ROOT}/win-stack-${WARCH}/usr/${ARCH}-w64-mingw32/sys-root/mingw/lib/* ${ROOT}/win-stack-${WARCH}/lib
rm -rf  ${ROOT}/win-stack-${WARCH}/usr/${ARCH}-w64-mingw32

tar -xf /home/mingw-pkgs/${LIBLO} usr/${ARCH}-w64-mingw32/bin --strip-components 2 -C ${ROOT}/win-stack-${WARCH}/bin
tar -xf /home/mingw-pkgs/${LIBLO} usr/${ARCH}-w64-mingw32/lib --strip-components 2 -C ${ROOT}/win-stack-${WARCH}/lib
tar -xf /home/mingw-pkgs/${LIBLO} usr/${ARCH}-w64-mingw32/include --strip-components 2 -C ${ROOT}/win-stack-${WARCH}/include
rm -rf ${ROOT}/win-stack-${WARCH}/usr/${ARCH}-w64-mingw32

unzip /home/mingw-pkgs/${AUBIO} -d ${ROOT}/
rsync -av --remove-source-files ${ROOT}/${AUBIO%.zip}/* ${ROOT}/win-stack-${WARCH}
rm -rf ${ROOT}/${AUBIO%.zip}

tar -xf /home/mingw-pkgs/${LV2} -C ${ROOT}/
tar -xf /home/mingw-pkgs/${SERD} -C ${ROOT}/
tar -xf /home/mingw-pkgs/${SORD} -C ${ROOT}/
tar -xf /home/mingw-pkgs/${SRATOM} -C ${ROOT}/
tar -xf /home/mingw-pkgs/${LILV} -C ${ROOT}/
tar -xf /home/mingw-pkgs/${SUIL} -C ${ROOT}/
# tar -xf /home/mingw-pkgs/${AUBIO} -C ${ROOT}/

cd ${ROOT}/${LV2%.tar.bz2}
CC=x86_64-w64-mingw32-gcc \
CXX=x86_64-w64-mingw32-g++ \
DEF_CFLAGS="-Os -I/usr/share/mingw-w64" \
DEF_LDFLAGS="" CFLAGS+="-std=c99" \
CXXFLAGS+="-std=c99" CFLAGS+=" -I${ROOT}/win-stack-${WARCH}/include" \
LDFLAGS+=" -L${ROOT}/win-stack-${WARCH}/lib" \
PKG_CONFIG_PATH=${ROOT}/win-stack-${WARCH}/lib/pkgconfig \
./waf configure --prefix=${ROOT}/win-stack-${WARCH} \
--includedir=${ROOT}/win-stack-${WARCH}/include \
--libdir=${ROOT}/win-stack-${WARCH}/lib --no-plugins
./waf build install

cd ${ROOT}/${SERD%-g227565f.tar.bz2}
CC=x86_64-w64-mingw32-gcc \
CXX=x86_64-w64-mingw32-g++ \
CFLAGS+="-std=c99" \
PKG_CONFIG_PATH=${ROOT}/win-stack-${WARCH}/lib/pkgconfig \
C_INCLUDE_PATH=${ROOT}/win-stack-${WARCH}/include \
./waf configure --prefix=${ROOT}/win-stack-${WARCH} \
--libdir=${ROOT}/win-stack-${WARCH}/lib --static
./waf build install

cd ${ROOT}/${SORD%-g61d9657.tar.bz2}
CC=x86_64-w64-mingw32-gcc \
CXX=x86_64-w64-mingw32-g++ \
CFLAGS+="-std=c99" CFLAGS+=" -I${ROOT}/win-stack-${WARCH}/include" \
PKG_CONFIG_PATH=${ROOT}/win-stack-${WARCH}/lib/pkgconfig \
C_INCLUDE_PATH=${ROOT}/win-stack-${WARCH}/include \
./waf configure --prefix=${ROOT}/win-stack-${WARCH} \
--libdir=${ROOT}/win-stack-${WARCH}/lib \
--includedir=${ROOT}/win-stack-${WARCH}/include --static
./waf build install

cd ${ROOT}/${SRATOM%-g2ed87d0.tar.bz2}
CC=x86_64-w64-mingw32-gcc \
CXX=x86_64-w64-mingw32-g++ \
CFLAGS+="-std=c99" CFLAGS+=" -I${ROOT}/win-stack-${WARCH}/include" \
PKG_CONFIG_PATH=${ROOT}/win-stack-${WARCH}/lib/pkgconfig \
C_INCLUDE_PATH=${ROOT}/win-stack-${WARCH}/include \
./waf configure --prefix=${ROOT}/win-stack-${WARCH} \
--libdir=${ROOT}/win-stack-${WARCH}/lib \
--includedir=${ROOT}/win-stack-${WARCH}/include --static
./waf build install

cd ${ROOT}/${LILV%-g20f2351.tar.bz2}
CC=x86_64-w64-mingw32-gcc \
CXX=x86_64-w64-mingw32-g++ \
CFLAGS+="-std=c99" CFLAGS+=" -I${ROOT}/win-stack-${WARCH}/include" \
PKG_CONFIG_PATH=${ROOT}/win-stack-${WARCH}/lib/pkgconfig \
C_INCLUDE_PATH=${ROOT}/win-stack-${WARCH}/include \
./waf configure --prefix=${ROOT}/win-stack-${WARCH} \
--libdir=${ROOT}/win-stack-${WARCH}/lib \
--includedir=${ROOT}/win-stack-${WARCH}/include --static
./waf build install

cd ${ROOT}/${SUIL%-gb402ae4.tar.bz2}
CC=x86_64-w64-mingw32-gcc \
CXX=x86_64-w64-mingw32-g++ \
CFLAGS+="-std=c99" CFLAGS+=" -I${ROOT}/win-stack-${WARCH}/include" \
CFLAGS+=" -I${ROOT}/win-stack-${WARCH}/lib" LDFLAGS="-L${ROOT}/win-stack-${WARCH}/lib"  \
PKG_CONFIG_PATH=${ROOT}/win-stack-${WARCH}/lib/pkgconfig \
./waf configure --prefix=${ROOT}/win-stack-${WARCH} \
--libdir=${ROOT}/win-stack-${WARCH}/lib \
--includedir=${ROOT}/win-stack-${WARCH}/include --no-cocoa --no-qt --no-qt4 --no-qt5 
./waf build install

# cd ${ROOT}/${AUBIO%.tar.bz2}
# # this change only for aubio-0.4.7
# sed -i 's/pause/getchar/g' ./examples/utils.c
# CC=x86_64-w64-mingw32-gcc \
# NM=x86_64-w64-mingw32-nm \
# DEF_CFLAGS="-Os -I/usr/share/mingw-w64" \
# DEF_LDFLAGS="" CFLAGS+=" -DHAVE_LIBAV=1 -DHAVE_SWRESAMPLE=1" \
# CFLAGS+=" -I${ROOT}/win-stack-${WARCH}/include" \
# LDFLAGS+=" -lavcodec -lavformat -lavutil -lswresample" \
# LDFLAGS+=" -L${ROOT}/win-stack-${WARCH}/lib" \
# PKG_CONFIG_PATH=${ROOT}/win-stack-${WARCH}/lib/pkgconfig \
# ./waf configure --prefix=${ROOT}/win-stack-${WARCH} \
# --includedir=${ROOT}/win-stack-${WARCH}/include \
# --libdir=${ROOT}/win-stack-${WARCH}/lib --disable-docs \
# --with-target-platform=${XARCH} --disable-examples --notests 
# ./waf
# ./waf install

pwd
cd ${ROOT}/win-stack-${WARCH}/

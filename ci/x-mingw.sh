#!/bin/bash
# this script creates a windows32/64bit build-stack for Ardour
# cross-compiled on GNU/Linux using gcc-8.2 (debian buster)
#
# It is intended to run in a pristine chroot or VM of a minimal debian system.
#
### Quick Start ###############################################################
#
# sudo apt-get install cowbuilder util-linux
# sudo mkdir -p /var/cache/pbuilder/buster-amd64/aptcache
#
# sudo cowbuilder --create \
#     --basepath /var/cache/pbuilder/buster-amd64/base.cow \
#     --distribution buster \
#     --debootstrapopts --arch --debootstrapopts amd64
#
### 'interactive build'
#
# sudo cowbuilder --login \
#     --bindmounts "/var/tmp /home/ardour"
#     --basepath /var/cache/pbuilder/buster-amd64/base.cow
#
### now, inside cowbuilder (/var/tmp/ and /home/ardour is shared with host)
#
# /var/tmp/this_script.sh       ### replace with path to *this* script :)
#
### ccache helps a lot to speed up recompiles. see also
### https://wiki.ubuntu.com/PbuilderHowto#Integration_with_ccache
###
### add the following to /etc/pbuilderrc
#> # ccache
#> sudo mkdir -p /var/cache/pbuilder/ccache
#> sudo chmod a+w /var/cache/pbuilder/ccache
#> export CCACHE_DIR="/var/cache/pbuilder/ccache"
#> export PATH="/usr/lib/ccache:${PATH}"
#> EXTRAPACKAGES=ccache
#> BINDMOUNTS="${CCACHE_DIR}${BINDMOUNTS:+:$BINDMOUNTS}"
###
###############################################################################

### influential environment variables

: ${XARCH=x86_64} # or i686

: ${MAKEFLAGS=-j4}
: ${STACKCFLAGS="-O2 -g"}

: ${SRCDIR=/var/tmp/winsrc}  # source-code .tgz cache
: ${TMPDIR=/var/tmp}         # package is built (and zipped) here.

: ${ROOT=/home/ardour} # everything else happens below here :)
                       # src, build and stack-install

###############################################################################

if [ "$(id -u)" != "0" -a -z "$SUDO" ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

###############################################################################
set -e

if test "$XARCH" = "x86_64" -o "$XARCH" = "amd64"; then
	echo "Target: 64bit Windows (x86_64)"
	XPREFIX=x86_64-w64-mingw32
	HPREFIX=x86_64
	MFAMILY=x86_64
	MCPU=x86_64
	WARCH=w64
	BOOST_ADDRESS_MODEL=64
	DEBIANPKGS="mingw-w64"
else
	echo "Target: 32 Windows (i686)"
	XPREFIX=i686-w64-mingw32
	HPREFIX=i386
	WARCH=w32
	MFAMILY=x86
	MCPU=i686
	BOOST_ADDRESS_MODEL=32
	if test "$DIST" = "buster"; then
		DEBIANPKGS="mingw-w64"
	else
		DEBIANPKGS="gcc-mingw-w64-i686 g++-mingw-w64-i686 mingw-w64-tools"
	fi
fi

: ${PREFIX=${ROOT}/win-stack-$WARCH}
: ${BUILDD=${ROOT}/win-build-$WARCH}

apt-get -y install build-essential \
	${DEBIANPKGS} \
	git autoconf automake libtool pkg-config \
	curl unzip ed yasm cmake ca-certificates \
	nsis subversion ocaml-nox gperf meson python

# use posix threads (needed for std::mutex et al)
update-alternatives --set-selections << EOF
i686-w64-mingw32-g++         manual   /usr/bin/i686-w64-mingw32-g++-posix
i686-w64-mingw32-gcc         manual   /usr/bin/i686-w64-mingw32-gcc-posix
x86_64-w64-mingw32-g++       manual   /usr/bin/x86_64-w64-mingw32-g++-posix
x86_64-w64-mingw32-gcc       manual   /usr/bin/x86_64-w64-mingw32-gcc-posix
EOF

# use ccache also for mingw64
if test -d /usr/lib/ccache -a -f /usr/bin/ccache; then
	export PATH="/usr/lib/ccache:${PATH}"
	cd /usr/lib/ccache
	test -L ${XPREFIX}-gcc || ln -s ../../bin/ccache ${XPREFIX}-gcc
	test -L ${XPREFIX}-g++ || ln -s ../../bin/ccache ${XPREFIX}-g++
fi

###############################################################################

# clean up old buld-stack
rm -rf ${PREFIX}
rm -rf ${BUILDD}

mkdir -p ${SRCDIR}
mkdir -p ${BUILDD}

mkdir -p ${PREFIX}/bin
mkdir -p ${PREFIX}/lib
mkdir -p ${PREFIX}/include

unset PKG_CONFIG_PATH
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig
export XPREFIX
export PREFIX
export SRCDIR

# Note: at some point using mingw's version of pkg-config may become
# relevant, usually via wine or some cross-environment.
# Until then, we use the host's native version with a custom
# PKG_CONFIG_PATH.
export PKG_CONFIG=/usr/bin/pkg-config
#if test -n "$(which ${XPREFIX}-pkg-config)"; then
#	export PKG_CONFIG=`which ${XPREFIX}-pkg-config`
#fi

###############################################################################

function download {
echo "--- Downloading.. $2"
test -f "${SRCDIR}/${1}" || curl -k -L -o "${SRCDIR}/${1}" $2
}

function src {
download "${1}${4}.${2}" $3
cd ${BUILDD}
rm -rf $1
tar xf "${SRCDIR}/${1}${4}.${2}"
cd $1
}

function autoconfconf {
set -e
echo "======= $(pwd) ======="
#CPPFLAGS="-I${PREFIX}/include -DDEBUG$CPPFLAGS" \
	CPPFLAGS="-I${PREFIX}/include$CPPFLAGS" \
	CFLAGS="-I${PREFIX}/include ${STACKCFLAGS} -mstackrealign$CFLAGS" \
	CXXFLAGS="-I${PREFIX}/include ${STACKCFLAGS} -std=gnu++11 -mstackrealign$CXXFLAGS" \
	LDFLAGS="-L${PREFIX}/lib$LDFLAGS" \
	./configure --host=${XPREFIX} --build=${HPREFIX}-linux \
	--prefix=$PREFIX $@
}

function autoconfbuild {
set -e
autoconfconf $@
make $MAKEFLAGS && make install
}

function wafbuild {
set -e
echo "======= $(pwd) ======="
	CC=${XPREFIX}-gcc \
	CXX=${XPREFIX}-g++ \
	CPP=${XPREFIX}-cpp \
	AR=${XPREFIX}-ar \
	LD=${XPREFIX}-ld \
	NM=${XPREFIX}-nm \
	AS=${XPREFIX}-as \
	STRIP=${XPREFIX}-strip \
	RANLIB=${XPREFIX}-ranlib \
	DLLTOOL=${XPREFIX}-dlltool \
	CPPFLAGS="-I${PREFIX}/include$CPPFLAGS" \
	CFLAGS="-I${PREFIX}/include ${STACKCFLAGS} -mstackrealign$CFLAGS" \
	CXXFLAGS="-I${PREFIX}/include ${STACKCFLAGS} -std=gnu++11 -mstackrealign$CXXFLAGS" \
	LDFLAGS="-L${PREFIX}/lib$LDFLAGS" \
	./waf configure --prefix=$PREFIX $@ \
	&& ./waf && ./waf install
}

function mesonbuild {
set -e
meson build/ --cross-file ${BUILDD}/meson-cross.txt --prefix=$PREFIX --libdir=lib "$@"
ninja -C build install ${CONCURRENCY}
}

cat > ${BUILDD}/meson-cross.txt << EOF
[binaries]
c = '/usr/lib/ccache/${XPREFIX}-gcc'
cpp = '/usr/lib/ccache/${XPREFIX}-g++'
ld = '/usr/bin/${XPREFIX}-ld'
ar = '/usr/bin/${XPREFIX}-ar'
strip = '/usr/bin/${XPREFIX}-strip'
windres = '/usr/bin/${XPREFIX}-windres'
pkgconfig = '/usr/bin/pkg-config'

[properties]
c_args = ['-I${PREFIX}/include', '-O2', '-mstackrealign', '-Werror=format=0']
cpp_args = ['-I${PREFIX}/include', '-O2', '-mstackrealign', '-std=gnu++11']
c_link_args = ['-L${PREFIX}/lib']
cpp_link_args = ['-L${PREFIX}/lib']
sys_root = '$PREFIX'

[paths]
prefix = '$PREFIX'

[host_machine]
system = 'windows'
cpu_family = '$MFAMILY'
cpu = '$MCPU'
endian = 'little'
EOF


###############################################################################
## BUILD STARTS HERE
###############################################################################

### jack headers, .def, .lib, .dll and pkg-config file from jackd 1.9.10
### this is a re-zip of file extracted from official jack releases:
### https://dl.dropboxusercontent.com/u/28869550/Jack_v1.9.10_32_setup.exe
### https://dl.dropboxusercontent.com/u/28869550/Jack_v1.9.10_64_setup.exe

download jack_win3264.tar.xz http://ardour.org/files/deps/jack_win3264.tar.xz
cd "$PREFIX"
tar xf ${SRCDIR}/jack_win3264.tar.xz
"$PREFIX"/update_pc_prefix.sh ${WARCH}

download drmingw.tar.xz http://ardour.org/files/deps/drmingw.tar.xz
cd ${BUILDD}
rm -rf drmingw
tar xf ${SRCDIR}/drmingw.tar.xz
cp -av drmingw/$WARCH/* "$PREFIX"/

src xz-5.2.2 tar.bz2 http://tukaani.org/xz/xz-5.2.2.tar.bz2
autoconfbuild

src zlib-1.2.7 tar.gz ftp://ftp.simplesystems.org/pub/libpng/png/src/history/zlib/zlib-1.2.7.tar.gz
make -fwin32/Makefile.gcc PREFIX=${XPREFIX}-
make install -fwin32/Makefile.gcc SHARED_MODE=1 \
	INCLUDE_PATH=${PREFIX}/include \
	LIBRARY_PATH=${PREFIX}/lib \
	BINARY_PATH=${PREFIX}/bin

src tiff-4.0.3 tar.gz http://download.osgeo.org/libtiff/old/tiff-4.0.3.tar.gz
autoconfbuild

download jpegsrc.v9a.tar.gz http://www.ijg.org/files/jpegsrc.v9a.tar.gz
cd ${BUILDD}
rm -rf jpeg-9a
tar xzf ${SRCDIR}/jpegsrc.v9a.tar.gz
cd jpeg-9a
autoconfbuild

src libogg-1.3.2 tar.gz http://downloads.xiph.org/releases/ogg/libogg-1.3.2.tar.gz
autoconfbuild

src libvorbis-1.3.4 tar.gz http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.4.tar.gz
autoconfbuild --disable-examples --with-ogg=${PREFIX}

src flac-1.3.2 tar.xz http://downloads.xiph.org/releases/flac/flac-1.3.2.tar.xz
ed Makefile.in << EOF
%s/examples / /
wq
EOF
autoconfbuild

src libsndfile-1.0.27 tar.gz http://www.mega-nerd.com/libsndfile/files/libsndfile-1.0.27.tar.gz
sed -i 's/12292/24584/' src/common.h
ed Makefile.in << EOF
%s/ examples regtest tests programs//
wq
EOF
LDFLAGS=" -lFLAC -lwsock32 -lvorbis -logg -lwsock32" \
autoconfbuild
ed $PREFIX/lib/pkgconfig/sndfile.pc << EOF
%s/ -lsndfile/ -lsndfile -lvorbis -lvorbisenc -lFLAC -logg -lwsock32/
wq
EOF

src libsamplerate-0.1.9 tar.gz http://www.mega-nerd.com/SRC/libsamplerate-0.1.9.tar.gz
ed Makefile.in << EOF
%s/ examples tests//
wq
EOF
autoconfbuild

src termcap-1.3.1 tar.gz http://ftpmirror.gnu.org/termcap/termcap-1.3.1.tar.gz
autoconfconf
make install CC=${XPREFIX}-gcc AR=${XPREFIX}-ar RANLIB=${XPREFIX}-ranlib

src readline-8.0-beta2 tar.gz http://ftpmirror.gnu.org/readline/readline-8.0-beta2.tar.gz
ed rlconf.h << EOF
%s/#define COLOR_SUPPORT//
wq
EOF
autoconfbuild

src expat-2.1.0 tar.gz https://sourceforge.net/projects/expat/files/expat/2.1.0/expat-2.1.0-RENAMED-VULNERABLE-PLEASE-USE-2.3.0-INSTEAD.tar.gz
autoconfbuild

src libiconv-1.16 tar.gz http://ftpmirror.gnu.org/libiconv/libiconv-1.16.tar.gz
autoconfbuild --with-included-gettext --with-libiconv-prefix=$PREFIX

src libxml2-2.9.2 tar.gz ftp://xmlsoft.org/libxslt/libxml2-2.9.2.tar.gz
CFLAGS=" -O0" CXXFLAGS=" -O0" \
autoconfbuild --with-threads=no --with-zlib=$PREFIX --without-python

src libpng-1.6.37 tar.xz https://downloads.sourceforge.net/project/libpng/libpng16/1.6.37/libpng-1.6.37.tar.xz
autoconfbuild

src freetype-2.9 tar.gz http://download.savannah.gnu.org/releases/freetype/freetype-2.9.tar.gz
autoconfbuild -with-harfbuzz=no

src fontconfig-2.13.1 tar.bz2 http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.1.tar.bz2
ed Makefile.in << EOF
%s/po-conf test/po-conf/
wq
EOF
autoconfbuild --enable-libxml2

src libarchive-3.2.1 tar.gz http://www.libarchive.org/downloads/libarchive-3.2.1.tar.gz
autoconfbuild --disable-bsdtar --disable-bsdcat --disable-bsdcpio --without-openssl

src pixman-0.38.4 tar.gz https://www.cairographics.org/releases/pixman-0.38.4.tar.gz
autoconfbuild

src cairo-1.16.0 tar.xz http://cairographics.org/releases/cairo-1.16.0.tar.xz
ed Makefile.in << EOF
%s/ test perf//
wq
EOF
ax_cv_c_float_words_bigendian=no \
autoconfbuild --disable-gtk-doc-html --enable-gobject=no --disable-valgrind \
	--enable-interpreter=no --enable-script=no

src libffi-3.1 tar.gz ftp://sourceware.org/pub/libffi/libffi-3.1.tar.gz
autoconfbuild

src gettext-0.19.3 tar.gz http://ftpmirror.gnu.org/gettext/gettext-0.19.3.tar.gz
CFLAGS="-O2 -mstackrealign" CXXFLAGS="-O2 -mstackrealign" \
	./configure --host=${XPREFIX} --build=${HPREFIX}-linux --prefix=$PREFIX $@
make $MAKEFLAGS && make install

src glib-2.64.1 tar.xz http://ftp.gnome.org/pub/gnome/sources/glib/2.64/glib-2.64.1.tar.xz
mesonbuild -Dinternal_pcre=true

src harfbuzz-2.6.4 tar.xz https://www.freedesktop.org/software/harfbuzz/release/harfbuzz-2.6.4.tar.xz
autoconfbuild -without-icu --with-uniscribe

src fribidi-1.0.9 tar.xz https://github.com/fribidi/fribidi/releases/download/v1.0.9/fribidi-1.0.9.tar.xz
mesonbuild -Ddocs=false

################################################################################
#NB. we could apt-get install wine instead and run the exe files in $PREFIX/bin
apt-get -y install libglib2.0-dev # used for native `glib-mkenums` etc `glib-*`
################################################################################

src pango-1.42.4 tar.xz http://ftp.gnome.org/pub/GNOME/sources/pango/1.42/pango-1.42.4.tar.xz
mesonbuild -Dgir=false #-Duse_fontconfig=true

src atk-2.14.0 tar.bz2 http://ftp.gnome.org/pub/GNOME/sources/atk/2.14/atk-2.14.0.tar.xz
autoconfbuild --disable-rebuilds

src gdk-pixbuf-2.31.1 tar.xz http://ftp.acc.umu.se/pub/GNOME/sources/gdk-pixbuf/2.31/gdk-pixbuf-2.31.1.tar.xz
autoconfbuild --disable-modules --without-gdiplus --with-included-loaders=yes

# latest: http://ftp.acc.umu.se/pub/GNOME/sources/gtk+/2.24/gtk+-2.24.32.tar.xz
src gtk+-2.24.25 tar.xz http://ftp.gnome.org/pub/gnome/sources/gtk+/2.24/gtk+-2.24.25.tar.xz
ed Makefile.in << EOF
%s/demos / /
wq
EOF
patch -p1 << EOF
--- a/gdk/win32/gdkkeys-win32.c	2015-04-29 16:33:41.545406159 +0200
+++ b/gdk/win32/gdkkeys-win32.c	2015-04-29 17:42:43.570929918 +0200
@@ -145,6 +145,8 @@
       *ksymp = GDK_Meta_R; break;
     case VK_APPS:
       *ksymp = GDK_Menu; break;
+    case VK_DECIMAL:
+      *ksymp = GDK_KP_Decimal; break;
     case VK_MULTIPLY:
       *ksymp = GDK_KP_Multiply; break;
     case VK_ADD:
EOF

# current-gtk-patches/gtk-treeview.patch
patch -p1 << EOF
--- a/gtk/gtktreeview.c	2016-06-29 21:43:47.387836880 +0200
+++ b/gtk/gtktreeview.c	2016-06-29 21:44:32.674038251 +0200
@@ -2559,6 +2559,7 @@
   gint horizontal_separator;
   gboolean path_is_selectable;
   gboolean rtl;
+  gboolean edits_allowed;
 
   rtl = (gtk_widget_get_direction (widget) == GTK_TEXT_DIR_RTL);
   gtk_tree_view_stop_editing (tree_view, FALSE);
@@ -2698,9 +2699,17 @@
 
       tree_view->priv->focus_column = column;
 
+      /* ARDOUR HACK */
+
+      if (g_object_get_data (G_OBJECT(tree_view), "mouse-edits-require-mod1")) {
+             edits_allowed = (event->state & GDK_MOD1_MASK);
+      } else {
+             /* regular GTK design: do edits if none of the default modifiers are active */
+             edits_allowed = !(event->state & gtk_accelerator_get_default_mod_mask ());
+      }
+
       /* decide if we edit */
-      if (event->type == GDK_BUTTON_PRESS && event->button == 1 &&
-	  !(event->state & gtk_accelerator_get_default_mod_mask ()))
+      if (event->type == GDK_BUTTON_PRESS && event->button == 1 && edits_allowed)
 	{
 	  GtkTreePath *anchor;
 	  GtkTreeIter iter;
EOF

CFLAGS=" -Wno-deprecated-declarations" \
autoconfconf --disable-rebuilds # --disable-modules
if test "$WARCH" = "w64"; then
make -n || true
rm gtk/gtk.def # workaround disable-rebuilds
fi
make && make install

################################################################################
dpkg -P libglib2.0-dev libpcre3-dev || true
################################################################################

src lv2-1.18.2 tar.bz2 http://ardour.org/files/deps/lv2-1.18.2-g611759d.tar.bz2 -g611759d
wafbuild --no-plugins --copy-headers --lv2dir=$PREFIX/lib/lv2

# work around http://dev.drobilla.net/ticket/998
export COMMONPROGRAMFILES="%COMMONPROGRAMFILES%"

src serd-0.30.11 tar.bz2 http://ardour.org/files/deps/serd-0.30.11-g36f1cecc.tar.bz2 -g36f1cecc
wafbuild

src sord-0.16.9 tar.bz2 http://ardour.org/files/deps/sord-0.16.9-gd2efdb2.tar.bz2 -gd2efdb2
wafbuild --no-utils

src sratom-0.6.8 tar.bz2 http://ardour.org/files/deps/sratom-0.6.8-gc46452c.tar.bz2 -gc46452c
wafbuild

src lilv-0.24.13 tar.bz2 http://ardour.org/files/deps/lilv-0.24.13-g71a2ff5.tar.bz2 -g71a2ff5
wafbuild --no-utils

src suil-0.10.8 tar.bz2 http://ardour.org/files/deps/suil-0.10.8-g05c2afb.tar.bz2 -g05c2afb
wafbuild

unset COMMONPROGRAMFILES

src curl-7.66.0 tar.bz2 http://curl.haxx.se/download/curl-7.66.0.tar.bz2
autoconfbuild --with-winssl

# libsigc++-3 need need C++17
#src libsigc++-3.0.2 tar.xz http://ftp.gnome.org/pub/GNOME/sources/libsigc++/3.0/libsigc++-3.0.2.tar.xz
src libsigc++-2.10.2 tar.xz http://ftp.gnome.org/pub/GNOME/sources/libsigc++/2.10/libsigc++-2.10.2.tar.xz
autoconfbuild

src glibmm-2.62.0 tar.xz http://ftp.gnome.org/pub/GNOME/sources/glibmm/2.62/glibmm-2.62.0.tar.xz
autoconfbuild

# cairomm >= 1.15.x needs libsigc++-3
src cairomm-1.13.1 tar.gz http://cairographics.org/releases/cairomm-1.13.1.tar.gz
autoconfbuild

src pangomm-2.42.0 tar.xz http://ftp.acc.umu.se/pub/GNOME/sources/pangomm/2.42/pangomm-2.42.0.tar.xz
autoconfbuild

src atkmm-2.22.7 tar.xz http://ftp.gnome.org/pub/GNOME/sources/atkmm/2.22/atkmm-2.22.7.tar.xz
autoconfbuild

src gtkmm-2.24.5 tar.xz http://ftp.acc.umu.se/pub/GNOME/sources/gtkmm/2.24/gtkmm-2.24.5.tar.xz
CXXFLAGS=" -Wno-deprecated-declarations -Wno-parentheses" \
autoconfbuild

src fftw-3.3.8 tar.gz http://fftw.org/fftw-3.3.8.tar.gz
autoconfbuild --enable-single --enable-float --enable-sse --with-our-malloc --enable-avx --disable-mpi --enable-threads --with-combined-threads --disable-static --enable-shared
make clean
autoconfbuild --enable-type-prefix --with-our-malloc --enable-avx --disable-mpi --enable-threads --with-combined-threads --disable-static --enable-shared

################################################################################
src taglib-1.9.1 tar.gz http://taglib.github.io/releases/taglib-1.9.1.tar.gz
ed CMakeLists.txt << EOF
0i
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_C_COMPILER ${XPREFIX}-gcc)
set(CMAKE_CXX_COMPILER ${XPREFIX}-c++)
set(CMAKE_RC_COMPILER ${XPREFIX}-windres)
.
wq
EOF
sed -i 's/\~ListPrivate/virtual ~ListPrivate/' taglib/toolkit/tlist.tcc
rm -rf build/
mkdir build && cd build
	cmake \
		-DCMAKE_INSTALL_PREFIX=$PREFIX -DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Windows -DZLIB_ROOT=$PREFIX \
		..
make $MAKEFLAGS && make install

# windows target does not create .pc file...
cat > $PREFIX/lib/pkgconfig/taglib.pc << EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: TagLib
Description: Audio meta-data library
Requires:
Version: 1.9.1
Libs: -L\${libdir}/lib -ltag
Cflags: -I\${includedir}/include/taglib
EOF

################################################################################
#git://liblo.git.sourceforge.net/gitroot/liblo/liblo
src liblo-0.28 tar.gz http://downloads.sourceforge.net/liblo/liblo-0.28.tar.gz
autoconfconf --enable-shared
ed src/Makefile << EOF
/noinst_PROGRAMS
.,+3d
wq
EOF
ed Makefile << EOF
%s/examples//
wq
EOF
make $MAKEFLAGS && make install

################################################################################
src boost_1_68_0 tar.bz2 http://sourceforge.net/projects/boost/files/boost/1.68.0/boost_1_68_0.tar.bz2
./bootstrap.sh --prefix=$PREFIX

echo "using gcc : 8.2 : ${XPREFIX}-g++ :
<rc>${XPREFIX}-windres
<archiver>${XPREFIX}-ar
;" > user-config.jam

./b2 --prefix=$PREFIX \
	toolset=gcc \
	target-os=windows \
	architecture=x86 \
	address-model=$BOOST_ADDRESS_MODEL \
	variant=release \
	threading=multi \
	threadapi=win32 \
	link=shared \
	runtime-link=shared \
	cxxstd=11 \
	--with-exception \
	--with-regex \
	--with-atomic \
	--layout=tagged \
	--user-config=user-config.jam \
	$MAKEFLAGS install

if false; then
# silence mingw compiler warnings
sed -i 's/^#pragma intrinsic.*$//' ${PREFIX}/include/boost/thread/win32/thread_primitives.hpp
sed -i 's/__atomic_store_n((void\*\*/__atomic_store_n((void* volatile*/' ${PREFIX}/include/boost/thread/win32/interlocked_read.hpp
sed -i 's/__atomic_load_n((void\*\*/__atomic_load_n((void* volatile*/' ${PREFIX}/include/boost/thread/win32/interlocked_read.hpp
sed -i 's/__atomic_store_n((long/__atomic_store_n((volatile long/' ${PREFIX}/include/boost/thread/win32/interlocked_read.hpp
sed -i 's/__atomic_load_n((long/__atomic_load_n((volatile long/' ${PREFIX}/include/boost/thread/win32/interlocked_read.hpp
fi

################################################################################
#download ladspa.h http://www.ladspa.org/ladspa_sdk/ladspa.h.txt
download ladspa.h http://community.ardour.org/files/ladspa.h
cp ${SRCDIR}/ladspa.h $PREFIX/include/ladspa.h
################################################################################

#src vamp-plugin-sdk-2.5 tar.gz http://code.soundsoftware.ac.uk/attachments/download/690/vamp-plugin-sdk-2.5.tar.gz
src vamp-plugin-sdk-2.8.0 tar.gz https://code.soundsoftware.ac.uk/attachments/download/2450/vamp-plugin-sdk-2.8.0.tar.gz
ed Makefile.in << EOF
%s/= ar/= ${XPREFIX}-ar/
%s/= ranlib/= ${XPREFIX}-ranlib/
%s/vamp-simple-host$/vamp-simple-host.exe/
%s/vamp-rdf-template-generator$/vamp-rdf-template-generator.exe/
wq
EOF
ed src/vamp-hostsdk/Window.h << EOF
/cstdlib
+1i
#ifndef M_PI
#  define M_PI 3.14159265358979323846
#endif
.
wq
EOF
MAKEFLAGS="sdk -j4" autoconfbuild
ed $PREFIX/lib/pkgconfig/vamp-hostsdk.pc << EOF
%s/-ldl//
wq
EOF

src rubberband-1.8.1 tar.bz2 http://code.breakfastquay.com/attachments/download/34/rubberband-1.8.1.tar.bz2
ed Makefile.in << EOF
%s/= ar/= ${XPREFIX}-ar/
%s|bin/rubberband$|bin/rubberband.exe|
wq
EOF
autoconfbuild
ed $PREFIX/lib/pkgconfig/rubberband.pc << EOF
%s/ -lrubberband/ -lrubberband -lfftw3/
wq
EOF

src mingw-libgnurx-2.5.1 tar.gz http://sourceforge.net/projects/mingw/files/Other/UserContributed/regex/mingw-regex-2.5.1/mingw-libgnurx-2.5.1-src.tar.gz
autoconfbuild

src aubio-0.3.2 tar.gz http://aubio.org/pub/aubio-0.3.2.tar.gz
ed Makefile.in << EOF
%s/examples / /
wq
EOF
autoconfbuild
ed $PREFIX/lib/pkgconfig/aubio.pc << EOF
%s/ -laubio/ -laubio -lfftw3f/
wq
EOF


################################################################################

src libwebsockets-4.0.15 tar.gz http://ardour.org/files/deps/libwebsockets-4.0.15.tar.gz
rm -rf build/
sed -i.bak 's%-Werror%%' CMakeLists.txt
mkdir build && cd build
cmake -DLWS_WITH_SSL=off -DLWS_WITH_EXTERNAL_POLL=yes \
	-DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER=`which ${XPREFIX}-gcc` -DCMAKE_RC_COMPILER=`which ${XPREFIX}-windres` \
	-DCMAKE_C_FLAGS="-isystem ${PREFIX}/include ${STACKCFLAGS} -mstackrealign" \
	-DLWS_WITHOUT_TEST_SERVER=on -DLWS_WITHOUT_TESTAPPS=on \
	-DCMAKE_INSTALL_PREFIX=$PREFIX -DCMAKE_BUILD_TYPE=Release \
	..
make $MAKEFLAGS && make install

## libwebsockets CMakeLists.txt only generates this for Unix systems

cat > $PREFIX/lib/pkgconfig/libwebsockets.pc << EOF
prefix=/home/ardour/win-stack-w64
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: libwebsockets
Description: Websockets server and client library
Version: 3.0.99

Libs: -L\${libdir} -lwebsockets
Cflags: -I\${includedir}
EOF

cat > $PREFIX/lib/pkgconfig/libwebsockets_static.pc << EOF
prefix=/home/ardour/win-stack-w64
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: libwebsockets_static
Description: Websockets server and client static library
Version: 3.0.99

Libs: -L\${libdir} -lwebsockets_static
Libs.private:
Cflags: -I\${includedir}"
EOF

################################################################################
src libusb-1.0.20 tar.bz2 http://downloads.sourceforge.net/project/libusb/libusb-1.0/libusb-1.0.20/libusb-1.0.20.tar.bz2
(
  MAKEFLAGS= \
  autoconfbuild
)

################################################################################
# alternative: https://github.com/chriskohlhoff/asio
rm -f ${PREFIX}/include/pa_asio.h ${PREFIX}/include/portaudio.h ${PREFIX}/include/asio.h
if test ! -d ${SRCDIR}/soundfind.git.reference; then
	git clone --mirror git://github.com/aardvarkk/soundfind.git ${SRCDIR}/soundfind.git.reference
fi
cd ${BUILDD}
#git clone --reference ${SRCDIR}/soundfind.git.reference --depth 1 git://github.com/aardvarkk/soundfind.git || true
git clone ${SRCDIR}/soundfind.git.reference soundfind || true

download pa_waves3.diff http://robin.linuxaudio.org/tmp/pa_waves3.diff
#src portaudio tgz http://portaudio.com/archives/pa_stable_v19_20140130.tgz
src portaudio-svn1963 tgz http://ardour.org/files/deps/portaudio-svn1963.tgz
patch -p1 < ${SRCDIR}/pa_waves3.diff
# build for winXP (no WASAPI)
autoconfconf --with-asiodir=${BUILDD}/soundfind/ASIOSDK2/ --with-winapi=asio,wmme --without-jack
ed Makefile << EOF
%s/-luuid//g
wq
EOF
make $MAKEFLAGS && make install
mv $PREFIX/bin/libportaudio-2.dll $PREFIX/bin/libportaudio-2.xp
make clean
# build for vista or newer (with WASAPI)
	ed configure << EOF
%s/mingw-include//
%s/_WIN32_WINNT=0x0501/_WIN32_WINNT=0x0600/
%s/WINVER=0x0501/WINVER=0x0600/
wq
EOF
autoconfconf --with-asiodir=${BUILDD}/soundfind/ASIOSDK2/ --with-winapi=asio,wmme,wasapi --without-jack
ed Makefile << EOF
%s/-luuid//g
wq
EOF
# mingw-w64 > 4.0 has functiondiscoverykeys_devpkey.h
ed src/hostapi/wasapi/pa_win_wasapi.c << EOF
/#undef INITGUID
.+1i
#else
  #include <avrt.h>
  #define COBJMACROS
  #include <audioclient.h>
  #include <endpointvolume.h>
  #define INITGUID
  #include <mmdeviceapi.h>
  #include <functiondiscoverykeys_devpkey.h>
  #include <functiondiscoverykeys.h>
.
wq
EOF

make $MAKEFLAGS && make install
cp include/pa_asio.h ${PREFIX}/include/
cp ${BUILDD}/soundfind/ASIOSDK2/common/asio.h ${PREFIX}/include/

src cppunit-1.13.2 tar.gz http://dev-www.libreoffice.org/src/cppunit-1.13.2.tar.gz
autoconfbuild

################################################################################
echo "*** STACK COMPLETE"
################################################################################

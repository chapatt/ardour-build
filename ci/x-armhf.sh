#!/usr/bin/env bash
### One stop script to cross-compile a ARM binary version of Ardour
### and dependencies from scratch and bundle it.
##
## It is intended to run in a pristine chroot or VM of a minimal
## 64bit debian/stretch build-host.
##
### Quick Start ###############################################################
### one-time cowbuilder/pbuilder setup on the build-host:
##
## sudo apt-get install cowbuilder util-linux
## sudo mkdir -p /var/cache/pbuilder/stretch-amd64/aptcache
##
## sudo cowbuilder --create \
##     --basepath /var/cache/pbuilder/stretch-amd64/base.cow \
##     --distribution stretch \
##     --debootstrapopts --arch --debootstrapopts amd64
##
### 'interactive build'
##
## sudo cowbuilder --login --bindmounts "/var/tmp /home" \
##     --basepath /var/cache/pbuilder/stretch-amd64/base.cow
##
### now, inside cowbuilder (/var/tmp/ is shared with host, see bindmounts)
##
##  /var/tmp/x-armhf.sh  ## THIS script
##
###############################################################################

: ${XARCH=armhf} # or armel

: ${CONCURRENCY=-j4}

: ${MAKEFLAGS=$CONCURRENCY}
: ${STACKCFLAGS="-O2 -g"}

: ${NOSTACK=}   # set to skip building the build-stack

: ${SRCDIR=/var/tmp/winsrc}  # source-code tgz cache
: ${TMPDIR=/var/tmp}         # package is built (and zipped) here.

: ${ROOT=/home/ardour} # everything happens below here:
                       # src, build and stack-install are
                       # in a subdir. e.g. $ROOT/linux-armhf/**

###############################################################################
### HERE BE DRAGONS ###########################################################
###############################################################################

if [ "$(id -u)" != "0" -a -z "$SUDO" ]; then
	echo "This script must be run as root in pbuilder" 1>&2
	echo "e.g sudo DIST=stretch cowbuilder --bindmounts /var/tmp --execute $0"
	exit 1
fi

pushd "`/usr/bin/dirname \"$0\"`" > /dev/null; this_script_dir="`pwd`"; popd > /dev/null

###############################################################################
set -e

if test "$XARCH" = "arm64"; then
	echo "Target: ARM 64 (arm64)"
	XPREFIX=aarch64-linux-gnu
	WARCH=arm64
	AARCH=aarch64
	DEBIANPKGS="gcc-aarch64-linux-gnu"
elif test "$XARCH" = "armhf"; then
	echo "Target: ARM Hard Float (armhf)"
	XPREFIX=arm-linux-gnueabihf
	WARCH=armhf
	AARCH=armhf
	DEBIANPKGS="g++-arm-linux-gnueabihf"
else
	echo "Target: ARM (armel)"
	XPREFIX=arm-linux-gnueabi
	WARCH=armel
	AARCH=armel
	DEBIANPKGS="g++-arm-linux-gnueabi"
fi

if test -n "$MIXBUS" -a "$MIXBUS" = "32C"; then
	OUTPREFIX="C_"
elif test -n "$MIXBUS"; then
	OUTPREFIX="M_"
else
	OUTPREFIX="A_"
fi

: ${BUILDROOT=${ROOT}/linux-$WARCH}
: ${PREFIX=${BUILDROOT}/stack}
: ${BUILDD=${BUILDROOT}/build}
: ${OUTDIR=${TMPDIR}/builds/${OUTPREFIX}Linux_$XARCH}/

###############################################################################
if ! dpkg --print-foreign-architectures | grep -q $WARCH; then
###############################################################################

dpkg --add-architecture $WARCH
apt-get update
apt-get -y autoremove

apt-get -y install build-essential \
	crossbuild-essential-$WARCH \
	${DEBIANPKGS} \
	git autoconf automake libtool pkg-config \
	curl unzip ed yasm cmake ca-certificates \
	subversion ocaml-nox gperf coreutils ed

apt-get -y install libc6-dev:$WARCH \
	libx11-dev:$WARCH libxext-dev:$WARCH libxrender-dev:$WARCH libx11-xcb-dev:$WARCH \
	libxcb-xkb-dev:$WARCH libxcb-render0-dev:$WARCH libxcb-shm0-dev:$WARCH \
	libasound-dev:$WARCH libudev-dev:$WARCH

#fixup ccache for now
if test -d /usr/lib/ccache -a -f /usr/bin/ccache; then
	export PATH="/usr/lib/ccache:${PATH}"
	cd /usr/lib/ccache
	test -L ${XPREFIX}-gcc || ln -s ../../bin/ccache ${XPREFIX}-gcc
	test -L ${XPREFIX}-g++ || ln -s ../../bin/ccache ${XPREFIX}-g++
fi

###############################################################################
fi
###############################################################################

mkdir -p ${SRCDIR}
mkdir -p ${PREFIX}
mkdir -p ${BUILDD}

unset PKG_CONFIG_PATH
export XPREFIX
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:/usr/lib/${XPREFIX}/pkgconfig
export PREFIX
export SRCDIR

export PKG_CONFIG=/usr/bin/pkg-config
#if test -n "$(which ${XPREFIX}-pkg-config)"; then
#	export PKG_CONFIG=`which ${XPREFIX}-pkg-config`
#fi

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

function svnco {
SVNURL=$1
SVNDIR=$2
shift
shift
cd ${BUILDD}
rm -rf $SVNDIR
svn co -q $@ $SVNURL $SVNDIR
cd $SVNDIR
}

function autoconfconf {
set -e
echo "======= $(pwd) ======="
#CPPFLAGS="-I${PREFIX}/include -DDEBUG$CPPFLAGS" \
	CPPFLAGS="-I${PREFIX}/include$CPPFLAGS" \
	CFLAGS="-I${PREFIX}/include ${STACKCFLAGS} $CFLAGS" \
	CXXFLAGS="-I${PREFIX}/include ${STACKCFLAGS} $CXXFLAGS" \
	LDFLAGS="-L${PREFIX}/lib $LDFLAGS" \
	./configure --host=${XPREFIX} --build=x86_64-linux \
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
	CFLAGS="-I${PREFIX}/include ${STACKCFLAGS} $CFLAGS" \
	CXXFLAGS="-I${PREFIX}/include ${STACKCFLAGS} $CXXFLAGS" \
	LDFLAGS="-L${PREFIX}/lib $LDFLAGS" \
	./waf configure --prefix=$PREFIX $@ \
	&& ./waf && ./waf install
}

################################################################################
if test -z "$NOSTACK"; then
################################################################################

rm -rf ${PREFIX}
rm -rf ${BUILDD}

mkdir -p ${PREFIX}
mkdir -p ${BUILDD}

# src xz-5.2.2 tar.bz2 http://tukaani.org/xz/xz-5.2.2.tar.bz2
src xz-5.2.5 tar.gz https://tukaani.org/xz/xz-5.2.5.tar.gz
autoconfbuild

src zlib-1.2.7 tar.gz ftp://ftp.simplesystems.org/pub/libpng/png/src/history/zlib/zlib-1.2.7.tar.gz
CHOST=${XPREFIX} ./configure --prefix=$PREFIX
make
make install

src termcap-1.3.1 tar.gz http://ftpmirror.gnu.org/termcap/termcap-1.3.1.tar.gz
MAKEFLAGS="CFLAGS=-fPIC CC=${XPREFIX}-gcc AR=${XPREFIX}-ar RANLIB=${XPREFIX}-ranlib" autoconfconf
make install CC=${XPREFIX}-gcc AR=${XPREFIX}-ar RANLIB=${XPREFIX}-ranlib

src readline-6.3 tar.gz http://ftpmirror.gnu.org/readline/readline-6.3.tar.gz
MAKEFLAGS="SHLIB_LIBS=-ltermcap" \
bash_cv_wcwidth_broken=yes \
autoconfbuild

src tiff-4.0.10 tar.gz http://download.osgeo.org/libtiff/tiff-4.0.10.tar.gz
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
LDFLAGS="-lFLAC -lvorbis -logg" \
autoconfbuild
ed $PREFIX/lib/pkgconfig/sndfile.pc << EOF
%s/ -lsndfile/ -lsndfile -lvorbis -lvorbisenc -lFLAC -logg/
wq
EOF

src libsamplerate-0.1.9 tar.gz http://www.mega-nerd.com/SRC/libsamplerate-0.1.9.tar.gz
ed Makefile.in << EOF
%s/ examples tests//
wq
EOF
AUTOMAKE_FLAGS="--gnu --add-missing --copy -f" ./autogen.sh --host=${XPREFIX} --build=x86_64-linux
autoconfbuild

src expat-2.2.9 tar.xz https://github.com/libexpat/libexpat/releases/download/R_2_2_9/expat-2.2.9.tar.xz
autoconfbuild

src libiconv-1.16 tar.gz https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.16.tar.gz
gl_cv_cc_visibility=no \
autoconfbuild --with-included-gettext --with-libiconv-prefix=$PREFIX

src libxml2-2.9.2 tar.gz ftp://xmlsoft.org/libxslt/libxml2-2.9.2.tar.gz
CFLAGS=" -O0" CXXFLAGS=" -O0" \
autoconfbuild --with-threads=no --with-zlib=$PREFIX --without-python

src gettext-0.19.3 tar.gz http://ftp.gnu.org/pub/gnu/gettext/gettext-0.19.3.tar.gz
autoconfbuild

src libxslt-1.1.33 tar.gz http://xmlsoft.org/sources/libxslt-1.1.33.tar.gz
autoconfbuild --without-python --with-libxml-prefix=$PREFIX

src libpng-1.6.37 tar.xz https://downloads.sourceforge.net/project/libpng/libpng16/1.6.37/libpng-1.6.37.tar.xz
autoconfbuild

src freetype-2.9 tar.gz http://download.savannah.gnu.org/releases/freetype/freetype-2.9.tar.gz
autoconfbuild -with-harfbuzz=no

src util-linux-2.34 tar.xz https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v2.34/util-linux-2.34.tar.xz
scanf_cv_alloc_modifier=as autoconfconf --disable-all-programs \
	--disable-libblkid --disable-libmount --disable-libsmartcols --disable-libfdisk \
	--disable-tls --without-ncurses --enable-libuuid
make && make install

src fontconfig-2.13.1 tar.bz2 http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.1.tar.bz2
ed Makefile.in << EOF
%s/po-conf test/po-conf/
wq
EOF
autoconfbuild --enable-libxml2

src libarchive-3.2.1 tar.gz http://www.libarchive.org/downloads/libarchive-3.2.1.tar.gz
autoconfbuild --disable-bsdtar --disable-bsdcat --disable-bsdcpio --without-openssl

src pixman-0.38.4 tar.gz https://www.cairographics.org/releases/pixman-0.38.4.tar.gz
ed Makefile.am << EOF
%s/ demos test/ demos/
 wq
EOF
autoreconf
autoconfbuild

src cairo-1.14.10 tar.xz http://cairographics.org/releases/cairo-1.14.10.tar.xz
ed Makefile.in << EOF
%s/ test perf//
wq
EOF
ax_cv_c_float_words_bigendian=no \
autoconfbuild --disable-gtk-doc-html --enable-gobject=no --disable-valgrind \
	--enable-interpreter=no --enable-script=no

src libffi-3.2.1 tar.gz ftp://sourceware.org/pub/libffi/libffi-3.2.1.tar.gz
autoconfbuild

src gettext-0.19.3 tar.gz http://ftpmirror.gnu.org/gettext/gettext-0.19.3.tar.gz
CFLAGS=" -O2" CXXFLAGS=" -O2" \
autoconfbuild

################################################################################
apt-get -y install python gettext libglib2.0-dev # /usr/bin/msgfmt , genmarshall
################################################################################

src glib-2.42.0 tar.xz  http://ftp.gnome.org/pub/gnome/sources/glib/2.42/glib-2.42.0.tar.xz
ed glib/valgrind.h << EOF
/#include <stdarg.h>
.i
#include <stdint.h>
.
wq
EOF

patch -p1 << EOF
--- a/glib/gdate.c
+++ b/glib/gdate.c
@@ -2439,6 +2439,8 @@
  *
  * Returns: number of characters written to the buffer, or 0 the buffer was too small
  */
+#pragma GCC diagnostic push
+#pragma GCC diagnostic ignored "-Wformat-nonliteral"
 gsize     
 g_date_strftime (gchar       *s, 
                  gsize        slen, 
@@ -2549,3 +2551,4 @@
   return retval;
 #endif
 }
+#pragma GCC diagnostic pop
EOF

ac_cv_func_posix_getpwuid_r=yes \
ac_cv_func_posix_getgrgid_r=yes \
glib_cv_uscore=no \
glib_cv_rtldglobal_broken=no \
glib_cv_stack_grows=no \
ac_cv_type_sig_atomic_t=no \
autoconfbuild --with-pcre=internal --disable-silent-rules --with-libiconv=yes

################################################################################
dpkg -P gettext || true
################################################################################

src harfbuzz-2.6.2 tar.xz http://www.freedesktop.org/software/harfbuzz/release/harfbuzz-2.6.2.tar.xz
autoconfbuild

src pango-1.40.4 tar.xz http://ftp.gnome.org/pub/GNOME/sources/pango/1.40/pango-1.40.4.tar.xz
autoconfbuild --with-included-modules=yes

src atk-2.14.0 tar.bz2 http://ftp.gnome.org/pub/GNOME/sources/atk/2.14/atk-2.14.0.tar.xz
autoconfbuild --disable-rebuilds

src gdk-pixbuf-2.31.1 tar.xz http://ftp.acc.umu.se/pub/GNOME/sources/gdk-pixbuf/2.31/gdk-pixbuf-2.31.1.tar.xz
autoconfbuild --disable-modules --without-gdiplus --with-included-loaders=yes --enable-gio-sniffing=no

################################################################################
# TODO: consider using Ardour's patched src (which includes the treeview patch)
# other patches in ardour's variant are not relevant for Linux
if false; then

src gtk+-2.24.23 tar.bz http://ardour.org/files/deps/gtk+-2.24.23-x11-ardour6.tar.bz2
# cross-compiling demos does not work
ed Makefile.in << EOF
%s/demos / /
wq
EOF

else

src gtk+-2.24.25 tar.xz http://ftp.gnome.org/pub/gnome/sources/gtk+/2.24/gtk+-2.24.25.tar.xz
# cross-compiling demos does not work
ed Makefile.in << EOF
%s/demos / /
wq
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
fi

# compile + install gtk+
LDFLAGS="-L/usr/lib/$XPREFIX $LDFLAGS" \
autoconfconf --disable-rebuilds # --disable-modules
make
make install
################################################################################

################################################################################
dpkg -P libglib2.0-dev || true
################################################################################

src lv2-1.18.2 tar.bz2 http://ardour.org/files/deps/lv2-1.18.2-g611759d.tar.bz2 -g611759d
wafbuild --no-plugins --copy-headers --lv2dir=$PREFIX/lib/lv2

src serd-0.30.11 tar.bz2 http://ardour.org/files/deps/serd-0.30.11-g36f1cecc.tar.bz2 -g36f1cecc
wafbuild

src sord-0.16.9 tar.bz2 http://ardour.org/files/deps/sord-0.16.9-gd2efdb2.tar.bz2 -gd2efdb2
wafbuild --no-utils

src sratom-0.6.8 tar.bz2 http://ardour.org/files/deps/sratom-0.6.8-gc46452c.tar.bz2 -gc46452c
wafbuild

src lilv-0.24.13 tar.bz2 http://ardour.org/files/deps/lilv-0.24.13-g71a2ff5.tar.bz2 -g71a2ff5
wafbuild

src suil-0.10.8 tar.bz2 http://ardour.org/files/deps/suil-0.10.8-g05c2afb.tar.bz2 -g05c2afb
wafbuild

# NSS...
apt-get -y install libzip-dev
src nss-3.25 tar.gz https://ftp.mozilla.org/pub/security/nss/releases/NSS_3_25_RTM/src/nss-3.25-with-nspr-4.12.tar.gz -with-nspr-4.12
(
	cd nss
	sed -i.bak "s%DSO_LDOPTS\t\t= %DSO_LDOPTS\t\t= -L$PREFIX/lib/ %" coreconf/Linux.mk
	sed -i.bak "s/CC\t\t\t=.*$/CC=$XPREFIX-gcc/" coreconf/Linux.mk
	sed -i.bak "s/CCC\t\t\t=.*$/CCC=$XPREFIX-g++/" coreconf/Linux.mk
	sed -i.bak "s/RANLIB\t\t\t=.*$/RANLIB=$XPREFIX-ranlib/" coreconf/Linux.mk
	sed -i.bak 's/-m32$//;s/-Di386$//;s/x86$/arm/' coreconf/Linux.mk
	sed -i.bak 's/strncpy(cp, "..\/", 3);/memcpy(cp, "..\/", 3);/g' coreconf/nsinstall/pathsub.c
if test "$XARCH" = "arm64"; then
	sed -i.bak 's/-DMP_ASSEMBLY_MULTIPLY -DMP_ASSEMBLY_SQUARE/-DNSS_USE_64/;s/-DSHA_NO_LONG_LONG//;s/mpi_arm.c//' lib/freebl/Makefile
fi
	sed -i.bak 's/cmd external_tests//' manifest.mn
	CROSS_COMPILE=1 MAKEFLAGS=-j1 XCFLAGS="-I${PREFIX}/include/" \
		make nss_build_all BUILD_OPT=1 NSDISTMODE=copy NSPR_CONFIGURE_OPTS="--target=${XPREFIX} --build=x86_64-linux" NATIVE_CC=gcc
	cp -L ../dist/*.OBJ/lib/*.so $PREFIX/lib/
	cp -L ../dist/*.OBJ/lib/*.a $PREFIX/lib/
	cp -r ../dist/*.OBJ/include $PREFIX/include/nss3
	cp -r ../dist/public/nss $PREFIX/include/nss3api
	cp -r ../dist/private/nss $PREFIX/include/nss3private
	cat > $PREFIX/lib/pkgconfig/nss.pc << EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include
Name: NSS
Version: 3.45
Description: Network Security S
Libs: -L\${libdir} -lssl3 -lsmime3 -lnss3 -lplds4 -lplc4 -lnspr4 -lnssutil3 -lpthread -ldl
Cflags: -I\${includedir}/nss3 -I\${includedir}/nss3api -I\${includedir}/nss3private
EOF
)

src nss-pem-1.0.2 tar.xz http://ardour.org/files/deps/nss-pem-1.0.2.tar.xz
(
	set -e
	mkdir build
	ed src/CMakeLists.txt << EOF
0i
set(CMAKE_C_COMPILER ${XPREFIX}-gcc)
set(CMAKE_CXX_COMPILER ${XPREFIX}-g++)
set(CMAKE_RC_COMPILER ${XPREFIX}-windres)
.
wq
EOF
	cd build
	cmake ../src
	make -j1
	cp libnsspem.so $PREFIX/lib
)

src curl-7.66.0 tar.bz2 http://curl.haxx.se/download/curl-7.66.0.tar.bz2
autoconfbuild --without-ssl --with-nss
echo "Requires: nss" >> $PREFIX/lib/pkgconfig/libcurl.pc

src libsigc++-2.4.1 tar.xz http://ftp.gnome.org/pub/GNOME/sources/libsigc++/2.4/libsigc++-2.4.1.tar.xz
autoconfbuild

src glibmm-2.42.0 tar.xz http://ftp.gnome.org/pub/GNOME/sources/glibmm/2.42/glibmm-2.42.0.tar.xz
autoconfbuild

src cairomm-1.11.2 tar.gz http://cairographics.org/releases/cairomm-1.11.2.tar.gz
autoconfbuild

src pangomm-2.34.0 tar.xz http://ftp.acc.umu.se/pub/gnome/sources/pangomm/2.34/pangomm-2.34.0.tar.xz
autoconfbuild

src atkmm-2.22.7 tar.xz http://ftp.gnome.org/pub/GNOME/sources/atkmm/2.22/atkmm-2.22.7.tar.xz
autoconfbuild

src gtkmm-2.24.4 tar.xz http://ftp.acc.umu.se/pub/GNOME/sources/gtkmm/2.24/gtkmm-2.24.4.tar.xz
autoconfbuild

src fftw-3.3.8 tar.gz http://fftw.org/fftw-3.3.8.tar.gz
autoconfbuild --enable-shared --enable-threads
make clean
autoconfbuild --enable-shared --enable-single --enable-float --enable-threads

src raptor2-2.0.14 tar.gz http://download.librdf.org/source/raptor2-2.0.14.tar.gz
ac_cv_header_libinn_h=no \
autoconfbuild --with-www=none \
	--with-curl-config=$PREFIX/bin/curl-config \
	--with-xml2-config=$PREFIX/bin/xml2-config \
	--with-xstl-config=$PREFIX/bin/xslt-config

src LRDF-0.5.1-rg tar.gz https://github.com/x42/LRDF/archive/0.5.1-rg.tar.gz
sh ./autogen.sh --host=${XPREFIX} --build=x86_64-linux
autoconfbuild

################################################################################
src taglib-1.9.1 tar.gz http://taglib.github.io/releases/taglib-1.9.1.tar.gz
#set(CMAKE_SYSTEM_NAME Windows)
ed CMakeLists.txt << EOF
0i
set(CMAKE_C_COMPILER ${XPREFIX}-gcc)
set(CMAKE_CXX_COMPILER ${XPREFIX}-g++)
set(CMAKE_RC_COMPILER ${XPREFIX}-windres)
.
wq
EOF
sed -i 's/\~ListPrivate/virtual ~ListPrivate/' taglib/toolkit/tlist.tcc
rm -rf build/
mkdir build && cd build
	cmake \
		-DCMAKE_INSTALL_PREFIX=$PREFIX -DCMAKE_BUILD_TYPE=Release -DZLIB_ROOT=$PREFIX \
		..
make $MAKEFLAGS
make install

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
make $MAKEFLAGS CFLAGS="-Wno-error"
make install

################################################################################
src boost_1_68_0 tar.bz2 http://sourceforge.net/projects/boost/files/boost/1.68.0/boost_1_68_0.tar.bz2
./bootstrap.sh --prefix=$PREFIX --with-libraries=exception,atomic
if test "$XARCH" = "arm64"; then
	sed -i 's/using gcc.*$/using gcc : arm : aarch64-linux-gnu-g++ ;/' project-config.jam
else
	sed -i 's/using gcc.*$/using gcc : arm : arm-linux-gnueabihf-g++ ;/' project-config.jam
fi
./b2 --prefix=$PREFIX \
	toolset=gcc-arm \
	variant=release \
	threading=multi \
	link=shared \
	runtime-link=shared \
	$MAKEFLAGS install

################################################################################
#download ladspa.h http://www.ladspa.org/ladspa_sdk/ladspa.h.txt
download ladspa.h http://community.ardour.org/files/ladspa.h
cp ${SRCDIR}/ladspa.h $PREFIX/include/ladspa.h
################################################################################

src vamp-plugin-sdk-2.8.0 tar.gz https://code.soundsoftware.ac.uk/attachments/download/2450/vamp-plugin-sdk-2.8.0.tar.gz
ed Makefile.in << EOF
%s/= ar/= ${XPREFIX}-ar/
%s/= ranlib/= ${XPREFIX}-ranlib/
wq
EOF
MAKEFLAGS="sdk ${CONCURRENCY}" autoconfbuild

src rubberband-1.8.1 tar.bz2 http://code.breakfastquay.com/attachments/download/34/rubberband-1.8.1.tar.bz2
ed Makefile.in << EOF
%s/= ar/= ${XPREFIX}-ar/
wq
EOF
autoconfbuild
ed $PREFIX/lib/pkgconfig/rubberband.pc << EOF
%s/ -lrubberband/ -lrubberband -lfftw3/
wq
EOF

src aubio-0.3.2 tar.gz http://aubio.org/pub/aubio-0.3.2.tar.gz
./bootstrap
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
ed lib/event-libs/glib/glib.c << EOF
26i
#ifndef G_SOURCE_FUNC
#define G_SOURCE_FUNC(f) ((GSourceFunc) (void (*)(void)) (f))
#endif
.
wq
EOF
mkdir build && cd build
cmake -DLWS_WITH_SSL=off -DLWS_WITH_GLIB=YES \
	-DCMAKE_C_FLAGS="-isystem ${PREFIX}/include ${STACKCFLAGS}" \
	-DCMAKE_C_COMPILER=`which ${XPREFIX}-gcc` \
	-DLWS_WITHOUT_TEST_SERVER=on -DLWS_WITHOUT_TESTAPPS=on \
	-DCMAKE_INSTALL_PREFIX=$PREFIX -DCMAKE_BUILD_TYPE=Release \
	..
make $MAKEFLAGS && make install

################################################################################
src libusb-1.0.20 tar.bz2 http://downloads.sourceforge.net/project/libusb/libusb-1.0/libusb-1.0.20/libusb-1.0.20.tar.bz2
MAKEFLAGS= \
autoconfbuild # --disable-udev

################################################################################
echo "*** STACK COMPLETE"

cd "$this_script_dir"
git log -n 1 --pretty="%H" -- x-armhf.sh > ${BUILDROOT}/stack/.vers

fi  # $NOSTACK
################################################################################

################################################################################
# CHECK OUT ARDOUR & GMSYNTH

ARDOURSRC=${BUILDROOT}/ardour
GMSYNTHSRC=${BUILDROOT}/gmsynth.lv2
mkdir -p $ARDOURSRC

# create a git cache to speed up future clones
if test ! -d ${SRCDIR}/ardour.git.reference; then
	git clone --mirror git://git.ardour.org/ardour/ardour.git ${SRCDIR}/ardour.git.reference
fi
git clone --reference ${SRCDIR}/ardour.git.reference git://git.ardour.org/ardour/ardour.git $ARDOURSRC || true

if test ! -d ${SRCDIR}/gmsynth.lv2.git.reference; then
	git clone --mirror git://github.com/x42/gmsynth.lv2.git ${SRCDIR}/gmsynth.lv2.git.reference
fi
git clone --reference ${SRCDIR}/gmsynth.lv2.git.reference git://github.com/x42/gmsynth.lv2.git ${GMSYNTHSRC} || true

if test -n "$MIXBUS"; then
	MIXBUSSRC=${BUILDROOT}/mixbus
	git clone git://git.ardour.org/harrison/mixbus.git ${BUILDROOT}/mixbus || true
	cd ${MIXBUSSRC}
	if test -z "$NOGITPULL"; then
		git reset --hard
		git pull || true
	fi
fi

# update if not changed
cd ${GMSYNTHSRC}
if git diff-files --quiet --ignore-submodules -- && git diff-index --cached --quiet HEAD --ignore-submodules --; then
	git pull || true
fi

cd ${ARDOURSRC}
if test -n "$NOGITPULL"; then
	true
elif false; then # XXX -- TODO allow dedicated revisions
	git reset --hard 5.12
	git cherry-pick --no-commit 7036b2825
else
	git reset --hard
	git pull || true
fi

################################################################################

if test -n "$NOCOMPILE"; then
	echo "Done. (NOCOMPILE)"
	echo "ardour source in ${ARDOURSRC}"
	exit
fi

################################################################################

if test -n "$DEMO"; then
	OUTDIR="${OUTDIR}_FREE"
fi

rm -rf $OUTDIR
mkdir -p $OUTDIR
touch ${OUTDIR}/build_failed

git describe > ${OUTDIR}/version.txt
git rev-parse HEAD > ${OUTDIR}/git_revision.txt
date -u "+%F %T UTC" > ${OUTDIR}/build_start.tme

################################################################################

# install optional dynamically linked libs on the target
apt-get -y install python # for waf
apt-get -y install libasound-dev:$WARCH libjack-jackd2-dev:$WARCH libudev-dev:$WARCH libdbus-1-dev:$WARCH
apt-get -y install libpulse-dev:$WARCH

################################################################################
################################################################################
# TODO: expose thses as parameters, options

APPNAME=Ardour
VENDOR=Ardour
EXENAME=ardour
if test -z "$ARDOURCFG"; then
	ARDOURCFG="--ptformat --libjack=weak"
fi
if test -n "$DEMO"; then
	ARDOURCFG="$ARDOURCFG --freebie"
fi

if test -z "$DBG"; then
	ARDOURCFG="$ARDOURCFG --optimize"
elif test "$DBG" == "optimize"; then
	ARDOURCFG="$ARDOURCFG --debug-symbols --optimize"
fi

if test "$XARCH" = "arm64"; then
	#OPTARM="-mcpu=cortex-a7 -mtune=cortex-a7"
	ARMNEON=""
elif test "$XARCH" = "armhf"; then
	ARMNEON="-mfpu=neon-vfpv4 -mfloat-abi=hard -mvectorize-with-neon-quad"
else
	ARMNEON=""
fi

if test -n "$MIXBUS" -a "$MIXBUS" = "32C"; then
	ARDOURSRC=$MIXBUSSRC
	APPNAME=Mixbus32C
	VENDOR=Harrison
	EXENAME=mixbus32c
	ARDOURCFG="$ARDOURCFG --program-name=Mixbus32C"
	CHANNELSTRIP=harrison_channelstrip6_32c
elif test -n "$MIXBUS"; then
	ARDOURSRC=$MIXBUSSRC
	APPNAME=Mixbus
	VENDOR=Harrison
	EXENAME=mixbus
	CHANNELSTRIP=harrison_channelstrip6
	ARDOURCFG="$ARDOURCFG --program-name=Mixbus"
fi

################################################################################
################################################################################

export CC=${XPREFIX}-gcc
export CXX=${XPREFIX}-g++
export CPP=${XPREFIX}-cpp
export AR=${XPREFIX}-ar
export LD=${XPREFIX}-ld
export NM=${XPREFIX}-nm
export AS=${XPREFIX}-as
export STRIP=${XPREFIX}-strip
export WINRC=${XPREFIX}-windres
export RANLIB=${XPREFIX}-ranlib
export DLLTOOL=${XPREFIX}-dlltool

################################################################################

cd ${GMSYNTHSRC}
make clean all OPTIMIZATIONS="-O3 $ARMNEON -ffast-math -fomit-frame-pointer -fno-finite-math-only -DNDEBUG"

################################################################################

if test -n "$MIXBUS" -a -d /home/ardour/Ardour_Harrison/; then
	#cd /home/ardour/Ardour_Harrison/
	#git pull

	cd /home/ardour/Ardour_Harrison/ladspa6/
	make clean ${WARCH}
	cp -v harrison_channelstrip6.${WARCH}.so ${SRCDIR}/

	cd /home/ardour/Ardour_Harrison/ladspa6_32/
	make clean ${WARCH}
	cp -v harrison_channelstrip6_32c.${WARCH}.so ${SRCDIR}/

	cd /home/ardour/Ardour_Harrison/vamp/
	OUTDIR=${SRCDIR}/ make -f Makefile.builder ${WARCH}
fi

################################################################################

cd ${ARDOURSRC}
rm -rf build
CFLAGS="$EXTRA_FLAGS" \
CXXFLAGS="$EXTRA_FLAGS" \
LDFLAGS="-L${PREFIX}/lib" \
DEPSTACK_ROOT="$PREFIX" \
./waf configure \
  --strict \
  --keepflags \
  --also-include=${PREFIX}/include \
  --dist-target=${AARCH} \
	--prefix=/ --configdir=/etc \
  $ARDOURCFG \
2>&1 \
| tee ${OUTDIR}/build_log.txt

./waf ${CONCURRENCY} \
2>&1 \
| tee -a ${OUTDIR}/build_log.txt

echo " === build complete, creating translations"
apt-get -qq -y install gettext makeself chrpath rsync
./waf i18n

################################################################################

echo " === bundling"
cd tools/linux_packaging/
. ../define_versions.sh
cd ../..

if test -n "$DBG"; then
  # override $DEBUG from define_versions.sh
  DEBUG=T
fi

APPDIR=${APPNAME}_${WARCH}-${release_version}
APP_VER_NAME=${APPNAME}-${release_version}
if [ x$DEBUG = xT ]; then
	APPDIR="${APPDIR}-dbg"
	APP_VER_NAME="${APP_VER_NAME}-dbg"
	BUILDTYPE="dbg"
fi

BUNDLEDIR=$TMPDIR/$APPDIR
APPLIB=${BUNDLEDIR}/lib/ardour${major_version}

rm -rf ${BUNDLEDIR}
DESTDIR=${BUNDLEDIR}/ ./waf install

# fix main binary name ardour-X.Y.Z -> mixbus-X.Y.Z
if ! test -f "$APPLIB/${EXENAME}-${release_version}"; then
	mv -v $APPLIB/ardour-${release_version} $APPLIB/${EXENAME}-${release_version}
fi

# copy dynamically loaded .so
if test -d $PREFIX/lib/suil-0/ ; then
	cp $PREFIX/lib/suil-0/lib* $APPLIB/
fi
cp -a ${GMSYNTHSRC}/build ${APPLIB}/LV2/gmsynth.lv2

cp -v $PREFIX/lib/libsoftokn3.so $APPLIB/
cp -v $PREFIX/lib/libfreeblpriv3.so $APPLIB/
cp -v $PREFIX/lib/libnsspem.so $APPLIB/
chrpath -r foo $APPLIB/libsoftokn3.so || true
chrpath -r foo $APPLIB/libfreeblpriv3.so || true
chrpath -r foo $APPLIB/libnsspem.so || true

echo " === copying libraries"
set +e
checkIdx=0
while [ true ] ; do
	missing=false
	filelist=`find $APPLIB/ -type f`
	for file in $filelist ; do
		if ! file $file | grep -qs ELF ; then
			continue
		fi
		for i in "${depCheckedList[@]}"; do
			if [ $i == $file ]; then
				continue 2
			fi
		done
		depCheckedList[$checkIdx]=$file
		checkIdx=$(($checkIdx + 1))

		if echo $file | grep -qs 'libsuil_.*qt[45]' ; then continue; fi

		DEPLIB=`$XPREFIX-objdump -x $file | grep NEEDED | awk '//{print $2;}'`
		for lib in $DEPLIB; do
			echo -n "."
			dep=$(find ${PREFIX}/lib $APPLIB -name "$lib" -print0 | xargs -0 -r -L 1 realpath | grep -v libwine.so)

			if test -z "$dep" ; then continue; fi
			if echo $dep | grep -qs "^/lib/" ; then continue; fi
			if echo $dep | grep -qs libjack ; then continue; fi
			if echo $dep | grep -qs libasound ; then continue; fi
			if echo $dep | grep -qs libX\. ; then continue; fi
			if echo $dep | grep -qs libxcb ; then continue; fi
			if echo $dep | grep -qs libICE\. ; then continue; fi
			if echo $dep | grep -qs libSM\. ; then continue; fi
			if echo $dep | grep -qs 'libc\.' ; then continue; fi
			if echo $dep | grep -qs libstdc++ ; then continue; fi
			if echo $dep | grep -qs libdbus ; then continue; fi
			if echo $dep | grep -qs libudev ; then continue; fi

			base=`basename $dep`
			if ! test -f $APPLIB/$base; then
				cp $dep $APPLIB/
				chmod 755 $APPLIB/$base
				chrpath -r foo $APPLIB/$base &>/dev/null
				missing=true
			fi
		done
	done
	echo "~"
	if test x$missing = xfalse; then
		break
	fi
done
set -e

################################################################################
# strip libraries
echo " === Finishing up bundle"
find $APPLIB/ -name "*.so*" -print0 | xargs -0 chmod u+w
find $APPLIB/ -name "*.so*" -print0 | xargs -0 chmod a+rx
if [ x$DEBUG = xF ]; then
	echo " === Stripping all libraries"
	${XPREFIX}-strip -s ${APPLIB}/ardour-*
	find $APPLIB/ -name "*.so*" -print0 | xargs -0 ${XPREFIX}-strip -s
fi

################################################################################
# remove ABI suffix a-la ldconfig/ldd
find $APPLIB/ -name "*.so" -type l -print0 | xargs -0 rm

for lib in $APPLIB/*.so.[0-9]*.[0-9.]* $APPLIB/*/*.so.[0-9]*.[0-9.]*; do
	mv $lib `echo $lib | sed 's/\.so\.\([0-9]*\).*$/.so.\1/'`
done

# Remove ABI suffix, symlink *.so.
# This fixes plugins that dynamically open libs.
# e.g. JUCE option to lazily loading libcurl.so
(
cd $APPLIB/
for lib in *.so.[0-9]* */*.so.[0-9]*; do
  link=$(echo $lib | sed 's/\.[0-9]*$//')
  ln -s $lib $link;
done
)

################################################################################
# remove "ardourN" subdirs
mv ${BUNDLEDIR}/lib/ ${BUNDLEDIR}/x-lib/
mv ${BUNDLEDIR}/etc/ ${BUNDLEDIR}/x-etc/
mv ${BUNDLEDIR}/share/ ${BUNDLEDIR}/x-share/
mv ${BUNDLEDIR}/x-lib/ardour${major_version} ${BUNDLEDIR}/lib
mv ${BUNDLEDIR}/x-etc/ardour${major_version} ${BUNDLEDIR}/etc
mv ${BUNDLEDIR}/x-share/ardour${major_version} ${BUNDLEDIR}/share/
rmdir ${BUNDLEDIR}/x-lib/
rmdir ${BUNDLEDIR}/x-etc/
rmdir ${BUNDLEDIR}/x-share/

################################################################################
# fixup..
mkdir ${BUNDLEDIR}/lib/gtkengines
mv ${BUNDLEDIR}/lib/engines ${BUNDLEDIR}/lib/gtkengines
mv ${BUNDLEDIR}/lib/vamp/* ${BUNDLEDIR}/lib/
rmdir ${BUNDLEDIR}/lib/vamp/
rm ${BUNDLEDIR}/lib/*.a

find ${BUNDLEDIR}/lib/ -type l | xargs rm

################################################################################
################################################################################
# replace/fix start scripts
echo " === Re-creating scripts"

rm -rf ${BUNDLEDIR}/bin
mkdir ${BUNDLEDIR}/bin

if test -f ${BUNDLEDIR}/lib/utils/ardour-util.sh; then
  cat > ${BUNDLEDIR}/lib/utils/ardour-util.sh << EOF
#!/bin/sh

UTIL_DIR=\$(dirname \$(readlink -f \$0))
LIB_DIR=\$(dirname \$UTIL_DIR)
INSTALL_DIR=\$(dirname \$LIB_DIR)

export LD_LIBRARY_PATH=\$LIB_DIR\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}

export ARDOUR_DATA_PATH=\$INSTALL_DIR/share
export ARDOUR_CONFIG_PATH=\$INSTALL_DIR/etc
export ARDOUR_DLL_PATH=\$INSTALL_DIR/lib
export VAMP_PATH=\$INSTALL_DIR/lib/\${VAMP_PATH:+:\$VAMP_PATH}

SELF=\$(basename \$0)
exec "\$UTIL_DIR/\$SELF" "\$@"
EOF
  chmod +x ${BUNDLEDIR}/lib/utils/ardour-util.sh
	for file in ${BUNDLEDIR}/lib/utils/*; do
		if ! file $file | grep -qs ELF ; then
			continue
		fi
		ln -s ../lib/utils/ardour-util.sh ${BUNDLEDIR}/bin/`basename $file`
	done

fi

if test -x ${BUNDLEDIR}/lib/luasession; then
cat >> ${BUNDLEDIR}/bin/${EXENAME}${major_version}-lua << EOF
#!/bin/sh

BIN_DIR=\$(dirname \$(readlink -f \$0))
INSTALL_DIR=\$(dirname \$BIN_DIR)
LIB_DIR=\$INSTALL_DIR/lib

export LD_LIBRARY_PATH=\$LIB_DIR\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}

export ARDOUR_DATA_PATH=\$INSTALL_DIR/share
export ARDOUR_CONFIG_PATH=\$INSTALL_DIR/etc
export ARDOUR_DLL_PATH=\$INSTALL_DIR/lib
export VAMP_PATH=\$INSTALL_DIR/lib/\${VAMP_PATH:+:\$VAMP_PATH}

exec "\$LIB_DIR/luasession" "\$@"
EOF
  chmod +x ${BUNDLEDIR}/bin/${EXENAME}${major_version}-lua
fi

cat >> ${BUNDLEDIR}/bin/${EXENAME}${major_version} << EOF
#!/bin/sh

checkdebug(){
	for arg in "\$@"
	do
		case "\$arg" in
			--gdb )
				DEBUG="T"
		esac
	done
}

checkdebug "\$@"

BIN_DIR=\$(dirname \$(readlink -f \$0))
INSTALL_DIR=\$(dirname \$BIN_DIR)
LIB_DIR=\$INSTALL_DIR/lib
ETC_DIR=\$INSTALL_DIR/etc

export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH
export PREBUNDLE_ENV="\$(env)"

export ARDOUR_BUNDLED=true
export ARDOUR_SELF=`basename "\$0"`

export GTK_MODULES=""
export LD_LIBRARY_PATH=\$LIB_DIR\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}

if [ "T" = "\$DEBUG" ]; then
	export ARDOUR_INSIDE_GDB=1
	exec gdb \$LIB_DIR/${EXENAME}-${release_version}
else
	exec \$LIB_DIR/${EXENAME}-${release_version} "\$@"
fi
EOF

chmod +x ${BUNDLEDIR}/bin/${EXENAME}${major_version}

################################################################################

cp ${ARDOURSRC}/build/tools/sanity_check/sanityCheck ${BUNDLEDIR}/bin/

################################################################################
# TODO: video tools (harvid, xjadeo, ffmpeg)
# on ARM?! -> if needed use distro provided ones

################################################################################
echo " === Bunding Plugins"

if test -n "$MIXBUS"; then
	mkdir -p ${BUNDLEDIR}/lib/ladspa/strip/

	cp -v ${SRCDIR}/${CHANNELSTRIP}.${WARCH}.so ${BUNDLEDIR}/lib/ladspa/strip/${CHANNELSTRIP}.so
	cp -v ${SRCDIR}/harrison_vamp.${WARCH}.so ${BUNDLEDIR}/lib/harrison_vamp.so

	chmod +x ${BUNDLEDIR}/lib/ladspa/strip/${CHANNELSTRIP}.so
	chmod +x ${BUNDLEDIR}/lib/harrison_vamp.so
fi

################################################################################
# x42-plugins -- only available for WARCH "arm64" "armhf"
if test x$WITH_X42_LV2 != x ; then
	mkdir -p ${BUNDLEDIR}/lib/LV2
	echo "Adding x42 Plugins"
	for proj in x42-meters x42-midifilter x42-stereoroute x42-eq setBfree x42-avldrums x42-whirl x42-limiter x42-tuner; do
		X42_VERSION=$(curl -s -S http://x42-plugins.com/x42/linux/${proj}.latest.txt)
		rsync -a -q --partial \
			rsync://x42-plugins.com/x42/linux/${proj}-lv2-linux-${WARCH}-${X42_VERSION}.zip \
			"${SRCDIR}/${proj}-lv2-linux-${WARCH}-${X42_VERSION}.zip"
		unzip -q -d "${BUNDLEDIR}/lib/LV2/" "${SRCDIR}/${proj}-lv2-linux-${WARCH}-${X42_VERSION}.zip"
	done
fi

################################################################################
echo " === Adding uninstaller"
# Add the uninstaller
sed -e "s/%REPLACE_PGM%/${APPNAME}/" -e "s/%REPLACE_VENDOR%/${VENDOR}/" -e "s/%REPLACE_MAJOR_VERSION%/${major_version}/" -e "s/%REPLACE_VERSION%/${release_version}/" -e "s/%REPLACE_TYPE%/${BUILDTYPE}/" \
	< ${ARDOURSRC}/tools/linux_packaging/uninstall.sh.in \
	> ${BUNDLEDIR}/bin/${APP_VER_NAME}.uninstall.sh
chmod a+x ${BUNDLEDIR}/bin/${APP_VER_NAME}.uninstall.sh

################################################################################
################################################################################

echo " === Creating .tar"
cd $TMPDIR
rm -f $APPDIR.tar
tar -cf $APPDIR.tar $APPDIR
ls -l $TMPDIR/$APPDIR.tar
( cd ${APPDIR}; find . ) > ${OUTDIR}/file_list.txt

PACKAGEDIR=`mktemp -d`
trap "rm -rf ${PACKAGEDIR}" EXIT

mv $TMPDIR/$APPDIR.tar ${PACKAGEDIR}/
du -sb ${BUNDLEDIR}/  | awk '{print $1}' > ${PACKAGEDIR}/.${APPDIR}.size
#( cd ${BUNDLEDIR}/ ; find . ) > /tmp/file_list.txt

rm -rf ${BUNDLEDIR}

################################################################################
################################################################################

# Add the stage2.run script
sed -e "s/%REPLACE_MAJOR_VERSION%/${major_version}/;s/%REPLACE_PGM%/${APPNAME}/;s/%REPLACE_VENDOR%/Ardour/;s/%REPLACE_EXE%/${EXENAME}/;s/%REPLACE_GCC5%/true/;s/%REPLACE_WINE%/false/" \
	< ${ARDOURSRC}/tools/linux_packaging/stage2.run.in \
	> ${PACKAGEDIR}/.stage2.run
chmod a+x ${PACKAGEDIR}/.stage2.run

cp ${ARDOURSRC}/tools/linux_packaging/install.sh ${PACKAGEDIR}/
cp ${ARDOURSRC}/tools/linux_packaging/README ${PACKAGEDIR}/

#MAKESELFOPTS="--bzip2"
MAKESELFOPTS="--xz --complevel 9"
## makeself [params] archive_dir file_name label startup_script [args]
makeself ${MAKESELFOPTS} ${PACKAGEDIR}/ $OUTDIR/${APPDIR}.run ${APPNAME} ./install.sh

ls -l $OUTDIR/${APPDIR}.run

rm ${OUTDIR}/build_failed
touch ${OUTDIR}/build_ok

for file in ${OUTDIR}/*.run; do
	md5sum $file | cut -d ' ' -f 1 > ${file}.md5sum
	sha1sum $file | cut -d ' ' -f 1 > ${file}.sha1sum
done

date -u "+%F %T UTC" > ${OUTDIR}/build_end.tme

#!/usr/bin/env bash

: ${CONCURRENCY=-j4}

: ${MAKEFLAGS=$CONCURRENCY}
: ${STACKCFLAGS="-O2 -g"}

: ${SRCDIR=${HOME}/src/src_cache}
: ${BUILDROOT=${HOME}}

###############################################################################

XHOST=aarch64-apple-darwin

GLOBAL_CPPFLAGS="-Wno-error=unused-command-line-argument"
GLOBAL_CFLAGS="-arch arm64 -DMAC_OS_X_VERSION_MAX_ALLOWED=110000 -mmacosx-version-min=11.0"
GLOBAL_CXXFLAGS="-arch arm64 --stdlib=libc++ -DMAC_OS_X_VERSION_MAX_ALLOWED=110000 -mmacosx-version-min=11.0"
GLOBAL_LDFLAGS="-headerpad_max_install_names --stdlib=libc++ -arch arm64"

###############################################################################
### HERE BE DRAGONS ###########################################################
###############################################################################

pushd "`/usr/bin/dirname \"$0\"`" > /dev/null; this_script_dir="`pwd`"; popd > /dev/null

set -e

: ${PREFIX=${BUILDROOT}/gtk/inst}
: ${BLDDEP=${BUILDROOT}/gtk/tool}
: ${BUILDD=${BUILDROOT}/gtk/src}

mkdir -p ${SRCDIR}
mkdir -p ${PREFIX}
mkdir -p ${BUILDD}

unset PKG_CONFIG_PATH
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig
#export PKG_CONFIG=/usr/bin/pkg-config

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
	CPPFLAGS="${GLOBAL_CPPFLAGS} -I${PREFIX}/include$CPPFLAGS" \
	CFLAGS="${GLOBAL_CFLAGS} -I${PREFIX}/include ${STACKCFLAGS} $CFLAGS" \
	CXXFLAGS="${GLOBAL_CXXFLAGS} -I${PREFIX}/include ${STACKCFLAGS} $CXXFLAGS" \
	LDFLAGS="${GLOBAL_LDFLAGS} -L${PREFIX}/lib $LDFLAGS" \
	./configure --build=x86_64-apple-darwin --host=${XHOST} \
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
	CPPFLAGS="${GLOBAL_CPPFLAGS} -I${PREFIX}/include$CPPFLAGS" \
	CFLAGS="${GLOBAL_CFLAGS} -I${PREFIX}/include ${STACKCFLAGS} $CFLAGS" \
	CXXFLAGS="${GLOBAL_CXXFLAGS} -I${PREFIX}/include ${STACKCFLAGS} $CXXFLAGS" \
	LDFLAGS="${GLOBAL_LDFLAGS} -L${PREFIX}/lib $LDFLAGS" \
	./waf configure --prefix=$PREFIX $@ \
	&& ./waf && ./waf install
}

function nativebuild {
	set -e
	PKG_CONFIG_PATH=${BLDDEP}/lib/pkgconfig \
	CPPFLAGS="-I${BLDDEP}/include $CPPFLAGS" \
	LDFLAGS="-headerpad_max_install_names -Bsymbolic -L${BLDDEP}/lib $LDFLAGS" \
	./configure --prefix=$PREFIX $@
	make $MAKEFLAGS
	make install
}

################################################################################

rm -rf ${PREFIX}
rm -rf ${BUILDD}
rm -rf ${BLDDEP}

mkdir -p ${PREFIX}
mkdir -p ${BUILDD}
mkdir -p ${BLDDEP}

export PATH="${BLDDEP}/bin:$PREFIX/bin:$PATH"
export ACLOCAL_PATH=$PREFIX/share/aclocal

PYVERS=`python --version 2>&1 | cut -d ' ' -f 2 | cut -b 1-3`
mkdir -p $BLDDEP/lib/python${PYVERS}/site-packages/

################################################################################
# tools to build tools

src m4-1.4.18 tar.gz http://ftp.gnu.org/gnu/m4/m4-1.4.18.tar.gz
PREFIX="${BLDDEP}" nativebuild

src make-4.1 tar.gz http://ftp.gnu.org/gnu/make/make-4.1.tar.gz
nativebuild
hash make

src autoconf-2.69 tar.xz http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz
PREFIX="${BLDDEP}" nativebuild
hash autoconf
hash autoreconf

src automake-1.14.1 tar.gz http://ftp.gnu.org/gnu/automake/automake-1.14.1.tar.gz
PREFIX="${BLDDEP}" nativebuild
hash automake

src libtool-2.4.2 tar.gz http://ftp.gnu.org/gnu/libtool/libtool-2.4.2.tar.gz
PREFIX="${BLDDEP}" nativebuild
hash libtoolize

src make-4.1 tar.gz http://ftp.gnu.org/gnu/make/make-4.1.tar.gz
nativebuild
hash make

src libiconv-1.16 tar.gz https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.16.tar.gz
PREFIX="${BLDDEP}" nativebuild --with-included-gettext --with-libiconv-prefix=${BLDDEP}

src libffi-3.2.1 tar.gz ftp://sourceware.org/pub/libffi/libffi-3.2.1.tar.gz
PREFIX="${BLDDEP}" nativebuild

src gettext-0.21 tar.gz http://ftp.gnu.org/pub/gnu/gettext/gettext-0.21.tar.gz
PREFIX="${BLDDEP}" nativebuild --disable-curses --with-included-gettext --with-libiconv-prefix="${BLDDEP}" --disable-java --disable-csharp --disable-openmp --without-bzip2 --without-xz

src glib-2.42.0 tar.xz  http://ftp.gnome.org/pub/gnome/sources/glib/2.42/glib-2.42.0.tar.xz
LIBFFI_CFLAGS="-I${BLDDEP}/lib/libffi-3.2.1/include" \
LIBFFI_LIBS="-L${BLDDEP}/lib -lffi" \
PREFIX="${BLDDEP}" nativebuild --with-pcre=internal --disable-silent-rules --with-libiconv=yes

src pkg-config-0.28 tar.gz http://pkgconfig.freedesktop.org/releases/pkg-config-0.28.tar.gz
CPPFLAGS="-I${BLDDEP}/include" LDFLAGS="-headerpad_max_install_names -L${BLDDEP}/lib" \
GLIB_CFLAGS="-I${BLDDEP}/include/glib-2.0 -I${BLDDEP}/lib/glib-2.0/include" GLIB_LIBS="-L${BUILDD}/lib -lglib-2.0 -lintl" \
./configure --prefix=$PREFIX
make $MAKEFLAGS
make install
hash pkg-config

src cmake-3.18.4 tar.gz http://www.cmake.org/files/v3.18/cmake-3.18.4.tar.gz
./bootstrap --prefix=${BLDDEP}
make
make install

################################################################################
# deps needed to autoreconf gtk+

src intltool-0.50.2 tar.gz http://launchpad.net/intltool/trunk/0.50.2/+download/intltool-0.50.2.tar.gz
PREFIX="${BLDDEP}" nativebuild

src libxml2-2.9.2 tar.gz ftp://xmlsoft.org/libxslt/libxml2-2.9.2.tar.gz
PYTHONPATH=$BLDDEP/lib/python${PYVERS}/site-packages/ \
PREFIX="${BLDDEP}" CFLAGS=" -O0" CXXFLAGS=" -O0" \
nativebuild --with-threads=no --with-python --with-python-install-dir=$BLDDEP/lib/python${PYVERS}/site-packages/

src libxslt-1.1.33 tar.gz http://xmlsoft.org/sources/libxslt-1.1.33.tar.gz
PREFIX="${BLDDEP}" nativebuild --without-python --with-libxml-prefix=$BLDDEP

mv $BLDDEP/bin/xsltproc $BLDDEP/bin/xsltproc.bin
cat << EOF >$BLDDEP/bin/xsltproc
#!/bin/sh
exec xsltproc.bin --nonet "\$@"
EOF
chmod a+x $BLDDEP/bin/xsltproc

src itstool-2.0.2 tar.bz2 http://files.itstool.org/itstool/itstool-2.0.2.tar.bz2
PYTHONPATH=$BLDDEP/lib/python${PYVERS}/site-packages/ \
PREFIX="${BLDDEP}" nativebuild

src gnome-common-2.34.0 tar.bz2 http://ftp.acc.umu.se/pub/gnome/sources/gnome-common/2.34/gnome-common-2.34.0.tar.bz2
PREFIX="${BLDDEP}" nativebuild

src gtk-osx-docbook-1.0 tar.gz http://downloads.sourceforge.net/project/gtk-osx/GTK-OSX%20Build/gtk-osx-docbook-1.0.tar.gz
JHBUILD_PREFIX=${BLDDEP} make install

src gnome-doc-utils-0.20.10 tar.xz http://ftp.acc.umu.se/pub/gnome/sources/gnome-doc-utils/0.20/gnome-doc-utils-0.20.10.tar.xz
LC_ALL=C sed -i.bak 's%/usr/bin/python%/usr/bin/env python%' xml2po/xml2po/xml2po.py.in

PKG_CONFIG_PATH=${BLDDEP}/lib/pkgconfig \
PYTHONPATH=$BLDDEP/lib/python${PYVERS}/site-packages/ \
PREFIX="${BLDDEP}" MAKEFLAGS="-j1" nativebuild --disable-scrollkeeper

src gtk-doc-1.21 tar.xz http://ftp.gnome.org/pub/GNOME/sources/gtk-doc/1.21/gtk-doc-1.21.tar.xz
PKG_CONFIG_PATH=${BLDDEP}/lib/pkgconfig \
PYTHONPATH=$BLDDEP/lib/python${PYVERS}/site-packages/ \
PREFIX="${BLDDEP}" nativebuild  --with-xml-catalog=$BLDDEP/etc/xml/catalog

################################################################################
# cross-compile
################################################################################

download jack_headers.tar.gz http://robin.linuxaudio.org/jack_headers.tar.gz
cd "$PREFIX"
tar xzf ${SRCDIR}/jack_headers.tar.gz
"$PREFIX"/update_pc_prefix.sh

src xz-5.2.2 tar.bz2 http://tukaani.org/xz/xz-5.2.2.tar.bz2
autoconfbuild

src zlib-1.2.7 tar.gz https://zlib.net/fossils/zlib-1.2.7.tar.gz
# src zlib-1.2.7 tar.gz ftp://ftp.simplesystems.org/pub/libpng/png/src/history/zlib/zlib-1.2.7.tar.gz
./configure --prefix=$PREFIX --archs="-arch arm64"
make $MAKEFLAGS
make install

src termcap-1.3.1 tar.gz http://ftpmirror.gnu.org/termcap/termcap-1.3.1.tar.gz
ed tparam.c << EOF
/STDC_HEADERS
.+1i
#include <unistd.h>
.
wq
EOF
ac_cv_header_stdc=yes autoconfconf
make install CFLAGS="-fPIC ${GLOBAL_CFLAGS}" oldincludedir=""

src readline-6.3 tar.gz http://ftpmirror.gnu.org/readline/readline-6.3.tar.gz
ac_cv_sys_tiocgwinsz_in_termios_h=no ac_cv_header_stdc=yes \
bash_cv_wcwidth_broken=yes \
MAKEFLAGS="SHLIB_LIBS=-ltermcap" \
autoconfbuild

src tiff-4.0.10 tar.gz http://download.osgeo.org/libtiff/tiff-4.0.10.tar.gz
CFLAGS="-DHAVE_APPLE_OPENGL_FRAMEWORK" \
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
autoconfbuild --disable-cpplibs --disable-asm-optimizations --disable-debug

src libsndfile-1.0.27 tar.gz http://www.mega-nerd.com/libsndfile/files/libsndfile-1.0.27.tar.gz
LC_ALL=C sed -i.bak 's/12292/24584/' src/common.h
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
AUTOMAKE_FLAGS="--gnu --add-missing --copy -f" ./autogen.sh --build=x86_64-apple-darwin --host=${XHOST}
autoconfbuild --disable-fftw --disable-sndfile

src expat-2.2.9 tar.xz https://github.com/libexpat/libexpat/releases/download/R_2_2_9/expat-2.2.9.tar.xz
autoconfbuild

src libiconv-1.16 tar.gz https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.16.tar.gz
gl_cv_cc_visibility=no \
autoconfbuild --with-included-gettext --with-libiconv-prefix=$PREFIX

src libxml2-2.9.2 tar.gz ftp://xmlsoft.org/libxslt/libxml2-2.9.2.tar.gz
CFLAGS=" -O0" CXXFLAGS=" -O0" \
autoconfbuild --with-threads=no --with-zlib=$PREFIX --without-python

src gettext-0.21 tar.gz http://ftp.gnu.org/pub/gnu/gettext/gettext-0.21.tar.gz
autoconfbuild --build=arm64 --disable-curses --disable-java --disable-csharp --disable-openmp --without-bzip2 --without-xz

src libxslt-1.1.33 tar.gz http://xmlsoft.org/sources/libxslt-1.1.33.tar.gz
autoconfbuild --without-python --with-libxml-prefix=$PREFIX

src libpng-1.6.37 tar.xz https://downloads.sourceforge.net/project/libpng/libpng16/1.6.37/libpng-1.6.37.tar.xz
autoconfbuild

src freetype-2.9 tar.gz http://download.savannah.gnu.org/releases/freetype/freetype-2.9.tar.gz
autoconfbuild -with-harfbuzz=no

src uuid-1.6.2 tar.gz http://www.mirrorservice.org/sites/ftp.ossp.org/pkg/lib/uuid/uuid-1.6.2.tar.gz
patch Makefile.in << EOF
115c115
< 	@\$(LIBTOOL) --mode=link \$(CC) -o \$(LIB_NAME) \$(LIB_OBJS) -rpath \$(libdir) \\
---
> 	@\$(LIBTOOL) --mode=link \$(CC) \$(LDFLAGS) -o \$(LIB_NAME) \$(LIB_OBJS) -rpath \$(libdir) \\
EOF
autoreconf && automake --add-missing --copy --force-missing || true
ac_cv_va_copy=yes autoconfbuild

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

src cairo-1.14.10 tar.xz http://cairographics.org/releases/cairo-1.14.10.tar.xz
patch -p1 < $this_script_dir/misc-patches/cairo-quartz-surface-ref.patch
ed Makefile.in << EOF
%s/ test perf//
wq
EOF
ax_cv_c_float_words_bigendian=no \
autoconfbuild --disable-gtk-doc-html --enable-gobject=no --disable-valgrind \
	--enable-interpreter=no --enable-script=no

src libffi-3.2.1 tar.gz ftp://sourceware.org/pub/libffi/libffi-3.2.1.tar.gz
autoconfbuild

src gettext-0.21 tar.gz http://ftp.gnu.org/pub/gnu/gettext/gettext-0.21.tar.gz
CFLAGS=" -O2" CXXFLAGS=" -O2" \
autoconfbuild --build=arm64 --with-included-gettext --with-libiconv-prefix=$PREFIX --disable-curses --disable-java --disable-csharp --disable-openmp

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
GLOBAL_LDFLAGS="$GLOBAL_LDFLAGS -lintl" \
autoconfbuild --with-pcre=internal --disable-silent-rules --with-libiconv=yes

src harfbuzz-2.6.2 tar.xz http://www.freedesktop.org/software/harfbuzz/release/harfbuzz-2.6.2.tar.xz
autoconfbuild

src pango-1.40.4 tar.xz http://ftp.gnome.org/pub/GNOME/sources/pango/1.40/pango-1.40.4.tar.xz
autoconfbuild --with-included-modules=yes --enable-introspection=no --disable-doc-cross-references

src atk-2.14.0 tar.bz2 http://ftp.gnome.org/pub/GNOME/sources/atk/2.14/atk-2.14.0.tar.xz
autoconfbuild --disable-rebuilds --enable-introspection=no

src gdk-pixbuf-2.31.1 tar.xz http://ftp.acc.umu.se/pub/GNOME/sources/gdk-pixbuf/2.31/gdk-pixbuf-2.31.1.tar.xz
autoconfbuild --disable-modules --without-gdiplus --with-included-loaders=yes --enable-gio-sniffing=no --enable-introspection=no

src gtk+-2.24.23 tar.bz http://ardour.org/files/deps/gtk+-2.24.23-quartz-ardour6.tar.bz2
aclocal
autoconf
automake --add-missing --copy --force-missing
libtoolize

#lt_cv_sys_global_symbol_pipe='sed -n -e '\''s/^.*[       ]\([BCDEGRST][BCDEGRST]*\)[     ][      ]*_\([_A-Za-z][_A-Za-z0-9]*\)$/\1 _\2 \2/p'\''' \
LDFLAGS="-L/usr/lib/$XPREFIX $LDFLAGS" \
autoconfconf --disable-rebuilds --enable-introspection=no --disable-cups --disable-papi --enable-relocation --with-gdktarget=quartz

ed gtk/gtkclipboard-quartz.c << EOF
26i
#include "gdk/quartz/gdkquartz.h"
.
wq
EOF
patch -p1 < $this_script_dir/current-gtk-patches/gdk-draw-combined.diff
LC_ALL=C sed -i.bak 's/ demos / /g' Makefile

make $MAKEFLAGS
make install

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
wafbuild --no-coverage

src suil-0.10.8 tar.bz2 http://ardour.org/files/deps/suil-0.10.8-g05c2afb.tar.bz2 -g05c2afb
wafbuild

src curl-7.66.0 tar.bz2 http://curl.haxx.se/download/curl-7.66.0.tar.bz2
autoconfbuild --without-ssl --with-darwinssl
rm -f $PREFIX/bin/curl

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
sh ./autogen.sh --build=x86_64-apple-darwin --host=${XHOST}
autoconfbuild

################################################################################
src taglib-1.9.1 tar.gz http://taglib.github.io/releases/taglib-1.9.1.tar.gz
LC_ALL=C sed -i.bak 's/\~ListPrivate/virtual ~ListPrivate/' taglib/toolkit/tlist.tcc
rm -rf build/
mkdir build && cd build
	cmake \
		-DCMAKE_INSTALL_PREFIX=$PREFIX -DCMAKE_RELEASE_TYPE=Release \
		-DCMAKE_C_FLAGS="$GLOBAL_CFLAGS -I${PREFIX}/include/" \
		-DCMAKE_CXX_FLAGS="$GLOBAL_CXXFLAGS -I${PREFIX}/include/" \
		-DCMAKE_LINKER_FLAGS="$GLOBAL_LDFLAGS -L ${PREFIX}/lib/" \
		 -DZLIB_ROOT="$PREFIX" \
		..
make $MAKEFLAGS
make install


################################################################################
#git://liblo.git.sourceforge.net/gitroot/liblo/liblo
src liblo-0.28 tar.gz http://downloads.sourceforge.net/liblo/liblo-0.28.tar.gz
CFLAGS=" -Wno-absolute-value" \
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
make $MAKEFLAGS
make install

################################################################################
src boost_1_68_0 tar.bz2 http://sourceforge.net/projects/boost/files/boost/1.68.0/boost_1_68_0.tar.bz2
./bootstrap.sh --prefix=$PREFIX --with-libraries=exception,atomic
LC_ALL=C sed -i.bak 's/4\.0\.0/0.0.0/' tools/build/src/tools/darwin.jam
LC_ALL=C sed -i.bak 's/arch arm/arch arm64/' tools/build/src/tools/darwin.jam
PATH=/usr/bin:$PATH ./b2 --prefix=$PREFIX \
	cflags="$GLOBAL_CFLAGS" cxxflags="$GLOBAL_CXXFLAGS" \
	variant=release \
	threading=multi \
	link=shared \
	runtime-link=shared \
	$MAKEFLAGS install || true

################################################################################
#download ladspa.h http://www.ladspa.org/ladspa_sdk/ladspa.h.txt
download ladspa.h http://community.ardour.org/files/ladspa.h
cp ${SRCDIR}/ladspa.h $PREFIX/include/ladspa.h
################################################################################

src vamp-plugin-sdk-2.8.0 tar.gz https://code.soundsoftware.ac.uk/attachments/download/2450/vamp-plugin-sdk-2.8.0.tar.gz
cp $this_script_dir/waf ./waf
cp $this_script_dir/vamp-wscript ./wscript
wafbuild

src rubberband-1.8.1 tar.bz2 http://code.breakfastquay.com/attachments/download/34/rubberband-1.8.1.tar.bz2
cp $this_script_dir/waf ./waf
cp $this_script_dir/rb-wscript ./wscript
wafbuild

ed $PREFIX/lib/pkgconfig/rubberband.pc << EOF
%s/ -lrubberband/ -lrubberband -lfftw3/
wq
EOF

src aubio-0.3.2 tar.gz http://aubio.org/pub/aubio-0.3.2.tar.gz
./bootstrap
LC_ALL=C sed -i.bak '/no-long-double/d' ./configure
ed Makefile.in << EOF
%s/examples / /
wq
EOF
ac_cv_path_SWIG=no \
autoconfbuild

ed $PREFIX/lib/pkgconfig/aubio.pc << EOF
%s/ -laubio/ -laubio -lfftw3f/
wq
EOF

################################################################################

src libwebsockets-4.0.15 tar.gz http://ardour.org/files/deps/libwebsockets-4.0.15.tar.gz
rm -rf build/
LC_ALL=C sed -i.bak 's%-Werror%%' CMakeLists.txt
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
	-DCMAKE_C_FLAGS="$GLOBAL_CFLAGS -isystem ${PREFIX}/include ${STACKCFLAGS}" \
	-DCMAKE_SHARED_LINKER_FLAGS="$GLOBAL_LDFLAGS"  \
	-DLWS_WITHOUT_TEST_SERVER=on -DLWS_WITHOUT_TESTAPPS=on \
	-DCMAKE_INSTALL_PREFIX=$PREFIX \
	-DCMAKE_PREFIX_PATH=$PREFIX \
	-DCMAKE_LIBRARY_PREFIX=$PREFIX \
	-DCMAKE_BUILD_TYPE=Release \
	..
make $MAKEFLAGS && make install

################################################################################
src libusb-1.0.20 tar.bz2 http://downloads.sourceforge.net/project/libusb/libusb-1.0/libusb-1.0.20/libusb-1.0.20.tar.bz2
MAKEFLAGS= \
autoconfbuild --disable-udev


################################################################################
# fix-up circular dependency.
install_name_tool -change /usr/lib/libiconv.2.dylib $PREFIX/lib/libiconv.2.dylib $PREFIX/lib/libxslt.1.dylib
install_name_tool -change /usr/lib/libiconv.2.dylib $PREFIX/lib/libiconv.2.dylib $PREFIX/lib/libexslt.0.dylib
install_name_tool -change /usr/lib/libiconv.2.dylib $PREFIX/lib/libiconv.2.dylib $PREFIX/lib/libxml2.2.dylib
install_name_tool -change /usr/lib/libiconv.2.dylib $PREFIX/lib/libiconv.2.dylib $PREFIX/lib/liblrdf.2.dylib

################################################################################
echo "*** STACK COMPLETE"

cd $this_script_dir
git log -n 1 --pretty="format:%H" -- x-applearm.sh > ${PREFIX}/../.vers

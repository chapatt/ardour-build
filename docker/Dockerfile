FROM debian:10

LABEL maintainer="Ahmed Zetao Yang <vitzys@outlook.com>" \
      name="Docker Ardour Build Environment" \
      description="Docker container for ardour build environment, with almost everything that you may need." \
      url="" \
      vcs-url="" \
      vendor="Ahmed Zetao Yang" \
      version="1.0"

# Fix missing locales
ENV LANGUAGE=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8

# Skip interactive post-install scripts
ENV DEBIAN_FRONTEND=noninteractive

# Don't install recommends && using mirror source
RUN echo 'apt::install-recommends "false";' > /etc/apt/apt.conf.d/00recommends \
   && sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list; \
   sed -i 's|security.debian.org/debian-security|mirrors.tuna.tsinghua.edu.cn/debian-security|g' /etc/apt/sources.list;

RUN apt-get update && apt-get install -y --force-yes \
    apt-transport-https \
    curl \
    wget \
    gnupg \
    ca-certificates

# Install base toolset
RUN apt-get update && apt-get install -y --force-yes \
    sudo \
    git \
    build-essential \
    cmake \
    autoconf \
    automake \
    gdb \
    ccache \
    devscripts \
    debhelper \
    cdbs \
    fakeroot \
    lintian \
    equivs \
    rpm \
    alien \
    dh-systemd \
    python \
    gcc-mingw-w64 \
    g++-mingw-w64 \
    gcc-mingw-w64-x86-64 \
    g++-mingw-w64-x86-64 \
    mingw-w64 \
    yasm \
    gnome-common \
    gnome-doc-utils \
    gettext \
    intltool \
    itstool \
    dos2unix \
    chrpath \
    rsync \
    unzip \
    libboost-all-dev \
    libglib2.0-dev \
    libglibmm-2.4-dev \
    libsndfile1-dev \
    libcurl4-gnutls-dev \
    libarchive-dev \
    liblo-dev \
    libtag1-dev \
    vamp-plugin-sdk \
    librubberband-dev \
    libasound2-dev  \
    libfftw3-dev \
    libaubio-dev \
    libpulse-dev \
    libudev-dev \
    libxml2-dev \
    libjack-dev \
    libcppunit-dev \
    libusb-1.0-0-dev \
    libwebsockets-dev \
    liblrdf0-dev \
    libpangomm-1.4-dev \
    libcwiid-dev \
    libsamplerate0-dev \
    lv2-dev \
    libsord-dev \
    libserd-dev \
    libsratom-dev \
    liblilv-dev \
    libgtkmm-2.4-dev \
    libsuil-dev \
    libsigc++-2.0-dev \
    libatk1.0-dev \
    libatkmm-1.6-dev \
    libbison-dev \
    libcairo2-dev \
    libcairomm-1.0-dev  \
    libexpat1-dev \
    libflac-dev \
    libfl-dev \
    fontconfig \
    libfontconfig1 \
    libfontconfig1-dev \
    libfreetype6 \
    libfreetype6-dev \
    libgdk-pixbuf2.0 \
    libgdk-pixbuf2.0-dev \
    libglib2.0 \
    libglib2.0-dev \
    libglibmm-2.4 \
    libglibmm-2.4-dev \
    gobject-introspection \
    libgirepository-1.0 \
    libgirepository1.0-dev \
    gtk-doc-tools \
    gtk2-engines \
    libgtk2.0-0 \
    libgtk2.0-dev \
    libgtk2.0-common \
    libgtkmm-2.4 \
    libgtkmm-2.4-dev \
    libharfbuzz0b \
    libharfbuzz-dev \
    libharfbuzz-gobject0

# Enable sudo without password
RUN echo '%adm ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

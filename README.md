# Ardour build for Linux

## Note

1. waf configure without `--freebie`
2. to run Ardour, you may need install `libxcb-render0` and `libxcb-shm0` if you use Ubuntu.

## Steps

From here on, we will refer to the directory where your Ardour source code is located as `$AD`. It does not matter where it is located on your system. Typically it will be a location such as `~/ardour` or maybe `/usr/local/src/ardour`

#### If building from git, checkout Ardour

```bash
cd $AD
git clone git://git.ardour.org/ardour/ardour.git <VERSION>
cd $AD/<VERSION>
```

#### OR If building from a source tarball, unpack it

```bash
cd $AD
tar xf /where/you/put/the/src/tarball
cd ardour-<VERSION>
```

Now, the build

```bash
./waf configure --strict --prefix=/usr --configdir=/etc --libjack=weak --ptformat --with-backends=jack,alsa,pulseaudio,dummy --optimize --cxx11 --freedesktop
./waf -j$(nproc)
./waf i18n
```

You **do not need to install** in order to use your new build of Ardour. You can run it from within the build tree:

```bash
cd gtk2_ardour
./ardev
```

To install the results:

```bash
./waf install
```

To uninstall:

```bash
./waf uninstall
```

To clean up results of a build (objects, libraries, etc) use

```bash
./waf clean
```

### Creating an Application Bundle

Ardour is distributed by ardour.org in the form of "bundles", which are nothing more than a directory tree which contain everything the app needs to run.

```bash
cd tools/linux_packaging
./build --public --harvid
./package --public --singlearch --makeself
```

You now have a functioning binary bundle, in the form a .run file.

### Flatpak

Besides, for Linux users there is another way to use Ardour, that is [flatpak]( https://flathub.org/apps/details/org.ardour.Ardour), [github](https://github.com/flathub/org.ardour.Ardour).


### reference

- [Building Ardour on Linux](https://ardour.org/building_linux.html)
- [Linux 64bit log](https://nightly.ardour.org/i/A_Linux_x86_64/build_log.txt)
- [Official nightly build](https://nightly.ardour.org/list.php)
- [Makeself](https://makeself.io): A self-extracting archiving tool for Unix systems, in 100% shell script.


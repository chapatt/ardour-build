# Ardour build for MacOS

## Note

waf configure without `--freebie`

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
tar xf /where/you/put/the/source/tarball
cd ardour-<VERSION>
```

Now, the build

```bash
./waf configure --strict --with-backends=jack,coreaudio,dummy --ptformat --optimize
./waf -j$(sysctl -n hw.logicalcpu)
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

### Creating An Application Bundle

Applications on OS X take the form of "bundles", which are nothing more than a directory tree which contain everything the app needs to run.

```bash
cd tools/osx_packaging
./osx_build --nls --public
```

You now have a functioning .dmg bundle.

### reference

- [Building Ardour on OS X](https://ardour.org/building_osx_native.html)
- [OSX x86_64 log](https://nightly.ardour.org/i/A_OSX_x86_64/build_log.txt)
- [Build Dependencies](https://nightly.ardour.org/list.php#Build%20Dependencies)
- [Official nightly build](https://nightly.ardour.org/list.php)
- [Waf: The meta build system](https://waf.io)


# ardour linux build

### build image

```
git clone -b master https://github.com/ZetaoYang/ardour-build
cd docker
docker build -t vitzy/debian:10 .
```

### run container

```
docker run -it -d --name ardour vitzy/debian:10
```

### compile

```
docker exec -it ardour /bin/bash

git clone https://github.com/Ardour/ardour
cd ardour
./waf configure
./waf
      
```

## bundle

```
cd tools/linux_packaging
./build --public --strip some
./package --public --singlearch
```



### reference

- [Building Ardour on Linux](https://ardour.org/building_linux.html)
- [Build Dependencies](https://nightly.ardour.org/list.php#Build%20Dependencies)
- [Official nightly build](https://nightly.ardour.org/list.php)
- [Waf: The meta build system](https://waf.io)
- [Ardour Development](https://ardour.org/development.html)
- Another linux build on docker: https://github.com/garyritchie/ardour-build


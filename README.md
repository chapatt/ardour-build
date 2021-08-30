<div align="center">
  <p>
    <h1>
      <a href="https://github.com/ZetaoYang/ardour-build">
      </a>
      <br />
      Ardour Unofficial Builds
    </h1>
    <h4>Github Actions Build of Ardour for Linux, MacOS and Windows.</h4>
  </p>
  <p>
    <a href="https://github.com/ZetaoYang/ardour-build/actions?query=workflow%3AArdour%20Build%20for%20Linux">
      <img src="https://img.shields.io/github/workflow/status/ZetaoYang/ardour-build/Ardour%20Build%20for%20Linux?label=GNU%2FLinux" alt="GNU/Linux Build Status" />
    </a>
    <a href="https://github.com/ZetaoYang/ardour-build/actions?query=workflow%3AArdour%20Build%20for%20MacOS">
      <img src="https://img.shields.io/github/workflow/status/ZetaoYang/ardour-build/Ardour%20Build%20for%20MacOS?label=MacOS" alt="MacOS Build Status" />
    </a>
    <a href="https://github.com/ZetaoYang/ardour-build/actions?query=workflow%3AArdour%20Cross%20Compile%20Build%20for%20Windows">
      <img src="https://img.shields.io/github/workflow/status/ZetaoYang/ardour-build/Ardour%20Cross%20Compile%20Build%20for%20Windows?label=Windows" alt="Windows Build Status" />
    </a>
    <a href="https://github.com/ZetaoYang/ardour-build/releases">
      <img src="https://img.shields.io/github/downloads/ZetaoYang/ardour-build/total.svg?style=flat-square" alt="Total Downloads" />
    </a>
  </p>
</div>

## Packages

Now pre-built packages are available on:

- Linux x86_64
- MacOS Intel x86_64
- Windows x86, x86_64

The builds are on three separate branches: [linux](https://github.com/ZetaoYang/ardour-build/tree/linux), [macos](https://github.com/ZetaoYang/ardour-build/tree/macos) and [win](https://github.com/ZetaoYang/ardour-build/tree/win).

## Build

The action is triggered by [workflows push paths event](https://help.github.com/en/actions/reference/workflow-syntax-for-github-actions#onpushpull_requestpaths) or [the repo's dispatch event](https://developer.github.com/v3/repos/#create-a-repository-dispatch-event).

for example, trigger building via dispatch event

Get your own [personal access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line).

`POST /repos/:owner/:repo/dispatches`

Trigger with curl command, example,
```
curl -H "Accept: application/Accept: application/vnd.github.v3.full+json" \
-H "Authorization: token your-personal-token" \
--request POST \
--data '{"event_type": "ardour-linux-build"}' \
https://api.github.com/repos/ZetaoYang/ardour-build/dispatches
```

or

```
curl -H "Accept: application/Accept: application/vnd.github.v3.full+json" \
-H "Authorization: token your-personal-token" \
--request POST \
--data '{"event_type": "ardour-macos-build"}' \
https://api.github.com/repos/ZetaoYang/ardour-build/dispatches
```

or

```
curl -H "Accept: application/Accept: application/vnd.github.v3.full+json" \
-H "Authorization: token your-personal-token" \
--request POST \
--data '{"event_type": "ardour-win-build", "client_payload": { "version": "0.33.0"}}' \
https://api.github.com/repos/ZetaoYang/ardour-build/dispatches
```


## Links

- [Building Ardour on Linux](https://ardour.org/building_linux.html)
- [Building Ardour on MacOS](https://ardour.org/building_osx_native.html)
- [Build Dependencies](https://nightly.ardour.org/list.php#Build%20Dependencies)
- [Official nightly build](https://nightly.ardour.org/list.php)
- [Waf: The meta build system](https://waf.io)
- [Interfacing Linux: Compiling Ardour 6 On Debian 10](https://linuxgamecast.com/2020/06/interfacing-linux-compiling-ardour-6-on-debian)
- [Ardour Flatpak json](https://github.com/flathub/org.ardour.Ardour/blob/master/org.ardour.Ardour.json)
- [Ardour PKGBUILD](https://github.com/archlinux/svntogit-community/blob/packages/ardour/trunk/PKGBUILD)
- Another try, MSYS2 compile win64: 
	* https://github.com/defcronyke/ardour  
	* http://lalists.stanford.edu/lau/2016/10/0006.html   
	* https://github.com/Ardour/ardour/pull/278/files
-  [450+ pages Ardour 6 Manual PDF on github](https://github.com/derwok/manual/releases)

## Acknowledgement

- Thanks to the [Ardour development](https://ardour.org/development.html) team for their effort.
- This project ["A Docker based build environment for cross compiling Ardour for windows using the official build infrastructure."](https://gitlab.com/mojofunk/ardour-ci-docker-jessie-mingw)  gave me a hint. It use official build scripts and patches, that is `git://git.ardour.org/ardour/ardour-build-tools.git`. This project also uses those scripts, but with a few changes.


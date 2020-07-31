# ardour cross compile on debian for win

### Purpose

This project is just an exploratory cross-compilation of ardour windows binary on debian buster.

### Issues

The compilation succeeds, but the program does not run properly. The error message is as follows,

```
strace.exe .\bin\Ardour.exe
 
...

(Ardour.exe:10160): Pango-WARNING **: 10:33:26.223: Invalid UTF-8 string passed to pango_layout_set_text()

(Ardour.exe:10160): Pango-WARNING **: 10:33:26.236: Invalid UTF-8 string passed to pango_layout_set_text()

(Ardour.exe:10160): Pango-WARNING **: 10:33:26.237: Invalid UTF-8 string passed to pango_layout_set_text()

(Ardour.exe:10160): Pango-WARNING **: 10:33:26.238: Invalid UTF-8 string passed to pango_layout_set_text()

(Ardour.exe:10160): Pango-WARNING **: 10:33:26.239: Invalid UTF-8 string passed to pango_layout_set_text()

(Ardour.exe:10160): Pango-WARNING **: 10:33:26.239: Invalid UTF-8 string passed to pango_layout_set_text()

(Ardour.exe:10160): Pango-WARNING **: 10:33:26.241: Invalid UTF-8 string passed to pango_layout_set_text()

(Ardour.exe:10160): Pango-WARNING **: 10:33:26.241: Invalid UTF-8 string passed to pango_layout_set_text()

(Ardour.exe:10160): Pango-WARNING **: 10:33:26.244: Invalid UTF-8 string passed to pango_layout_set_text()

(Ardour.exe:10160): Pango-WARNING **: 10:33:26.244: Invalid UTF-8 string passed to pango_layout_set_text()

(Ardour.exe:10160): Pango-WARNING **: 10:33:26.246: Invalid UTF-8 string passed to pango_layout_set_text()

(Ardour.exe:10160): Pango-WARNING **: 10:33:26.248: Invalid UTF-8 string passed to pango_layout_set_text()

(Ardour.exe:10160): Pango-WARNING **: 10:33:26.250: Invalid UTF-8 string passed to pango_layout_set_text()

(Ardour.exe:10160): Pango-WARNING **: 10:33:26.251: Invalid UTF-8 string passed to pango_layout_set_text()

(Ardour.exe:10160): Pango-WARNING **: 10:33:26.255: Invalid UTF-8 string passed to pango_layout_set_text()

(Ardour.exe:10160): Pango-WARNING **: 10:33:26.258: Invalid UTF-8 string passed to pango_layout_set_text()

(Ardour.exe:10160): Pango-WARNING **: 10:33:26.262: Invalid UTF-8 string passed to pango_layout_set_text()

(Ardour.exe:10160): Pango-WARNING **: 10:33:26.268: Invalid UTF-8 string passed to pango_layout_set_text()

(Ardour.exe:10160): Pango-WARNING **: 10:33:26.303: Invalid UTF-8 string passed to pango_layout_set_text()

(Ardour.exe:10160): Pango-WARNING **: 10:33:26.615: Invalid UTF-8 string passed to pango_layout_set_text()
--- Process 10160, exception 20474343 at 00007fffaf3d3e49
--- Process 10160, exception 21474343 at 00007fffaf3d3e49
--- Process 10160, exception 20474343 at 00007fffaf3d3e49
terminate called after throwing an instance of 'failed_constructor'
--- Process 10160, exception 20474343 at 00007fffaf3d3e49
  what():  failed constructor
--- Process 10160 thread 19024 exited with status 0x3
--- Process 10160 thread 1256 exited with status 0x3
--- Process 10160 thread 15084 exited with status 0x3
--- Process 10160 thread 15116 exited with status 0x3
--- Process 10160 thread 9060 exited with status 0x3
--- Process 10160 thread 14076 exited with status 0x3
--- Process 10160 thread 19380 exited with status 0x3
--- Process 10160 thread 1228 exited with status 0x3
--- Process 10160 thread 19336 exited with status 0x3
--- Process 10160 thread 9656 exited with status 0x3
--- Process 10160 thread 18960 exited with status 0x3
--- Process 10160 thread 19184 exited with status 0x3
--- Process 10160 thread 2028 exited with status 0x3
--- Process 10160 thread 17872 exited with status 0x3
--- Process 10160 exited with status 0x3
```

### Good news

There's a project ["A Docker based build environment for cross compiling Ardour for windows using the official build infrastructure."](https://gitlab.com/mojofunk/ardour-ci-docker-jessie-mingw) , it use  official build tools, e.g. git.ardour.org/ardour/ardour-build-tools/win/x-mingw.sh

### Bad news

Cannot access git.ardour.org/ardour/ardour-build-tools/win/x-mingw.sh unless you have ardour gitlab account.


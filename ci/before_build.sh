#!/bin/bash

mkdir -p /var/tmp/winsrc

echo 1 | update-alternatives --config x86_64-w64-mingw32-gcc
echo 1 | update-alternatives --config x86_64-w64-mingw32-g++
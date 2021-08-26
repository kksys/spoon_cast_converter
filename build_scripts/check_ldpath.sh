#!/bin/bash

cd modules/ffmpeg/dist/mac/lib

for dylib in $(ls | grep dylib); do
    otool -arch x86_64 -L "./${dylib}"
    otool -arch arm64 -L "./${dylib}"
done

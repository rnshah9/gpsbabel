#!/bin/bash -ex
#
# this script is triggered by SCM changes and is run on the build server.
# output is conditionally mailed to gpsbabel-code.
#

# echo some system info to log
uname -a
if [ -e /etc/system-release ]; then
	cat /etc/system-release
fi
if [ -e /etc/os-release ]; then
	cat /etc/os-release
fi
git --no-pager log -n 1

# build and test keeping output within the pwd.
export GBTEMP=$(mktemp -d -p $(pwd) GBTEMPXXXX)

#note that debug will also enable assertions.
qmake "CONFIG+=debug sanitizer sanitize_address"
make clean
make -j 3
make check

qmake "CONFIG+=debug sanitizer sanitize_undefined"
make clean
make -j 3
make check

# run clazy on both gpsbabel and gpsbabelfe.
# unlike qmake, cmake uses system includes for Qt which quiets warnings
# from the Qt headers.
export CLAZY_CHECKS=level0,level1,no-non-pod-global-static,no-qstring-ref
cmake . -DCMAKE_CXX_COMPILER=clazy -G "Ninja" -DCMAKE_BUILD_TYPE:STRING="Debug"
cmake --build . --target clean
cmake --build . 2>&1 | tee clazy.log
if grep -- '-Wclazy' clazy.log; then
  exit 1
else
  exit 0
fi


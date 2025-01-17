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
export GBTEMP=$(pwd)/gbtemp
mkdir -p "$GBTEMP"
cmake . -G Ninja -DCMAKE_BUILD_TYPE=Release -DWEB="$(pwd)/gpsbabel_docdir"
# As of 2018-10, all the virtualized travis build images are two cores per:
# https://docs.travis-ci.com/user/reference/overview/
# We'll be slightly abusive on CPU knowing that I/O is virtualized.
#make toolinfo
cmake --build . --target clean
cmake --build . --target gpsbabel
cmake --build . --target gpsbabel.html
cmake --build . --target gpsbabel.pdf
cmake --build . --target gpsbabel.org
cmake --build . --target check
cmake --build . --target gpsbabelfe
# test for mangled encoding of command line arguments
./test_encoding_latin1
./test_encoding_utf8
#make torture
cmake --build . --target check-vtesto
# eat the verbose output from test-all, including crash.output
# this is a bit risky, if test-all generates an error we won't see what happened.
echo "test-all in progress... (read/write test between all possible formats)"
(LIBC_FATAL_STDERR_=1; export LIBC_FATAL_STDERR_; ./test-all -s -r reference/expertgps.gpx >/dev/null 2>&1)
# summarize the test-all results, and generate an error if a fatal error was
# detected by test-all.
./test-all -J

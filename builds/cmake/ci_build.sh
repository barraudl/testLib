#!/usr/bin/env bash
set -e

# Set this to enable verbose profiling
[ -n "${CI_TIME-}" ] || CI_TIME=""
case "$CI_TIME" in
    [Yy][Ee][Ss]|[Oo][Nn]|[Tt][Rr][Uu][Ee])
        CI_TIME="time -p " ;;
    [Nn][Oo]|[Oo][Ff][Ff]|[Ff][Aa][Ll][Ss][Ee])
        CI_TIME="" ;;
esac

# Set this to enable verbose tracing
[ -n "${CI_TRACE-}" ] || CI_TRACE="no"
case "$CI_TRACE" in
    [Nn][Oo]|[Oo][Ff][Ff]|[Ff][Aa][Ll][Ss][Ee])
        set +x ;;
    [Yy][Ee][Ss]|[Oo][Nn]|[Tt][Rr][Uu][Ee])
        set -x ;;
esac

LANG=C
LC_ALL=C
export LANG LC_ALL

if [ -d "./tmp" ]; then
    rm -rf ./tmp
fi
mkdir -p tmp
BUILD_PREFIX=$PWD/tmp

CONFIG_OPTS=()
CONFIG_OPTS+=("CFLAGS=-I${BUILD_PREFIX}/include")
CONFIG_OPTS+=("CPPFLAGS=-I${BUILD_PREFIX}/include")
CONFIG_OPTS+=("CXXFLAGS=-I${BUILD_PREFIX}/include")
CONFIG_OPTS+=("LDFLAGS=-L${BUILD_PREFIX}/lib")
CONFIG_OPTS+=("PKG_CONFIG_PATH=${BUILD_PREFIX}/lib/pkgconfig")
CONFIG_OPTS+=("--prefix=${BUILD_PREFIX}")
CONFIG_OPTS+=("--with-docs=no")
if [ -z "${CI_CONFIG_QUIET-}" ] || [ "${CI_CONFIG_QUIET-}" = yes ] || [ "${CI_CONFIG_QUIET-}" = true ]; then
    CONFIG_OPTS+=("--quiet")
fi

CMAKE_OPTS=()
CMAKE_OPTS+=("-DCMAKE_INSTALL_PREFIX:PATH=${BUILD_PREFIX}")
CMAKE_OPTS+=("-DCMAKE_PREFIX_PATH:PATH=${BUILD_PREFIX}")
CMAKE_OPTS+=("-DCMAKE_LIBRARY_PATH:PATH=${BUILD_PREFIX}/lib")
CMAKE_OPTS+=("-DCMAKE_INCLUDE_PATH:PATH=${BUILD_PREFIX}/include")

# Clone and build dependencies
[ -z "$CI_TIME" ] || echo "`date`: Starting build of dependencies (if any)..."

# Build and check this project
cd ../..
[ -z "$CI_TIME" ] || echo "`date`: Starting build of currently tested project..."
CCACHE_BASEDIR=${PWD}
export CCACHE_BASEDIR
PKG_CONFIG_PATH=${BUILD_PREFIX}/lib/pkgconfig $CI_TIME cmake "${CMAKE_OPTS[@]}" .
$CI_TIME make all VERBOSE=1 -j4
$CI_TIME ctest -V
$CI_TIME make install
[ -z "$CI_TIME" ] || echo "`date`: Builds completed without fatal errors!"

echo "=== Are GitIgnores good after making the project '$BUILD_TYPE'? (should have no output below)"
git status -s || true
echo "==="

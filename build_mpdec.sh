#!/bin/bash
set -e
set -x

tarball="mpdecimal-2.4.2.tar.gz"
dest="${tarball%%.tar.gz}"
url="http://www.bytereef.org/software/mpdecimal/releases/${tarball}"
prefix="/usr"

function pre()
{
    curl -LO "${url}"
    tar xf "${tarball}"
}

function build()
{
    pre
    pushd "${dest}"
        export LDFLAGS="-Wl,-rpath=$prefix/lib"
        ./configure --prefix=$prefix
        make
        make install
    popd
    post
}

function post()
{
    rm -rf "${dest}"
    rm -rf "${tarball}"
    echo "All done."
}

# Main
build

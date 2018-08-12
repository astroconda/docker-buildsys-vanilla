#!/bin/bash
set -e
set -x
tarball="openssl-1.1.0h.tar.gz"
dest="${tarball%%.tar.gz}"
url="https://www.openssl.org/source/${tarball}"
prefix="/opt/openssl"


function pre()
{
    curl -LO "${url}"
    tar xf "${tarball}"
    export KERNEL_BITS=64
}


function get_system_cacert() {
  local paths=(
    /etc/ssl/cert.pem
    /etc/ssl/cacert.pem
    /etc/ssl/certs/cacert.pem
    /etc/ssl/certs/ca-bundle.crt
  )
  for bundle in "${paths[@]}"
  do
    if [[ -f $bundle ]]; then
        echo "$bundle"
        break
    fi
  done
}


function build()
{
    pre
    pushd "${dest}"
        target="linux-x86_64"
        export PATH="$prefix/bin:$PATH"
        export LDFLAGS="-Wl,-rpath=$prefix/lib"

        ./Configure \
            --prefix="$prefix" \
            --openssldir="ssl" \
            --libdir="lib" \
            ${LDFLAGS} \
            ${target} \
            enable-ec_nistp_64_gcc_128 \
            zlib-dynamic \
            shared \
            no-ssl3-method
        make
        make install MANDIR="$prefix/share/man" MANSUFFIX=ssl
    popd
    post
}

function post()
{
    bundle=$(get_system_cacert)
    install -D -m644 "$bundle" "$prefix/ssl/cert.pem"
    find $prefix
    echo "All done."
}

# Main
build

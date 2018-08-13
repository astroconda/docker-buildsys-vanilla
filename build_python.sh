#!/bin/bash
#https://www.python.org/ftp/python/3.7.0/Python-3.7.0.tar.gz

set -e
set -x

python_version="$1"
python_basever="${python_version%.*}"

if [[ ! ${python_version} || ! ${python_basever} ]]; then
    echo "Need a python version..."
    exit 1
fi

python_base_url="https://www.python.org/ftp/python"
python_tarball="Python-${python_version}.tgz"
python_source="${python_tarball%%.tgz}"
python_url="${python_base_url}/${python_version}/${python_tarball}"
prefix="/opt/${python_basever}"
openssl_root="/opt/openssl"

dep_table=(
    "bzlib.h libbz2.so"
    "expat.h libexpat.so"
    "ffi.h libffi.so"
    "gdbm.h libgdbm.so"
    "lzma.h liblzma.so"
    "mpdecimal.h libmpdec.so"
    "ncurses.h libncurses.so"
    "nislib.h libnsl.so"
    "readline.h libreadline.so"
    "ssl.h libssl.so"
    "sqlite3.h libsqlite3.so"
    "tcl.h libtcl.so"
    "tk.h libtk.so"
    "zlib.h libz.so"
)


function depcheck()
{
    dep_count=0
    dep_total="${#dep_table[@]}"

    set +x
    for _record in "${dep_table[@]}"
    do
        unset record
        read -ra record <<< $_record

        header=$(find /usr/include $openssl_root /usr/lib{,64} -regex ".*\/${record[0]}" 2>/dev/null | head -n 1 || true)
        if [[ -n $header ]]; then
            dep_count=$((dep_count+1))
        else
            echo "Missing header: ${record[0]}"
        fi
        lib=$(find $openssl_root /usr/lib{,64} -regex ".*\/${record[1]}" 2>/dev/null | head -n 1 || true)
        if [[ -n "$lib" ]]; then
            dep_count=$((dep_count+1))
        else
            echo "Missing library: ${record[1]}"
        fi
    done
    set -x

    if [[ ${dep_count} != $(( (dep_total * 2) )) ]]; then
        echo 'Missing dependencies...'
        exit 1
    fi
}


function pre()
{
    export PATH=$openssl_root/bin:$PATH
    export PKG_CONFIG_PATH=$openssl_root/lib/pkgconfig:$PKG_CONFIG_PATH
    export CFLAGS="-I$openssl_root/include"
    export LDFLAGS="-L$openssl_root/lib -Wl,-rpath=$prefix/lib:$openssl_root/lib"

    depcheck

    if [[ ! -f ${python_tarball} ]]; then
        curl -LO "${python_url}"
    fi

    if [[ -d ${python_source} ]]; then
        rm -rf "${python_source}"
    fi

    tar xf "${python_tarball}"
}


function build()
{
    pre
    pushd "${python_source}"
        ./configure \
            --prefix="$prefix" \
            --enable-ipv6 \
            --enable-loadable-sqlite-extensions \
            --enable-profiling \
            --enable-shared \
            --with-dbmliborder=gdbm:ndbm \
            --with-openssl="$openssl_root" \
            --with-pymalloc \
            --with-system-expat \
            --with-system-ffi \
            --with-threads
        make -j4
        make install
    popd
    post
}


function post()
{
    export PATH=$prefix/bin:$PATH
    ln -sf python3                   "${prefix}"/bin/python
    ln -sf python3-config            "${prefix}"/bin/python-config
    ln -sf idle3                     "${prefix}"/bin/idle
    ln -sf pydoc3                    "${prefix}"/bin/pydoc
    ln -sf pip3                      "${prefix}"/bin/pip
    ln -sf python${python_basever}.1 "${prefix}"/share/man/man1/python.1

    $prefix/bin/pip install --upgrade pip
    $prefix/bin/pip install --upgrade setuptools
    $prefix/bin/pip install wheel

    echo '---'
    python --version
    python -c "import sys; from pprint import pprint; pprint(sys.path)"

    rm -rf $HOME/.config/pip
    rm -rf "${python_tarball}"
    rm -rf "${python_source}"
    echo "All done."
}


# Main
build

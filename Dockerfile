FROM centos:6
LABEL maintainer="jhunk@stsci.edu" \
      vendor="Space Telescope Science Institute"

RUN yum install -y epel-release \
    && yum clean all

RUN yum install -y \
	gcc \
	gcc-c++ \
	gcc-gfortran \
	glibc \
	perl \
        pkgconfig \
	expat-devel \
	bzip2-devel \
	gdbm-devel \
	libffi-devel \
	ncurses-devel \
	openssl-devel \
	readline-devel \
	sqlite-devel \
	tcl-devel \
	tk-devel \
	xz-devel \
	zlib-devel \
    && yum clean all

COPY build_*.sh /usr/local/bin/
ENV PATH="/opt/openssl/bin:${PATH}"
ENV MANPATH="/opt/openssl/share/man:${MANPATH}"
ENV PKG_CONFIG_PATH="/opt/openssl/lib/pkgconfig:/usr/lib/pkgconfig:${PKG_CONFIG_PATH}"

WORKDIR /builder
RUN build_openssl.sh
RUN build_mpdec.sh
RUN build_python.sh 3.5.5
RUN build_python.sh 3.6.6
RUN build_python.sh 3.7.0
RUN rm -rf /builder

WORKDIR /root

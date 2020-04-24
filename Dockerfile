FROM debian:buster-slim

ARG RUST_VER=1.42.0

RUN apt update -y -q \
 && apt upgrade -y -q \
 && apt install -y -q \
   autoconf \
   automake \
   cmake \
   gcc \
   make \
   autotools-dev \
   curl \
   mingw-w64 \
   mingw-w64-tools \
   gcc-mingw-w64 \
   binutils-mingw-w64 \
   clang \
   llvm \
   git \
   libxml2-dev \
   libssl-dev \
   liblzma-dev \
   zlib1g-dev \
   sqlite3 \
   libsqlite3-0 \
   libsqlite3-dev \
   libzip-dev

#Build arguments
ARG osxcross_repo="tpoechtrager/osxcross"
ARG osxcross_revision="e0a171828a72a0d7ad4409489033536590008ebf"
ARG sdk_version="10.13"

RUN mkdir -p "/tmp/osxcross" \
 && cd "/tmp/osxcross" \
 && curl -sLo osxcross.tar.gz "https://codeload.github.com/${osxcross_repo}/tar.gz/${osxcross_revision}" \
 && tar --strip=1 -xzf osxcross.tar.gz \
 && rm -f osxcross.tar.gz

COPY MacOSX10.13.sdk.tar.xz /tmp/osxcross/tarballs/

RUN  cd "/tmp/osxcross" \
 && UNATTENDED=1 ./build.sh \
 && mv target /usr/osxcross \
 && mv tools /usr/osxcross/ \
 && rm -rf /tmp/osxcross \
 && rm -rf "/usr/osxcross/SDK/MacOSX${sdk_version}.sdk/usr/share/man"

RUN useradd -ms /bin/bash rust

USER rust
WORKDIR /home/rust

RUN curl https://sh.rustup.rs -sSf -o rustup.sh && \
        sh ./rustup.sh -y && \
        rm rustup.sh

ENV PATH $PATH:/home/rust/.cargo/bin:/usr/osxcross/bin
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/osxcross/lib

RUN rustup default $RUST_VER
RUN rustup target add x86_64-pc-windows-gnu
RUN rustup target add x86_64-apple-darwin
RUN rustup component add clippy
RUN cargo install cargo-outdated
RUN cargo install cargo-audit
RUN cargo install cargo-web
RUN cargo install diesel_cli --no-default-features --features sqlite

RUN cp /usr/x86_64-w64-mingw32/lib/*crt2.o \
        /home/rust/.rustup/toolchains/${RUST_VER}-x86_64-unknown-linux-gnu/lib/rustlib/x86_64-pc-windows-gnu/lib/

ADD mac-cargo /usr/local/bin/
ADD mac-c++ /usr/local/bin/
ADD mac-cc /usr/local/bin/
ADD win-cargo /usr/local/bin/
ADD win-cc /usr/local/bin

WORKDIR /workdir

CMD ["cargo", "build", "--release"]

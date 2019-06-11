FROM debian:buster-slim

ARG RUST_VER=1.35.0

RUN apt update \
        && apt install -y -q \
                autoconf \
                automake \
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
                git

#Build arguments
ARG osxcross_repo="tpoechtrager/osxcross"
ARG osxcross_revision="a845375e028d29b447439b0c65dea4a9b4d2b2f6"
ARG darwin_sdk_version="10.11"
ARG darwin_osx_version_min="10.7"
ARG darwin_version="15"
ARG darwin_sdk_url="https://github.com/phracker/MacOSX-SDKs/releases/download/10.13/MacOSX10.11.sdk.tar.xz"

# ENV available in docker image
ENV OSXCROSS_REPO="${osxcross_repo}"                   \
    OSXCROSS_REVISION="${osxcross_revision}"           \
    DARWIN_SDK_VERSION="${darwin_sdk_version}"         \
    DARWIN_VERSION="${darwin_version}"                 \
    DARWIN_OSX_VERSION_MIN="${darwin_osx_version_min}" \
    DARWIN_SDK_URL="${darwin_sdk_url}"

RUN mkdir -p "/tmp/osxcross"                                                                                   \
 && cd "/tmp/osxcross"                                                                                         \
 && curl -sLo osxcross.tar.gz "https://codeload.github.com/${OSXCROSS_REPO}/tar.gz/${OSXCROSS_REVISION}"  \
 && tar --strip=1 -xzf osxcross.tar.gz                                                                         \
 && rm -f osxcross.tar.gz                                                                                      \
 && curl -sLo tarballs/MacOSX${DARWIN_SDK_VERSION}.sdk.tar.xz                                                  \
             "${DARWIN_SDK_URL}"                \
 && yes "" | SDK_VERSION="${DARWIN_SDK_VERSION}" OSX_VERSION_MIN="${DARWIN_OSX_VERSION_MIN}" ./build.sh                               \
 && mv target /usr/osxcross                                                                                    \
 && mv tools /usr/osxcross/                                                                                    \
 && ln -sf ../tools/osxcross-macports /usr/osxcross/bin/omp                                                    \
 && ln -sf ../tools/osxcross-macports /usr/osxcross/bin/osxcross-macports                                      \
 && ln -sf ../tools/osxcross-macports /usr/osxcross/bin/osxcross-mp                                            \
 && rm -rf /tmp/osxcross                                                                                       \
 && rm -rf "/usr/osxcross/SDK/MacOSX${DARWIN_SDK_VERSION}.sdk/usr/share/man"

RUN useradd -ms /bin/bash rust

USER rust
WORKDIR /home/rust

RUN curl https://sh.rustup.rs -sSf -o rustup.sh && \
        sh ./rustup.sh -y && \
        $HOME/.cargo/bin/rustup default $RUST_VER && \
        $HOME/.cargo/bin/rustup target add x86_64-pc-windows-gnu && \
        $HOME/.cargo/bin/rustup target add x86_64-apple-darwin && \
        rm rustup.sh

ENV PATH $PATH:/home/rust/.cargo/bin:/usr/osxcross/bin

RUN cp /usr/x86_64-w64-mingw32/lib/*crt2.o \
        /home/rust/.rustup/toolchains/1.35.0-x86_64-unknown-linux-gnu/lib/rustlib/x86_64-pc-windows-gnu/lib/

ADD lin-cargo /usr/local/bin/
ADD mac-cargo /usr/local/bin/
ADD mac-c++ /usr/local/bin/
ADD mac-cc /usr/local/bin/
ADD win-cargo /usr/local/bin/
ADD win-cc /usr/local/bin

WORKDIR /workdir

CMD ["lin-cargo", "build", "--release"]

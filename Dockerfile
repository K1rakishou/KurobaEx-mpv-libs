FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    autoconf \
    pkgconf \
    libtool \
    ninja-build \
    python3-pip \
    gperf \
    git \
    wget \
    unzip \
    nasm \
    openjdk-17-jdk-headless \
    && pip3 install meson --break-system-packages \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN git clone https://github.com/mpv-android/mpv-android.git .
RUN git clone https://github.com/K1rakishou/KurobaEx-mpv-libs.git KurobaEx-mpv-libs

RUN for patch in KurobaEx-mpv-libs/patches/*.patch; do \
    echo "==> Applying $patch" && \
    git apply "$patch"; \
done

WORKDIR /build/buildscripts

RUN IN_CI=1 WGET="wget --progress=bar:force" ./include/download-sdk.sh
RUN IN_CI=1 WGET="wget --progress=bar:force" ./include/download-deps.sh

RUN mkdir -p deps/mpv && \
    wget --progress=bar:force https://github.com/mpv-player/mpv/archive/master.tar.gz -O master.tgz && \
    tar -xzf master.tgz -C deps/mpv --strip-components=1 && \
    rm master.tgz

RUN for arch in armv7l arm64 x86 x86_64; do \
    echo "==> Building deps for $arch" && \
    ./buildall.sh --arch $arch --only-deps mpv && \
    echo "==> Building mpv for $arch" && \
    ./buildall.sh --arch $arch -n mpv || { \
        logfile="deps/mpv/_build-${arch}/meson-logs/meson-log.txt"; \
        [ -f "$logfile" ] && cat "$logfile"; \
        exit 1; \
    }; \
done

RUN bash -c '\
    source ./include/path.sh && \
    PREFIX32=$([ -f prefix/armv7l/lib/libmpv.so ] && echo $PWD/prefix/armv7l || true) && \
    PREFIX64=$([ -f prefix/arm64/lib/libmpv.so ] && echo $PWD/prefix/arm64 || true) && \
    PREFIX_X64=$([ -f prefix/x86_64/lib/libmpv.so ] && echo $PWD/prefix/x86_64 || true) && \
    PREFIX_X86=$([ -f prefix/x86/lib/libmpv.so ] && echo $PWD/prefix/x86 || true) && \
    PREFIX32=$PREFIX32 PREFIX64=$PREFIX64 PREFIX_X64=$PREFIX_X64 PREFIX_X86=$PREFIX_X86 \
    ndk-build -C ../app/src/main -j$(nproc) \
'

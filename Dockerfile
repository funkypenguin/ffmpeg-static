# ffmpeg - http://ffmpeg.org/download.html
#
# https://hub.docker.com/r/jrottenberg/ffmpeg/
#
#

FROM        alpine:3.5 AS base

RUN     apk  add --no-cache --update libgcc ca-certificates libcrypto1.0 libssl1.0 libgomp expat
#RUN     apk  add --no-cache --update libgcc libstdc++ ca-certificates libcrypto1.0 libssl1.0 libgomp expat

# BUILD_DATE and VCS_REF are immaterial, since this is a 2-stage build, but our build
# hook won't work unless we specify the args
ARG BUILD_DATE
ARG VCS_REF


FROM        base AS build

# BUILD_DATE and VCS_REF are immaterial, since this is a 2-stage build, but our build
# hook won't work unless we specify the args
ARG BUILD_DATE
ARG VCS_REF

WORKDIR     /tmp/workdir

ARG        PKG_CONFIG_PATH=/opt/ffmpeg/lib/pkgconfig
ARG        LD_LIBRARY_PATH=/opt/ffmpeg/lib
ARG        PREFIX=/opt/ffmpeg
ARG        MAKEFLAGS="-j2"

ENV         FFMPEG_VERSION=4.0.2     \
            FDKAAC_VERSION=0.1.5      \
            LAME_VERSION=3.99.5       \
            LIBASS_VERSION=0.13.7     \
            OGG_VERSION=1.3.2         \
            OPENCOREAMR_VERSION=0.1.5 \
            OPUS_VERSION=1.2          \
            OPENJPEG_VERSION=2.1.2    \
            THEORA_VERSION=1.1.1      \
            VORBIS_VERSION=1.3.5      \
            VPX_VERSION=1.7.0         \
            X264_VERSION=20170226-2245-stable \
            X265_VERSION=2.3          \
            XVID_VERSION=1.3.4        \
            FREETYPE_VERSION=2.5.5    \
            FRIBIDI_VERSION=0.19.7    \
            FONTCONFIG_VERSION=2.12.4 \
            LIBVIDSTAB_VERSION=1.1.0  \
            KVAZAAR_VERSION=1.2.0     \
            AOM_VERSION=master        \
            FFNVCODEC_VERSION=n8.2.15.4 \
            SRC=/usr/local

ARG         OGG_SHA256SUM="e19ee34711d7af328cb26287f4137e70630e7261b17cbe3cd41011d73a654692  libogg-1.3.2.tar.gz"
ARG         OPUS_SHA256SUM="77db45a87b51578fbc49555ef1b10926179861d854eb2613207dc79d9ec0a9a9  opus-1.2.tar.gz"
ARG         VORBIS_SHA256SUM="6efbcecdd3e5dfbf090341b485da9d176eb250d893e3eb378c428a2db38301ce  libvorbis-1.3.5.tar.gz"
ARG         THEORA_SHA256SUM="40952956c47811928d1e7922cda3bc1f427eb75680c3c37249c91e949054916b  libtheora-1.1.1.tar.gz"
ARG         XVID_SHA256SUM="4e9fd62728885855bc5007fe1be58df42e5e274497591fec37249e1052ae316f  xvidcore-1.3.4.tar.gz"
ARG         FREETYPE_SHA256SUM="5d03dd76c2171a7601e9ce10551d52d4471cf92cd205948e60289251daddffa8  freetype-2.5.5.tar.gz"
ARG         LIBVIDSTAB_SHA256SUM="14d2a053e56edad4f397be0cb3ef8eb1ec3150404ce99a426c4eb641861dc0bb  v1.1.0.tar.gz"
ARG         LIBASS_SHA256SUM="8fadf294bf701300d4605e6f1d92929304187fca4b8d8a47889315526adbafd7  0.13.7.tar.gz"
ARG         FRIBIDI_SHA256SUM="3fc96fa9473bd31dcb5500bdf1aa78b337ba13eb8c301e7c28923fea982453a8  0.19.7.tar.gz"


RUN     buildDeps="autoconf \
                   automake \
                   bash \
                   binutils \
                   bzip2 \
                   cmake \
                   curl \
                   coreutils \
                   diffutils \
                   file \
                   g++ \
                   gcc \
                   gperf \
                   libtool \
                   make \
                   python \
                   openssl-dev \
                   tar \
                   nasm \
                   yasm \
                   musl-dev \
                   zlib-dev \
                   expat-dev" && \
        apk  add --no-cache --update ${buildDeps}

## opencore-amr https://sourceforge.net/projects/opencore-amr/
RUN \
        DIR=/tmp/opencore-amr && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://kent.dl.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-${OPENCOREAMR_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        ./configure --prefix="${PREFIX}" --disable-shared --enable-static  && \
        make && \
        make install && \
        rm -rf ${DIR}

## x264 http://www.videolan.org/developers/x264.html
RUN \
        DIR=/tmp/x264 && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://download.videolan.org/pub/videolan/x264/snapshots/x264-snapshot-${X264_VERSION}.tar.bz2 | \
        tar -jx --strip-components=1 && \
        ./configure --prefix="${PREFIX}" --disable-shared --enable-static --enable-pic --disable-cli && \
        make && \
        make install && \
        rm -rf ${DIR}

### x265 http://x265.org/
RUN \
        DIR=/tmp/x265 && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://download.videolan.org/pub/videolan/x265/x265_${X265_VERSION}.tar.gz  | \
        tar -zx && \
        cd x265_${X265_VERSION}/build/linux && \
        sed -i "/-DEXTRA_LIB/ s/$/ -DCMAKE_INSTALL_PREFIX=\${PREFIX}/" multilib.sh && \
        sed -i "/^cmake/ s/$/ -DENABLE_CLI=OFF/" multilib.sh && \
        ./multilib.sh && \
        make -C 8bit install && \
        rm -rf ${DIR}

### libogg https://www.xiph.org/ogg/
RUN \
        DIR=/tmp/ogg && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO http://downloads.xiph.org/releases/ogg/libogg-${OGG_VERSION}.tar.gz && \
        echo ${OGG_SHA256SUM} | sha256sum --check && \
        tar -zx --strip-components=1 -f libogg-${OGG_VERSION}.tar.gz && \
        ./configure --prefix="${PREFIX}" --disable-shared --enable-static  && \
        make && \
        make install && \
        rm -rf ${DIR}
### libopus https://www.opus-codec.org/
RUN \
        DIR=/tmp/opus && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://archive.mozilla.org/pub/opus/opus-${OPUS_VERSION}.tar.gz && \
        echo ${OPUS_SHA256SUM} | sha256sum --check && \
        tar -zx --strip-components=1 -f opus-${OPUS_VERSION}.tar.gz && \
        autoreconf -fiv && \
        ./configure --prefix="${PREFIX}" --disable-shared --enable-static && \
        make && \
        make install && \
        rm -rf ${DIR}
### libvorbis https://xiph.org/vorbis/
RUN \
        DIR=/tmp/vorbis && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO http://downloads.xiph.org/releases/vorbis/libvorbis-${VORBIS_VERSION}.tar.gz && \
        echo ${VORBIS_SHA256SUM} | sha256sum --check && \
        tar -zx --strip-components=1 -f libvorbis-${VORBIS_VERSION}.tar.gz && \
        ./configure --prefix="${PREFIX}" --with-ogg="${PREFIX}" --disable-shared --enable-static && \
        make && \
        make install && \
        rm -rf ${DIR}
### libtheora http://www.theora.org/
RUN \
        DIR=/tmp/theora && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO http://downloads.xiph.org/releases/theora/libtheora-${THEORA_VERSION}.tar.gz && \
        echo ${THEORA_SHA256SUM} | sha256sum --check && \
        tar -zx --strip-components=1 -f libtheora-${THEORA_VERSION}.tar.gz && \
        ./configure --prefix="${PREFIX}" --with-ogg="${PREFIX}" --disable-shared --enable-static && \
        make && \
        make install && \
        rm -rf ${DIR}
### libvpx https://www.webmproject.org/code/
RUN \
        DIR=/tmp/vpx && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://codeload.github.com/webmproject/libvpx/tar.gz/v${VPX_VERSION} | \
        tar -zx --strip-components=1 && \
        ./configure --prefix="${PREFIX}" --enable-vp8 --enable-vp9 --enable-vp9-highbitdepth --enable-pic --disable-shared --enable-static \
        --disable-debug --disable-examples --disable-docs --disable-install-bins  && \
        make && \
        make install && \
        rm -rf ${DIR}
### libmp3lame http://lame.sourceforge.net/
RUN \
        DIR=/tmp/lame && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://kent.dl.sourceforge.net/project/lame/lame/$(echo ${LAME_VERSION} | sed -e 's/[^0-9]*\([0-9]*\)[.]\([0-9]*\)[.]\([0-9]*\)\([0-9A-Za-z-]*\)/\1.\2/')/lame-${LAME_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        ./configure --prefix="${PREFIX}" --bindir="${PREFIX}/bin" --disable-shared --enable-static --enable-nasm --enable-pic --disable-frontend && \
        make && \
        make install && \
        rm -rf ${DIR}
### xvid https://www.xvid.com/
RUN \
        DIR=/tmp/xvid && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO http://downloads.xvid.org/downloads/xvidcore-${XVID_VERSION}.tar.gz && \
        echo ${XVID_SHA256SUM} | sha256sum --check && \
        tar -zx -f xvidcore-${XVID_VERSION}.tar.gz && \
        cd xvidcore/build/generic && \
        ./configure --prefix="${PREFIX}" --bindir="${PREFIX}/bin" --datadir="${DIR}" --disable-shared --enable-static && \
        make && \
        make install && \
        rm -rf ${DIR}
### fdk-aac https://github.com/mstorsjo/fdk-aac
RUN \
        DIR=/tmp/fdk-aac && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://github.com/mstorsjo/fdk-aac/archive/v${FDKAAC_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        autoreconf -fiv && \
        ./configure --prefix="${PREFIX}" --enable-shared --datadir="${DIR}" && \
        make && \
        make install && \
        rm -rf ${DIR}
## freetype https://www.freetype.org/
RUN  \
        DIR=/tmp/freetype && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO http://download.savannah.gnu.org/releases/freetype/freetype-${FREETYPE_VERSION}.tar.gz && \
        echo ${FREETYPE_SHA256SUM} | sha256sum --check && \
        tar -zx --strip-components=1 -f freetype-${FREETYPE_VERSION}.tar.gz && \
        ./configure --prefix="${PREFIX}" --enable-static --disable-shared && \
        make && \
        make install && \
        rm -rf ${DIR}
## libvstab https://github.com/georgmartius/vid.stab
RUN  \
        DIR=/tmp/vid.stab && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://github.com/georgmartius/vid.stab/archive/v${LIBVIDSTAB_VERSION}.tar.gz &&\
        echo ${LIBVIDSTAB_SHA256SUM} | sha256sum --check && \
        tar -zx --strip-components=1 -f v${LIBVIDSTAB_VERSION}.tar.gz && \
        cmake -DCMAKE_INSTALL_PREFIX="${PREFIX}" . && \
        make && \
        make install && \
        rm -rf ${DIR}
## fridibi https://www.fribidi.org/
# + https://github.com/fribidi/fribidi/issues/8
RUN  \
        DIR=/tmp/fribidi && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://github.com/fribidi/fribidi/archive/${FRIBIDI_VERSION}.tar.gz && \
        echo ${FRIBIDI_SHA256SUM} | sha256sum --check && \
        tar -zx --strip-components=1 -f ${FRIBIDI_VERSION}.tar.gz && \
        sed -i 's/^SUBDIRS =.*/SUBDIRS=gen.tab charset lib/' Makefile.am && \
        ./bootstrap --no-config && \
        ./configure -prefix="${PREFIX}" --enable-static --disable-shared && \
        make -j 1 && \
        make install && \
        rm -rf ${DIR}
## fontconfig https://www.freedesktop.org/wiki/Software/fontconfig/
RUN  \
        DIR=/tmp/fontconfig && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://www.freedesktop.org/software/fontconfig/release/fontconfig-${FONTCONFIG_VERSION}.tar.bz2 &&\
        tar -jx --strip-components=1 -f fontconfig-${FONTCONFIG_VERSION}.tar.bz2 && \
        ./configure -prefix="${PREFIX}" --enable-static --disable-shared && \
        make && \
        make install && \
        rm -rf ${DIR}
## libass https://github.com/libass/libass
RUN  \
        DIR=/tmp/libass && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://github.com/libass/libass/archive/${LIBASS_VERSION}.tar.gz &&\
        echo ${LIBASS_SHA256SUM} | sha256sum --check && \
        tar -zx --strip-components=1 -f ${LIBASS_VERSION}.tar.gz && \
        ./autogen.sh && \
        ./configure -prefix="${PREFIX}" --enable-static --disable-shared && \
        make && \
        make install && \
        rm -rf ${DIR}

## kvazaar https://github.com/ultravideo/kvazaar
RUN \
        DIR=/tmp/kvazaar && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://github.com/ultravideo/kvazaar/archive/v${KVAZAAR_VERSION}.tar.gz &&\
        tar -zx --strip-components=1 -f v${KVAZAAR_VERSION}.tar.gz && \
        ./autogen.sh && \
        ./configure -prefix="${PREFIX}" --enable-static --disable-shared && \
        make && \
        make install && \
        rm -rf ${DIR}

RUN \
        dir=/tmp/aom ; \
        mkdir -p ${dir} ; \
        cd ${dir} ; \
        curl -sLO https://aomedia.googlesource.com/aom/+archive/${AOM_VERSION}.tar.gz ; \
        tar -zx -f ${AOM_VERSION}.tar.gz ; \
        rm -rf CMakeCache.txt CMakeFiles ; \
        mkdir -p ./aom_build ; \
        cd ./aom_build ; \
        cmake -DCMAKE_INSTALL_PREFIX="${PREFIX}" -DBUILD_SHARED_LIBS=1 ..; \
        make ; \
        make install ; \
        rm -rf ${dir}


## ffnvcodec
RUN \
        dir=/tmp/ffnvcodec ; \
        mkdir -p ${dir} ; \
        curl -sLO https://github.com/FFmpeg/nv-codec-headers/archive/${FFNVCODEC_VERSION}.tar.gz &&\
        tar -zx -f ${FFNVCODEC_VERSION}.tar.gz ; \
        cd nv-codec-headers-${FFNVCODEC_VERSION} ; \
        make ; \
        make install ; \
        rm -rf ${dir}

## ffmpeg https://ffmpeg.org/
RUN  \
        DIR=$(mktemp -d) && cd ${DIR} && \
        curl -sLO https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.bz2 && \
        tar -jx --strip-components=1 -f ffmpeg-${FFMPEG_VERSION}.tar.bz2 && \
        ./configure \
        --pkg-config-flags="--static"  \
        --disable-debug \
        --disable-doc \
        --disable-ffplay \
        --disable-shared \
        --enable-static \
        --enable-avresample \
        --enable-libopencore-amrnb \
        --enable-libopencore-amrwb \
        --enable-gpl \
        --enable-libfreetype \
        --enable-libmp3lame \
        --enable-libopus \
        --enable-libtheora \
        --enable-libvorbis \
        --enable-libvpx \
        --enable-libx265 \
        --enable-libxvid \
        --enable-libx264 \
        --enable-nonfree \
        --enable-openssl \
        --enable-libfdk_aac \
        --enable-libkvazaar \
        --enable-postproc \
        --enable-small \
        --enable-version3 \
        --extra-cflags="-I${PREFIX}/include --static" \
        --extra-ldflags="-L${PREFIX}/lib --static" \
        --extra-libs=-ldl \
        --prefix="${PREFIX}" \
        --enable-cuda \
        --enable-decoder=h264_cuvid \
        --enable-decoder=hevc_cuvid \
        --enable-decoder=mjpeg_cuvid \
        --enable-decoder=mpeg1_cuvid \
        --enable-decoder=mpeg2_cuvid \
        --enable-decoder=mpeg4_cuvid \
        --enable-decoder=vc1_cuvid \
        --enable-decoder=vp8_cuvid \
        --enable-decoder=vp9_cuvid \
        --enable-encoder=h264_nvenc \
        --enable-encoder=hevc_nvenc \
        --enable-libass \
        --enable-cuvid && \
        make && \
        make install && \
        make distclean && \
        hash -r && \
        cd tools && \
        make qt-faststart && \
        cp qt-faststart ${PREFIX}/bin

###### Now an empty container with just the ffmpeg binaries
FROM        base as release 
MAINTAINER  David Young <davidy@funkypenguin.co.nz>

# Now we DO need these, for the auto-labeling of the image
ARG BUILD_DATE
ARG VCS_REF

# Good docker practice, plus we get microbadger badges
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/funkypenguin/ffmpeg-static.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.schema-version="2.2-r1"

# The singular purpose of this container is to produce a statically-compiled
# ffmpeg/ffprobe binary, so copy these to the VOLUME /export
RUN   mkdir /export

# Get the ffmpeg binaries from the build stage
COPY --from=build /opt/ffmpeg/bin/ff* /usr/local/bin/

# Prepare the script to copy the binaries out of the container
ADD copy-to-export.sh /

# Make the script executable
RUN  chmod 755 /copy-to-export.sh
 
# Allow the user to mount /export, so that they can get their binaries copied
VOLUME [ "/export" ]

# When the container runs, just execute the script and copy the files
ENTRYPOINT ["/copy-to-export.sh"]
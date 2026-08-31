# Ubuntu 20.04 on purpose: LineageOS 17.1 build scripts still expect python2
# as `python`, which later Ubuntu releases no longer provide by default.
FROM mcr.microsoft.com/devcontainers/base:ubuntu-20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        bc bison build-essential ccache curl flex g++-multilib gcc-multilib \
        git git-lfs gnupg gperf imagemagick lib32ncurses5-dev lib32readline-dev \
        lib32z1-dev libelf-dev liblz4-tool libncurses5 libncurses5-dev \
        libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush python2 \
        rsync schedtool squashfs-tools unzip xsltproc zip zlib1g-dev \
    && ln -sf /usr/bin/python2 /usr/bin/python \
    && rm -rf /var/lib/apt/lists/*

# The tree carries its own JDK under prebuilts/jdk, so no system JDK here.

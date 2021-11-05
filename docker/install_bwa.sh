#!/bin/bash

# do NOT remove this command
apt-get update

# fill up your additional steps for the package installation
apt-get install --no-install-recommends -y build-essential gcc cmake libbz2-dev zlib1g-dev automake git \
    && git config --global http.sslVerify false \
    && git clone https://github.com/lh3/bwa.git && cd bwa && make && cp bwa /usr/bin \
    && apt-get remove -y git cmake libbz2-dev zlib1g-dev automake gcc build-essential \
    && apt-get autoclean -y && apt-get autoremove -y --purge && rm -rf /var/lib/apt/lists/* && rm -rf /var/cache/apk* \
    && rm -rf /bwa*
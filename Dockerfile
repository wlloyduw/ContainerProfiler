FROM profiler:latest
MAINTAINER varikmp<varikmp@uw.edu>
ENV DEBIAN_FRONTEND noninteractive
ENV HOME /root
RUN apt-get update \
    && apt-get install --no-install-recommends -y build-essential gcc cmake libbz2-dev zlib1g-dev automake autoconf autoconf-archive pkg-config libhdf5-dev git \
    && git config --global http.sslVerify false \
    && git clone https://github.com/pachterlab/kallisto.git && cd kallisto/ext/htslib && autoheader && autoconf && cd ../.. && mkdir build && cd build && cmake .. && make && make install \
    && apt-get remove -y git automake autoconf autoconf-archive pkg-config zlib1g-dev libbz2-dev cmake gcc build-essential \
    && apt-get autoclean -y && apt-get autoremove -y --purge && rm -rf /var/lib/apt/lists/* && rm -rf /var/cache/apk* \
    && rm -rf /root/kallisto*
COPY docker/entrypoint.sh .
RUN chmod +x entrypoint.sh
RUN sed -i 's/COMMAND/kallisto/g' entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]

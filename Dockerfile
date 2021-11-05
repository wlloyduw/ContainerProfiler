FROM profiler:latest
MAINTAINER Varik Hoang <varikmp@uw.edu>
ENV DEBIAN_FRONTEND noninteractive
COPY ./docker/entrypoint.sh .
RUN chmod +x entrypoint.sh
COPY docker/install_bwa.sh .
RUN chmod +x ./install_bwa.sh && ./install_bwa.sh
RUN sed -i 's/COMMAND/bwa/g' entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]

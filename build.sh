#!/bin/bash
#======================================================================
#- IMPLEMENTATION
#-    version         docker builder (https://www.washington.edu/) 0.1
#-    author          Varik Hoang <varikmp@uw.edu>
#-    copyright       Copyright (c) https://www.washington.edu/
#-    license         GNU General Public License
#======================================================================
#  HISTORY
#     2021/09/27 : varikmp - script creation
#======================================================================
#  OPTION
#    -u --ubuntu-version # specify the ubuntu version for profiler
#    -d --docker-file    # specify the docker file based on profiler
#======================================================================

# the script only allows sudo or root user
if [ "$EUID" -ne 0 ]
then
    echo "The script requires to have sudo or root permission"
    exit
fi

# color code format
RED='\e[91m'
GREEN='\e[92m'
YELLOW='\e[93m'
BLANK='\e[39m'

# capture the arguments
echo -e "[$GREEN""INFO "$BLANK"] parsing arguments ..."
eval set -- "$(getopt -a --options u:d: -- "$@")"
while true
do
    case "$1" in
        -u|--ubuntu-version)
            UBUNTU_VERSION=$2
            shift 2;;
        -d|--docker-file)
            DOCKER_FILE=$2
            shift 2;;
        --)
            break;;
    esac
done

if [ -z "$UBUNTU_VERSION" ]
then
    echo -e "[$YELLOW""WARN "$BLANK"] did not specify the ubuntu version"
    UBUNTU_VERSION=$(cat /etc/os-release | grep VERSION_ID | grep -o '".*"' | sed 's/"//g')
fi
echo -e "[$GREEN""INFO "$BLANK"] ubuntu version: $UBUNTU_VERSION"
echo -e "[$GREEN""INFO "$BLANK"] docker file: $DOCKER_FILE"

echo "FROM ubuntu:$UBUNTU_VERSION" > Dockerfile
cat ./docker/base.docker >> Dockerfile
docker build -t profiler .

if [ -f "$DOCKER_FILE" ]
then
    echo "FROM profiler:latest" > Dockerfile
    cat $DOCKER_FILE >> Dockerfile
    docker build -t profiler:$(basename $DOCKER_FILE .docker) .
fi
rm Dockerfile
exit

python plotly_graph_generation.py -s 1 --infile deltas.csv graph_generation_config.ini
sudo ./build.sh -d docker/sysbench.docker

# for debugging purpose
sudo docker run --rm \
    -e TOOL=profile \
    -e TOOL_ARGUMENTS="-t 1 -o /data/sysbench" \
    -v ${PWD}:/data \
    -v ${PWD}/profiler.sh:/profiler.sh \
    -v ${PWD}/docker/sysbench.sh:/sysbench.sh \
    profiler:sysbench

--test=cpu --cpu-max-prime=20000 --max-requests=4000 run
--test=memory --memory-block-size=1M --memory-total-size=100G  --num-threads=1 run

# to profile a set of commands (generating profiling files in JSON format
sudo docker run --rm \
    -e TOOL=profile \
    -e TOOL_ARGUMENTS="-t 1 -o /data/sysbench" \
    -v ${PWD}:/data \
    profiler:sysbench --test=cpu --cpu-max-prime=20000 --max-requests=4000 run

# calculate the deltas from profiling files
sudo docker run --rm \
    -e TOOL=delta \
    -e TOOL_ARGUMENTS="-i /data/sysbench -o /data/sysbench" \
    -v ${PWD}:/data \
    profiler:sysbench

sudo docker run --rm \
    -e TOOL=csv \
    -e TOOL_ARGUMENTS="-w -i /data/sysbench -o /data/sysbench/deltas.csv -p /data/sysbench/process.csv" \
    -v ${PWD}:/data \
    profiler:sysbench

sudo docker run --rm \
    -e TOOL=graph \
    -e TOOL_ARGUMENTS="-r /data/sysbench/deltas.csv -g /data/sysbench -m /data/cfg/graph.cfg -s" \
    -v ${PWD}:/data \
    profiler:sysbench



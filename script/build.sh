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
#    PROFILER_OUTPUT_DIR # specify the output directory
#    PROFILER_TIME_STEPS # specify the time step each second
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


#rm $DOCKER_FILE
# sudo docker run --rm -v $PWD:/data profiler profile -o /data

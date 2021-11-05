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

# check software
if [ -z "$(which bc)" ]
then
    apt install -y bc
fi

# color code format
RED='\e[91m'
GREEN='\e[92m'
YELLOW='\e[93m'
BLANK='\e[39m'

# capture the arguments
echo -e "[$GREEN""INFO "$BLANK"] parsing arguments ..."
eval set -- "$(getopt -a --options u:d:i:e:p: -- "$@")"
while true
do
    case "$1" in
        -u|--ubuntu-version)
            UBUNTU_VERSION=$2
            shift 2;;
        -d|--docker-file)
            DOCKER_FILE=$2
            shift 2;;
		-i|--install-script)
            INSTALL_SCRIPT=$2
            shift 2;;
        -e|--execute-script)
            EXECUTE_SCRIPT=$2
            shift 2;;
        -p|--entrypoint)
            ENTRYPOINT=$2
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

# list all configurations
echo -e "[$GREEN""INFO "$BLANK"] ubuntu version: $UBUNTU_VERSION"
if [ -z "$INSTALL_SCRIPT" ]; then echo -e "[$YELLOW""WARN "$BLANK"] did not specify the install script"; else echo -e "[$GREEN""INFO "$BLANK"] install script: $INSTALL_SCRIPT"; fi
if [ -z "$EXECUTE_SCRIPT" ]; then echo -e "[$YELLOW""WARN "$BLANK"] did not specify the execute script"; else echo -e "[$GREEN""INFO "$BLANK"] execute script: $EXECUTE_SCRIPT"; fi
if [ -z "$DOCKER_FILE" ]; then echo -e "[$YELLOW""WARN "$BLANK"] did not specify the docker file"; else echo -e "[$GREEN""INFO "$BLANK"] docker file: $EXECUTE_SCRIPT"; fi

# start capturing the build time
START_TIME=`date +%s`

# start building the container image
echo "FROM ubuntu:$UBUNTU_VERSION" > Dockerfile
cat ./docker/base.docker >> Dockerfile
docker build -t profiler .

### 
echo "FROM profiler:latest" > Dockerfile
echo "MAINTAINER Varik Hoang <varikmp@uw.edu>" >> Dockerfile
echo "ENV DEBIAN_FRONTEND noninteractive" >> Dockerfile
echo "COPY ./docker/entrypoint.sh ." >> Dockerfile
echo "RUN chmod +x entrypoint.sh" >> Dockerfile

INSTALLED_PACKAGES=""
REMOVED_PACKAGES=""

if [ ! -z "$INSTALL_SCRIPT" ] && [ -f "$INSTALL_SCRIPT" ]
then
    echo "COPY $INSTALL_SCRIPT ." >> Dockerfile
    echo "RUN chmod +x ./$(basename $INSTALL_SCRIPT) && ./$(basename $INSTALL_SCRIPT)" >> Dockerfile
    
    # add installed packages to the list
    STATEMENTS=$(cat $INSTALL_SCRIPT | sed ':a;N;$!ba;s/\\\n//g;s/\t//g;s/  / /g' | grep apt | grep " install" | awk -F '&&' '{print $1; print $2}')
    IFS=$'\n'; for STATEMENT in ${STATEMENTS[@]}; do INSTALLED_PACKAGES="$INSTALLED_PACKAGES$(echo $STATEMENT | grep apt | grep install | sed 's/apt-get//g;s/apt//g;s/install//g;s/-y//g;s/  //g;:a;N;$!ba;s/\t//g')"; done; IFS=$' '
    STATEMENTS=$(cat $INSTALL_SCRIPT | sed ':a;N;$!ba;s/\\\n//g;s/\t//g;s/  / /g' | grep apt | grep " remove" | awk -F '&&' '{print $1; print $2}')
    IFS=$'\n'; for STATEMENT in ${STATEMENTS[@]}; do REMOVED_PACKAGES="$REMOVED_PACKAGES$(echo $STATEMENT | grep apt | grep remove | sed 's/apt-get//g;s/apt//g;s/remove//g;s/-y//g;s/  //g;:a;N;$!ba;s/\t//g')"; done; IFS=$' '
fi

if [ ! -z "$EXECUTE_SCRIPT" ] && [ -f "$EXECUTE_SCRIPT" ]
then
    echo "COPY $EXECUTE_SCRIPT ." >> Dockerfile
    echo "RUN chmod +x ./$(basename $EXECUTE_SCRIPT)" >> Dockerfile
    
    # add execute script to the list
    INSTALLED_PACKAGES="$(basename $EXECUTE_SCRIPT) $INSTALLED_PACKAGES"
fi

if [ -z "$ENTRYPOINT" ] && [ ! -z "$INSTALLED_PACKAGES" ]
then
    # list all packages installed to set entry point
    for PACKAGE in ${REMOVED_PACKAGES[@]}; do INSTALLED_PACKAGES=${INSTALLED_PACKAGES//$PACKAGE/}; INSTALLED_PACKAGES=${INSTALLED_PACKAGES//  /}; done
    echo -e "[$YELLOW""WARN "$BLANK"] did not specify the entry point"
    echo -e "[$GREEN""INFO "$BLANK"] here is a list of installed packages select one command for entrypoint: $GREEN$INSTALLED_PACKAGES$BLANK"
    printf "[$GREEN""INFO "$BLANK"] please select one command for entrypoint: $GREEN"
    read ENTRYPOINT
    printf "$BLANK"
fi

# design the tag name for docker image
if [ ! -z "$DOCKER_FILE" ]
then
    TAG=$(basename $DOCKER_FILE .docker)
    
    cat $DOCKER_FILE | 
    exit
    cat $DOCKER_FILE >> Dockerfile
elif [ ! -z "$ENTRYPOINT" ]
then
    TAG=$(basename $ENTRYPOINT)

    # replace the command as entry point
    if [[ "$ENTRYPOINT" == "$(basename $EXECUTE_SCRIPT)" ]]; then ENTRYPOINT="bash $(basename $ENTRYPOINT)"; fi
    echo "RUN sed -i 's/COMMAND/$ENTRYPOINT/g' entrypoint.sh" >> Dockerfile
    echo "ENTRYPOINT [\"./entrypoint.sh\"]" >> Dockerfile
else
    TAG=custom
fi

# build the docker image
docker build -t profiler:$TAG .

# finish capturing the build time
END_TIME=`date +%s`
RUNTIME=$(echo "$END_TIME - $START_TIME" | bc -l)
echo -e "[$GREEN""INFO "$BLANK"] time to build the container image profiler:$TAG is $RUNTIME seconds";

# check the docker image
DOCKER_IMAGE=$(docker images | grep profiler | grep $TAG)
if [ -z "$DOCKER_IMAGE" ]
then
    echo -e "[$RED""ERROR"$BLANK"] could not find the container image profiler:$TAG";
else
    echo -e "[$GREEN""INFO "$BLANK"] here is an example of running the container"
    echo -e "$GREEN\$$BLANK sudo docker run --rm \\"
    echo -e "\t-e TOOL=profile \\"
    echo -e "\t-e TOOL_ARGUMENTS=\"-t 1 -o /data\" \\"
    echo -e "\t-v \${PWD}:/data \\"
    echo -e "\t profiler:$TAG YOUR_ARUMENTS_GO_HERE"
fi


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

sudo docker run --rm \
    -e TOOL=profile \
    -e TOOL_ARGUMENTS="-t 1 -o /data/sysbench" \
    -v ${PWD}:/data \
    profiler:execute.sh

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



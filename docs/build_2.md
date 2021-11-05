# Table of Contents

FILL UP LATER

# (UC34) How do I build the ContainerProfiler to profile the total resource utilization

```bash
sudo ./build.sh
```

## (UC3) How do I profile a task or application

```bash
sudo docker run --rm -v ${PWD}:/OUTPUT_DIR  profiler:custom profile -o /OUTPUT_DIR SET_OF_TASKS
```

For example:

```bash
sudo docker run --rm -v ${PWD}:/data  profiler:custom profile -o /data "sleep 5; ls -al"
```

OUTPUT_DIR: the directory that holds profiling files in JSON format

## (UC4) How do I profile a task or application

```bash
sudo docker run --rm
    -v ${PWD}:/OUTPUT_DIR
    profiler:custom profile -t TIME_INTERVAL -o /OUTPUT_DIR SET_OF_TASKS
```

For example:

```bash
sudo docker run --rm -v ${PWD}:/data  profiler:custom profile -t 1 -o /data "sleep 5; ls -al"
```

# (UC12) How do I build a container that integrates the ContainerProfiler using my own Docker file

```bash
sudo ./build.sh -d DOCKER_FILE_PATH
```

For example:

```bash
sudo ./build.sh -d docker/sysbench.docker
```

## (UC1) How do I profile a task or application

```bash
sudo docker run --rm \
    -e TOOL=profile \
    -e TOOL_ARGUMENTS="-o /data" \
    -v ${PWD}:/data \
    profiler:CONTAINER_TAG YOUR_ARUMENTS_GO_HERE
```

For example:

```bash
sudo docker run --rm \
    -e TOOL=profile \
    -e TOOL_ARGUMENTS="-o /data" \
    -v ${PWD}:/data \
    profiler:sysbench --test=cpu --cpu-max-prime=20000 --max-requests=4000 run
```

## (UC2) How do I perform time series sampling

```bash
sudo docker run --rm \
    -e TOOL=profile \
    -e TOOL_ARGUMENTS="-t TIME_INTERVAL -o /data" \
    -v ${PWD}:/data \
    profiler:CONTAINER_TAG YOUR_ARUMENTS_GO_HERE
```

For example:

```bash
sudo docker run --rm \
    -e TOOL=profile \
    -e TOOL_ARGUMENTS="-t 1 -o /data" \
    -v ${PWD}:/data \
    profiler:sysbench --test=cpu --cpu-max-prime=20000 --max-requests=4000 run
```

# (UC56) How do I build a container that integrates the ContainerProfiler using my install script

```bash
sudo ./build.sh -i INSTALL_SCRIPT_PATH
```

For example:

```bash
sudo ./build.sh -i docker/install.sh
```

You will be asked to enter an entry point based on the software you attempt to install in your install script

## (UC5) How do I profile a task or application

```bash
sudo docker run --rm \
    -e TOOL=profile \
    -e TOOL_ARGUMENTS="-o /data" \
    -v ${PWD}:/data \
    profiler:CONTAINER_TAG YOUR_ARUMENTS_GO_HERE
```

For example:

```bash
sudo docker run --rm \
	-e TOOL=profile \
	-e TOOL_ARGUMENTS="-o /data" \
	-v ${PWD}:/data \
	 profiler:sysbench --test=cpu --cpu-max-prime=20000 --max-requests=4000 run
```

## (UC5) How do I profile a task or application

```bash
sudo docker run --rm \
    -e TOOL=profile \
    -e TOOL_ARGUMENTS="-t TIME_INTERVAL -o /data" \
    -v ${PWD}:/data \
    profiler:CONTAINER_TAG YOUR_ARUMENTS_GO_HERE
```

For example:

```bash
sudo docker run --rm \
	-e TOOL=profile \
	-e TOOL_ARGUMENTS="-t 1 -o /data" \
	-v ${PWD}:/data \
	 profiler:sysbench --test=cpu --cpu-max-prime=20000 --max-requests=4000 run
```
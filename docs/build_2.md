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

## (UC4) How do I perform time series profiling of a task or application

The idea is to add the '-t' argument to specify a time series sampling interval.  (e.g. '-t 1' for 1-second sampling)

```bash
sudo docker run --rm
    -v ${PWD}:/OUTPUT_DIR
    profiler:custom profile -t TIME_INTERVAL -o /OUTPUT_DIR SET_OF_TASKS
```

For example:

```bash
sudo docker run --rm -v ${PWD}:/data  profiler:custom profile -t 1 -o /data "sleep 5; ls -al"
```

# (UC12) How do I build a new container that integrates the ContainerProfiler into on an existing container

You will need access to the Dockerfile used to build your container.
The idea is that your container will already be configured to run a specified task or application, and 
we simply want to integrate the container profiler so it is easy to profile.
The idea is to point to the folder containing your Dockerfile and any other dependencies.

```bash
sudo ./build.sh -d DOCKER_FILE_PATH
```

For example:

```bash
sudo ./build.sh -d docker/sysbench.docker
```

## (UC1) How do I profile my container once I've integrated the ContainerProfiler 

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

## (UC2) How do I perform time series sampling on my container once I've integrated the ContainerProfiler

The idea is to add the '-t' argument to specify a time series sampling interval.  (e.g. '-t 1' for 1-second sampling)

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

# (UC56) How do I build a container that integrates the ContainerProfiler to profile software where I provide an installation script

Here the installation script should install all software dependencies required to run the application.
It is not necessary to preface installation commands with 'sudo'.

```bash
sudo ./build.sh -i INSTALL_SCRIPT_PATH
```

For example:

```bash
sudo ./build.sh -i docker/install.sh
```

You will be asked to enter an entry point based on the software you attempt to install in your install script.
The entry point is the name of the command (without any arguments) that will be run.
For example, if the installation script installs sysbench, then the name of the command will be 'sysbench'.
Later, when running the container you do not need to specify the command again, but just the arguments that are to be passed to the command.

## (UC5) How do I profile a task or application installed using the installation script

After the container name 'profiler:sysbench' you will need to specify the command line arguments
for the application being profiled.

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

## (UC5) How do I perform time series sampling of the task or application installed using the installation script

After the container name 'profiler:sysbench' you will need to specify the command line arguments
for the application being profiled.

In addition, add the '-t' argument to specify a time series sampling interval.  (e.g. '-t 1' for 1-second sampling)

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

## Delta: a tool is to compute the delta statistics of resource utilization between time instances

After receiving profiling files from the previous step, we run the delta option to generate delta statistics in JSON format.

Short Name | Long Name | Optional | Descriptions
--- | --- | --- | ---
-i | --input-directory | No | specify the input directory for calculating aggregate values in JSON format
-o | --output-directory | No | specify the output directory for calculating aggregate values in JSON format
-a | --aggregate-config-file | Yes | specify the aggregate configuration file
-c | --clean-up | Yes | clean up the aggregate files from the previous run

```bash
sudo docker run --rm \
	-e TOOL=delta \
	-e TOOL_ARGUMENTS="-i /data -o /data" \
	-v ${PWD}:/data \
	 profiler:sysbench
```

## CSV generator: a tool is to generate the statistics of resource utilization in JSON format

We need to specify the directory that holds statistic files. Those files are generated from the delta tool.

Short Name | Long Name | Optional | Descriptions
--- | --- | --- | ---
-i | --input-directory | No | specify the input directory of aggregate files
-o | --csv-output-file | No | specify the output file for CSV file generation
-w | --overwrite | Yes | overwrite the CSV file from the previous run

```bash
sudo docker run --rm \
	-e TOOL=csv \
	-e TOOL_ARGUMENTS="-i /data -o /data/delta.csv" \
	-v ${PWD}:/data \
	 profiler:sysbench
```

## Graph: a tool is to make graph based on the statistic CSV file

The tool generate the graphs based on the statistic file in CSV format. Also, we can provide the metric configuration file for the graphs.

Short Name | Long Name | Optional | Descriptions
--- | --- | --- | ---
-r | --csv-input-file | No | specify the aggregate CSV file
-m | --metric-input-file | Yes | specify the metric file specifying metrics for graphing
-g | --graph-output-directory | No | specify the output directory for graph images
-s | --single-plot | Yes | plot single curve on a graph


```bash
sudo docker run --rm \
	-e TOOL=graph \
	-e TOOL_ARGUMENTS="-i /data -o /data" \
	-v ${PWD}:/data \
	 profiler:sysbench
```
# Container Profiler

University of Washington Tacoma

<img src="./docs/logo.png" alt="drawing" width="400"/>

# Table of Contents
   * [FAQ](#faq)
      * [General](#general)
         * [Why should I use the Container Profiler?](#why-should-i-use-the-Container-Profiler)
      * [Usage](#usage)
         * [How do I use Container Profiler on my own container?](#how-do-i-use-the-Container-Profiler-on-my-own-container)
      * [Miscellaneous](#miscellaneous)
         * [How should I reference the Container Profiler if I use it?](#how-should-i-reference-the-Container-Profiler-if-i-use-it)
   * [MANUAL](#manual)
      * [GENERAL INFORMATION](#general-information)
         * [Overview: Running the Container Profiler](#overview-running-the-container-Profiler)
      * [Container Profiler](#container-profiler-1)
         * [Function Reference](#function-reference)
         * [Metrics Description](#metrics-description)
         * [VM Level Metrics](#vm-level-metrics)
         * [Container Level Metrics](#container-level-metrics)
         * [Process Level Metrics](#process-level-metrics)
      * [Tutorial - Profiling a Container](#tutorial-profiling-a-container)
         * [Video Demonstration](#video-demonstration)
         * [Install the Container Profiler](#Install-the-Container-Profiler)
         * [Preparing the Container Profiler](#Preparing-the-Container-Profiler)
         * [Starting the Profiler](#starting-the-profiler)

# FAQ
## General

### Why should I use the Container Profiler?

#### Easy to use profiling for applications or workflows in a container. 

## Usage

### How do I use the Container Profiler on my own container?

1\. Install the Container Profiler

2\. Here the common [use cases](docs/build.md) for applying the Container Profiler to profile a container 

## Miscellaneous
### How should I reference the Container Profiler if I use it?

# MANUAL
## GENERAL INFORMATION
The Container Profiler can be used as a tool to profile an application or workflow by taking interval snapshots of a collection of linux resource utilization metrics throughout the course of the job. These snapshots are then stored as JSON data which can then be used to see how the metrics changed once the job is finished.

In order to use the Container Profiler, a container with an application/workflow/script to be run and profiled is needed.
### Overview: Running the Container Profiler


## Container Profiler

ContainerProfiler includes bash scripts **rudataall.sh** to profile the resource utilization on VM level, container level and process level and **deltav2.sh** to compute the delta statistics of resource utilization between two time instances. Detailed usage of the profiler script can be found in the YouTube video linked below (demo scripts can be found in profiler_demo directory).

**Authors:** Wes Lloyd & Huazeng Deng & Ling-hong Hung & Varik Hoang

**Version:**   0.3

**GitHub:**    https://github.com/wlloyduw/ContainerProfiler

**Preprint:**  https://arxiv.org/abs/2005.11491

**License:**   Copyright.

## Metrics Description 
=======

The text below describes the metrics captured by the script **rudataall.sh** for profiling resource utilization on the 
virtual machine (VM) level, container level and process level. A complete metrics description spreadsheet can be found at 
https://github.com/wlloyduw/ContainerProfiler/blob/master/metrics_description_for_rudataall.xlsx 

## VM Level Metrics
----------------


| **Attribute** | **Description** |
| ------------- | --------------- |
| vCpuTime | Total CPU time (cpu_user+cpu_kernel) in centiseconds (cs) (hundreths of a second) |
| vCpuTimeUserMode | CPU time for processes executing in user mode in centiseconds (cs) |  
| vCpuTimeKernelMode | CPU time for processes executing in kernel mode in centiseconds (cs) |  
| vCpuIdleTime | CPU idle time in centiseconds (cs) |  
| vCpuTimeIOWait | CPU time waiting for I/O to complete in centiseconds (cs) |  
| vCpuTimeIntSrvc | CPU time servicing interrupts in centiseconds (cs) |  
| vCpuTimeSoftIntSrvc | CPU time servicing soft interrupts in centiseconds (cs) |  
| vCpuContextSwitches | The total number of context switches across all CPUs |  
| vCpuNice | Time spent with niced processes executing in user mode in centiseconds (cs) |  
| vCpuSteal | Time stolen by other operating systems running in a virtual environment in centiseconds (cs) |  
| vCpuType | The model name of the processor |  
| vCpuMhz | The precise speed in MHz for thee processor to the thousandths decimal place |  
| vDiskSectorReads | The number of disk sectors read, where a sector is typically 512 bytes, assumes /dev/sda1|  
| vDiskSectorWrites | The number of disk sectors written, where a sector is typically 512 bytes, assumes /dev/sda1 |  
| vDiskSuccessfulReads | Number of disk reads completed succesfully |
| vDiskMergedReads | Number of disk reads merged together (adjacent and merged for efficiency) |
| vDiskReadTime | Time spent reading from the disk in millisecond (ms) |
| vDiskSuccessfulReads | Number of disk reads completed succesfully |
| vDiskSuccessfulWrites | Number of disk writes completed succesfully |
| vDiskMergedWrites | Number of disk writes merged together (adjacent and merged for efficiency) |
| vDiskWriteTime | Time spent writing in milliseconds (ms) |
| vMemoryTotal | Total amount of usable RAM in kilobytes (KB) |
| vMemoryFree | The amount of physical RAM left unused by the system in kilobytes (KB) |
| vMemoryBuffers | The amount of temporary storage for raw disk blocks in kilobytes (KB) |
| vMemoryCached | The amount of physical RAM used as cache memory in kilobytes (KB) |
| vNetworkBytesRecvd | Network Bytes received assumes eth0 in bytes |
| vNetworkBytesSent | Network Bytes written assumes eth0 in bytes |
| vLoadAvg | The system load average as an average number of running plus waiting threads over the last minute |
| vPgFault | type of exception raised by computer hardware when a running program accesses a memory page that is not currently mapped by the memory management unit (MMU) into the virtual address space of a process|
| vMajorPageFault | Major page faults are expected when a prdocess starts or needs to read in additional data and in these cases do not indicate a problem condition |
| vId | VM ID (default is "unavailable") |
| currentTime | Number of seconds (s) that have elapsed since January 1, 1970 (midnight UTC/GMT) |

## Container Level Metrics
----------------

| **Attribute** | **Description** |
| ------------- | --------------- |
| cCpuTime | Total CPU time consumed by all tasks in this cgroup (including tasks lower in the hierarchy) in nanoseconds (ns) |
| cProcessorStats | Self-defined parameter |
| cCpu${i}TIME | CPU time consumed on each CPU by all tasks in this cgroup (including tasks lower in the hierarchy) in nanoseconds (ns) |
| cNumProcessors | Number of CPU processors |
| cCpuTimeUserMode | CPU time consumed by tasks in user mode in this cgroup in centiseconds (cs) |
| cCpuTimeKernelMode | PU time consumed by tasks in kernel mode in this cgroup in centiseconds (cs) |
| cDiskSectorIO | Number of sectors transferred to or from specific devices by a cgroup |
| cDiskReadBytes | Number of bytes transferred from specific devices by a cgroup in bytes |
| cDiskWriteBytes | Number of bytes transferred to specific devices by a cgroup in bytes |
| cMemoryUsed | Total current memory usage by processes in the cgroup in bytes |
| cMemoryMaxUsed | Maximum memory used by processes in the cgroup in bytes |
| cNetworkBytesRecvd | The number of bytes each interface has received |
| cNetworkBytesSent | The number of bytes each interface has sent |
| cId | Container ID |

## Process Level Metrics
----------------

| **Attribute** | **Description** |
| ------------- | --------------- |
| pId | Process ID |  
| pNumThreads | Number of threads in this process |  
| pCpuTimeUserMode | Total CPU time this process was scheduled in user mode, measured in clock ticks (divide by sysconf(\_SC_CLK_TCK)) |  
| pCpuTimeKernelMode | Total CPU time this process was scheduled in kernel mode, measured in clock ticks (divide by sysconf(\_SC_CLK_TCK)) |
| pChildrenUserMode | Total time children processes of the parent were scheduled in user mode, measured in clock ticks |
| pChildrenKernelMode | Total time children processes of the parent were scheduled in kernel mode, measured in clock ticks |
| pVoluntaryContextSwitches | Number of voluntary context switches | 
| pNonvoluntaryContextSwitches | Number of involuntary context switches | 
| pBlockIODelays | Aggregated block I/O delays, measured in clock ticks | 
| pVirtualMemoryBytes | Virtual memory size in bytes | 
| pResidentSetSize | Resident Set Size: number of pages the process has in real memory.  This is just the pages which count toward text, data, or stack space.  This does not include pages which have not been demand-loaded in, or which are swapped out | 
| pNumProcesses | Number of processes inside a container | 

       

## Tutorial: Profiling a Container

## Video Demonstration
**Video Channel:**     https://www.youtube.com/@containerprofiler6371 

1. Getting Started with the Container Profiler tool - [Part 1](https://www.youtube.com/watch?v=KK6kKfMkKuc) & [Part 2](https://www.youtube.com/watch?v=Tj3Zyje0DjY)
2. Profiling a bash script with the Container Profiler - [Link](https://www.youtube.com/watch?v=mGZkmXWJAGw)
3. Profiling applications with the Container Profiler using the install script - [Link](https://www.youtube.com/watch?v=L0qrtodC4j0)
4. Graphing Resource Utilization with the Container Profiler tool - [Link](https://www.youtube.com/watch?v=PFkETPfZI9g)
5. Profiling and graphing resource utilization of pgbench, the postgresql database benchmark - [Link](https://www.youtube.com/watch?v=cI8D4JRuyjw)

## Install the Container Profiler
```bash
git clone https://github.com/wlloyduw/ContainerProfiler
```

# How do I build the ContainerProfiler to profile the total resource utilization

```bash
sudo ./build.sh
```

## 1. How do I profile a task or application

```bash
sudo docker run --rm -v ${PWD}:/OUTPUT_DIR  profiler:custom profile -o /OUTPUT_DIR SET_OF_TASKS
```

For example:

```bash
sudo docker run --rm -v ${PWD}:/data  profiler:custom profile -o /data "sleep 5; ls -al"
```

OUTPUT_DIR: the directory that holds profiling files in JSON format

## 2. How do I perform time series profiling of a task or application

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

# How do I build a new container that integrates the ContainerProfiler into on an existing container

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

## 3. How do I profile my container once I've integrated the ContainerProfiler 

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

## 4. How do I perform time series sampling on my container once I've integrated the ContainerProfiler

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

# How do I build a container that integrates the ContainerProfiler to profile software where I provide an installation script

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

## 5. How do I profile a task or application installed using the installation script

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

## 6. How do I perform time series sampling of the task or application installed using the installation script

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

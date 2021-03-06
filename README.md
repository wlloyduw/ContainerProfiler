# ContainerProfiler

ContainerProfiler includes bash scripts **rudataall.sh** to profile the resource utilization on VM level, container level and process level and **deltav2.sh** to compute the delta statistics of resource utilization between two time instances. Detailed usage of the profiler script can be found in the YouTube video linked below (demo scripts can be found in profiler_demo directory).

**Authors:** Wes Lloyd & Huazeng Deng & Ling-hong Hung

**Version:**   0.2

**GitHub:**    https://github.com/wlloyduw/ContainerProfiler

**Video:**     https://youtu.be/X-_7zqeyffk

**License:**   Copyright.




Function Reference
======

**deltav2**.sh calculates the delta from 2 json files produced by **rudataall.sh**

It writes the deltas to stdout in json format and the missing fields to stderr

####Usage:
```bash
deltav2.sh file1.json file2.json 2>missing.txt 1>delta.json
```
Test file and scripts are found in testFiles

####Description
Basically it loops through file1 to find key : numeric_value pairs and store them in an associative array. It then loops through file2 to print out the json elements and calculate deltas. Missing values in file1 are printed here and a second key numericValue associative array is mad. A third loop then searches through the first associative array to fine missing values in file2. 

As long as there is no more than one key : value pair per line in the json files and the key is unique (i.e. doesn't depend on the structure of the higher order json objects), the script should work fine. It is tolerant of order permutations, new or different fields, and missing lines but depends on file2 being valid json.

Metrics Description 
=======

The text below describes the metrics captured by the script **rudataall.sh** for profiling resource utilization on the 
virtual machine (VM) level, container level and process level. A complete metrics description spreadsheet can be found at 
https://github.com/wlloyduw/ContainerProfiler/blob/master/metrics_description_for_rudataall.xlsx 

VM Level Metrics
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
| vId | VM ID (default is "unavailable") |
| currentTime | Number of seconds (s) that have elapsed since January 1, 1970 (midnight UTC/GMT) |


      
          
          
Container Level Metrics
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


        

Process Level Metrics
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





    
       

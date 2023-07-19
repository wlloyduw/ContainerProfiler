# --------------------------------------------------------------------------
# The tool is to profile the resource utilization on VM level, container
# level and process level and deltav2.sh to compute the delta statistics of
# resource utilization between two time instances.
#
# (C) 2021 Washington of University
# authors: Wesley Lloyd, Ling-Hong Hung, David Perez, Varik Hoang
# email wlloyd@uw.edu
# --------------------------------------------------------------------------

import psutil
import shutil
import json
import argparse
from datetime import datetime
import re      
import subprocess
import os.path
from os import path
import os
import glob
import time

#add the virtual level.
CORRECTION_MULTIPLIER=100
CORRECTION_MULTIPLIER_MEMORY=(1/1000)
CGROUP_DIR='/sys/fs/cgroup/'

parser = argparse.ArgumentParser(description='process path and file /or string of metrics.')
parser.add_argument('output_dir', action='store', help='stores directory to where the files will be output to')
parser.add_argument('time_series', type=int, nargs='?', default=0, help='stores time series (in milliseconds) factor (default is 0 which means no time series)')
parser.add_argument("-v", "--vm_profiling", action="store_true", default=False, help='list of metrics to graph over')
parser.add_argument("-c", "--container_profiling", action="store_true", default=False, help='list of metrics to graph over')
parser.add_argument("-p", "--processor_profiling", action="store_true", default=False, help='list of metrics to graph over')
args= parser.parse_args()
output_dir = args.output_dir
time_series = args.time_series

if all(v is False for v in [args.vm_profiling, args.container_profiling, args.processor_profiling]):
    args.vm_profiling = True
    args.container_profiling=True
    args.processor_profiling=True

output_dict={}
already_printed=False

def print_nothing(*args):
    pass

def get_tick_in_ms():
    return (time.time()) # milliseconds

def get_file_content(file_path, default_value=""):
    """get_file_content(file_path, [default_value])

    Author: Varik Hoang
    The method return the content of the file, also can optionally provide
    the default value in case if the file is not existed or empty
    """
    try:
        with open(file_path, "r") as file_pointer:
            file_content = file_pointer.read()
            if len(file_content) == 0:
                return default_value
            return file_content
    except FileNotFoundError:
        if not os.path.isfile(".cgroupv2"):
            print_console("cgroup v2 detected")
            f = open(".cgroupv2", "a")
            f.write("File '{}' does not exist".format(file_path))
            f.close()
        # print_console("File '{}' does not exist".format(file_path))
    except:
        print_console("Could not open the file '{}'".format(file_path))
    return default_value

def execute_commands(set_of_commands):
    """execute_commands(commands)

    Author: Varik Hoang
    The method return the output of a set of commands
    """
    commands = []
    processes = []
    commands.append(set_of_commands[0].split())
    processes.append(subprocess.Popen(commands[-1], stdout=subprocess.PIPE))
    for command in set_of_commands[1:]:
        commands.append(command.split())
        processes.append(subprocess.Popen(commands[-1], stdin=processes[-1].stdout, stdout=subprocess.PIPE))
    output, _error = processes[-1].communicate()
    return output

def is_process_running():    
    """execute_commands(commands)

    Author: Varik Hoang
    The method checks for the existence of a process
    """
    try:
        with open("./profile.pid", "r") as file_pointer:
            os.kill(int(file_pointer.read()), 0)
    except:
        return False
    else:
        return True

def get_static_info():
    """get_static_info()

    Author: Varik Hoang
    The method write all static metrics to file once
    """
    vKernelInfo = execute_commands(["uname -a"]).decode("utf-8")[:-1]
    vCpuType = execute_commands(["cat /proc/cpuinfo", "grep model", "grep name", "uniq"]).decode("utf-8").split(sep=": ")[1][:-1]
    cId=get_file_content("/etc/hostname", "unknown")[:-1]
    
    # -----------------------------------------
    # Add CPU caches L1, L2, L3 to the profiler
    # -----------------------------------------
    vCpuCache = {}
    cpu_dirs = glob.glob('/sys/devices/system/cpu/cpu?')
    for cpu_dir in cpu_dirs:
        index_dirs = glob.glob('{}/cache/index*'.format(cpu_dir))
        for index_dir in index_dirs:
            file = open("{}/level".format(index_dir), "r")
            cache_level = int(file.readline()[:-1])
            file.close()
    
            file = open("{}/type".format(index_dir), "r")
            cache_type = str(file.readline()[:-1])
            file.close()
            if cache_type == "Data":
                cache_type = "d"
            elif cache_type == "Instruction":
                cache_type = "i"
            else:
                cache_type = ""
            
            file = open("{}/shared_cpu_map".format(index_dir), "r")
            cache_shared_cpu_map = str(file.readline()[:-1])
            file.close()
            
            file = open("{}/size".format(index_dir), "r")
            cache_size = str(file.readline()[:-1])
            file.close()
            
            cache_key = "L{}{}".format(cache_level, cache_type)
            if cache_key not in vCpuCache.keys():
                vCpuCache[cache_key] = {}
                cache_size_unit = cache_size[len(cache_size)-1]
                if cache_size_unit == "K":
                    cache_size = int(cache_size[:-1]) * 1024
                elif cache_size_unit == "M":
                    cache_size = int(cache_size[:-1]) * 1024 * 1024
                else:
                    cache_size = int(cache_size)
                vCpuCache[cache_key][cache_shared_cpu_map] = cache_size
            else:
                if cache_shared_cpu_map not in vCpuCache[cache_key].keys():
                    cache_size_unit = cache_size[len(cache_size)-1]
                    if cache_size_unit == "K":
                        cache_size = int(cache_size[:-1]) * 1024
                    elif cache_size_unit == "M":
                        cache_size = int(cache_size[:-1]) * 1024 * 1024
                    else:
                        cache_size = int(cache_size)
                    vCpuCache[cache_key][cache_shared_cpu_map] = cache_size
    
    for cache_key in vCpuCache.keys():
        total_size = 0
        for shared_cpu_map in vCpuCache[cache_key].keys():
            total_size += vCpuCache[cache_key][shared_cpu_map]
        vCpuCache[cache_key] = total_size
    
    vm_dict={
        "vKernelInfo" : vKernelInfo,
        "vCpuType" : vCpuType,
        "vCpuCache": vCpuCache,
        "vBootTime" : psutil.boot_time(),
        "vId" : "unavailable",
        "cNumProcessors": psutil.cpu_count(),
        "cId": cId,
    }
    return vm_dict

def getContainerInfo():
    cpuTime=int(get_file_content("{}/cpuacct/cpuacct.usage".format(CGROUP_DIR), 0))
    tcpuTime = get_tick_in_ms()

    container_mem_stats = get_file_content("{}/memory/memory.stat".format(CGROUP_DIR), "pgfault 0\npgmajfault 0")
    cpgfault = int(re.findall(r'pgfault.*', container_mem_stats)[0].split()[1])
    cpgmajfault = int(re.findall(r'pgmajfault.*', container_mem_stats)[0].split()[1])

    cpuinfo_file_stats = get_file_content("/proc/stat", "cpu 0 0 0 0 0 0 0 0 0 0") # default: 1 processor
    cCpuTimeUserMode = int(re.findall(r'cpu.*', cpuinfo_file_stats)[0].split()[1])
    tcCpuTimeUserMode = get_tick_in_ms()
    cCpuTimeKernelMode = int(re.findall(r'cpu.*', cpuinfo_file_stats)[0].split()[3])
    tcCpuTimeKernelMode = get_tick_in_ms()

    cProcessorStatsFileArr = get_file_content("{}/cpuacct/cpuacct.usage_percpu".format(CGROUP_DIR), "0").split() # default: 1 processor
    cProcessorDict={}
    count=0
    for el in cProcessorStatsFileArr:
        temp_str="cCpu${}TIME".format(count)
        cProcessorDict[temp_str]=int(el)
        tcCpuTIME = get_tick_in_ms()
        cProcessorDict["tcCpu${}TIME".format(count)]=tcCpuTIME
        count+=1

    # data sample
    # 8:0 53966
    # 11:0 0
    cDiskSectorIO = get_file_content("{}/blkio/blkio.sectors".format(CGROUP_DIR), "11:0 0\n22:0 0")
    try:
        cDiskSectorIOFileArr = cDiskSectorIO.split(sep='\n')
        cDiskSectorIO = sum([int(line.split()[1]) for line in cDiskSectorIOFileArr])
    except:
        print_console("Could not find the virtual file {}/blkio/blkio.sectors".format(CGROUP_DIR))
        cDiskSectorIO=0 
    
    cDiskReadBytes=0
    cDiskWriteBytes=0
    try:
        output = execute_commands(["lsblk -a", "grep disk"])
        major_minor_arr=[]
        for line in output.decode('UTF-8').split(sep='\n')[:-1]:
            major_minor_arr.append(line.split()[1])

        cDiskRWBytesFile = get_file_content("{}/blkio/blkio.throttle.io_service_bytes".format(CGROUP_DIR), "259:0 Read 0\n259:0 Write 0")
        cDiskReadBytesArr=re.findall(r'.*Read.*', cDiskRWBytesFile)
        cDiskWriteBytesArr=re.findall(r'.*Write.*', cDiskRWBytesFile)

        for el in cDiskReadBytesArr:
            temp_arr = el.split()
            for major_minor in major_minor_arr:
                if (temp_arr[0] == major_minor):
                    cDiskReadBytes += int(temp_arr[2])
        
        for el in cDiskWriteBytesArr:
            temp_arr = el.split()
            for major_minor in major_minor_arr:
                if (temp_arr[0] == major_minor):
                    cDiskWriteBytes += int(temp_arr[2])
    except ValueError: # this just happens if the latest kernel version changes the way to read values
        print_console("There is at least one disk read/write in bytes not an integer type")
        cDiskReadBytes = 0
        cDiskWriteBytes = 0

    cNetworkBytesRecvd = 0
    cNetworkBytesSent = 0
    cNetworkBytesFileStats = execute_commands(["cat /proc/net/dev", "grep eth0"])
    try:
        cNetworkBytesArr = cNetworkBytesFileStats.split() # laptop does not have eth0
        cNetworkBytesRecvd = int(cNetworkBytesArr[1])
        cNetworkBytesSent = int(cNetworkBytesArr[9])
    except IndexError:
        print_console("Could not find the network device eth0")
    except ValueError: # this just happens if the latest kernel version changes the way to read values
        print_console("There is at least one network received/sent in bytes not an integer type")

    cMemoryUsed = 0
    cMemoryMaxUsed = 0
    try:
        cMemoryUsed = int(get_file_content("{}/memory/memory.usage_in_bytes".format(CGROUP_DIR), "0"))
        cMemoryMaxUsed = int(get_file_content("{}/memory/memory.max_usage_in_bytes".format(CGROUP_DIR), "0"))
    except:
        print_console("The memory usage in bytes not an integer type")

    #CPU=(`cat /proc/stat | grep '^cpu '`)

    cNumProcesses = sum(1 for line in get_file_content("{}/pids/tasks".format(CGROUP_DIR), "2")) -2

    container_dict={        
        "cCpuTime": cpuTime,
        "tcCpuTime": tcpuTime,
        "cPGFault": cpgfault,
        "cMajorPGFault": cpgmajfault,
        "cProcessorStats": cProcessorDict,
        "cCpuTimeUserMode": cCpuTimeUserMode,
        "tcCpuTimeUserMode": tcCpuTimeUserMode,
        "cCpuTimeKernelMode": cCpuTimeKernelMode,
        "tcCpuTimeKernelMode": tcCpuTimeKernelMode,
        "cDiskSectorIO": cDiskSectorIO,
        "cDiskReadBytes":  cDiskReadBytes,
        "cDiskWriteBytes": cDiskWriteBytes    ,
        "cNetworkBytesRecvd":cNetworkBytesRecvd,
        "cNetworkBytesSent": cNetworkBytesSent,
        "cMemoryUsed": cMemoryUsed,
        "cMemoryMaxUsed": cMemoryMaxUsed,    
        "cNumProcesses": cNumProcesses,
        "pMetricType": "Process level"
    }
    return container_dict

def getVmInfo():
    cpu_info=psutil.cpu_times() # ATTENTION could not get ticks for each metrics inside this method
    t_cpu_info = get_tick_in_ms()
    net_info=psutil.net_io_counters(nowrap=True)
    cpu_info2=psutil.cpu_stats()
    disk_info=psutil.disk_io_counters()
    memory=psutil.virtual_memory()
    loadavg=psutil.getloadavg()
    cpu_freq=psutil.cpu_freq()
# get_file_content("VIRTUAL_FILE_PATH", "DEFAULT_VALUE")
    # vm_file = open("/proc/vmstat", "r")
    pgfault = int(execute_commands(["cat /proc/vmstat", "grep pgfault"]).split()[1])
    pgmajfault = int(execute_commands(["cat /proc/vmstat", "grep pgmajfault"]).split()[1])

    # cmd1=['lsblk', '-nd', '--output', 'NAME,TYPE']
    # cmd2=['grep','disk']
    # p1 = subprocess.Popen(cmd1, stdout=subprocess.PIPE)
    # p2 = subprocess.Popen(cmd2, stdin=p1.stdout, stdout=subprocess.PIPE)
    # o, e = p2.communicate()
    mounted_filesys=str(execute_commands(["lsblk -nd --output NAME,TYPE", "grep disk"]).decode("utf-8").split()[0])
    vm_disk_file=open("/proc/diskstats", "r")
    vm_disk_file_stats=vm_disk_file.read()
    vDiskSucessfulReads=int(re.findall(rf"{mounted_filesys}.*", vm_disk_file_stats)[0].split(sep=" ")[1])
    vDiskSucessfulWrites=int(re.findall(rf"{mounted_filesys}.*", vm_disk_file_stats)[0].split(sep=" ")[5])
    vDiskTotal, vDiskUsed, vDiskFree = shutil.disk_usage("/")

	# TODO add all ticks for each metric
    vm_dict={
        "vMetricType" : "VM Level",
        "vCpuTime" : (cpu_info[0] + cpu_info[2]) *CORRECTION_MULTIPLIER ,
        "tvCpuTime" : t_cpu_info,
        "vDiskSectorReads" : disk_info[2]/512, 
        "vDiskSectorWrites" : disk_info[3]/512,
        "vNetworkBytesRecvd" : net_info[1],
        "vNetworkBytesSent" : net_info[0], 
        "vPgFault" : pgfault,
        "vMajorPageFault" : pgmajfault,
        "vCpuTimeUserMode" : cpu_info[0] * CORRECTION_MULTIPLIER, 
        "tvCpuTimeUserMode" : t_cpu_info,
        "vCpuTimeKernelMode" : cpu_info[2] * CORRECTION_MULTIPLIER,
        "tvCpuTimeKernelMode" : t_cpu_info,
        "vCpuIdleTime" : cpu_info[3]* CORRECTION_MULTIPLIER,
        "tvCpuIdleTime" : t_cpu_info,
        "vCpuTimeIOWait" : cpu_info[4]* CORRECTION_MULTIPLIER,
        "tvCpuTimeIOWait" : t_cpu_info,
        "vCpuTimeIntSrvc" :  cpu_info[5]* CORRECTION_MULTIPLIER,
        "tvCpuTimeIntSrvc" :  t_cpu_info,
        "vCpuTimeSoftIntSrvc" : cpu_info[6] * CORRECTION_MULTIPLIER,
        "tvCpuTimeSoftIntSrvc" : t_cpu_info,
        "vCpuContextSwitches" : cpu_info2[0]* CORRECTION_MULTIPLIER,
        "tvCpuContextSwitches" : t_cpu_info,
        "vCpuNice" : cpu_info[1]* CORRECTION_MULTIPLIER,
        "tvCpuNice" : t_cpu_info,
        "vCpuSteal" : cpu_info[7]* CORRECTION_MULTIPLIER,
        "tvCpuSteal" : t_cpu_info,
        "vDiskTotal" : vDiskTotal,
        "vDiskUsed" : vDiskUsed,
        "vDiskFree" : vDiskFree,
        "vDiskSuccessfulReads" : vDiskSucessfulReads,
        "vDiskMergedReads" : disk_info[6],
        "vDiskReadTime" : disk_info[4],
        "vDiskSuccessfulWrites" : vDiskSucessfulWrites,
        "vDiskMergedWrites" : disk_info[7],
        "vDiskWriteTime" : disk_info[5],
        "vMemoryTotal" : round(memory[0] * CORRECTION_MULTIPLIER_MEMORY),    
        "vMemoryFree" : round(memory[4]* CORRECTION_MULTIPLIER_MEMORY),
        "vMemoryBuffers" : round(memory[7]* CORRECTION_MULTIPLIER_MEMORY),
        "vMemoryCached" : round(memory[8]* CORRECTION_MULTIPLIER_MEMORY),
        "vLoadAvg" : loadavg[0],
        "vCpuMhz" : cpu_freq[0]
    }
    return vm_dict

def getProcInfo():
    #need to get pPGFault/pMajorPGFault in a different verbosity level: maybe called MP for manual process
    #pResidentSetSize needs to be get in MP
    dictlist=[]
    for proc in psutil.process_iter():
        #procFile="/proc/{}/stat".format(proc.pid) 
        #log = open(procFile, "r")
        #pidProcStat=log.readline().split()
        try:
            curr_dict={
                "pId" : proc.pid,
                "pCmdline" : " ".join(proc.cmdline()),
                "pName" : proc.name(),
                "pNumThreads" : proc.num_threads(),
                "pCpuTimeUserMode" : proc.cpu_times()[0]* CORRECTION_MULTIPLIER,
                "pCpuTimeKernelMode" : proc.cpu_times()[1]* CORRECTION_MULTIPLIER,
                "pChildrenUserMode" : proc.cpu_times()[2]* CORRECTION_MULTIPLIER,
                "pChildrenKernelMode" : proc.cpu_times()[3]* CORRECTION_MULTIPLIER,
                #"pPGFault" : int(pidProcStat[9]),
                #"pMajorPGFault" : int(pidProcStat[11]),
                "pVoluntaryContextSwitches" : proc.num_ctx_switches()[0],        
                "pInvoluntaryContextSwitches" : proc.num_ctx_switches()[1],        
                "pBlockIODelays" : proc.cpu_times()[4]* CORRECTION_MULTIPLIER,
                "pVirtualMemoryBytes" : proc.memory_info()[1]
                #"pResidentSetSize" : proc.memory_info()[0]             
            }
            dictlist.append(curr_dict)
        except:
            pass
    return dictlist

def profile_command():
    """
    Author: Varik Hoang
    The method executes the command and return the profiling time in milliseconds
    """
    profiling_time=get_tick_in_ms()
    output_dict["currentTime"] = int(time.time() * 10**9)

    # seconds_since_epoch = round(datetime.now().timestamp())
    # output_dict["currentTime"] = seconds_since_epoch        #bad value.
    
    static_metrics_file = output_dir + '/static.json'
    if not os.path.exists(static_metrics_file):
        with open(static_metrics_file, 'w') as outfile: 
            json.dump(get_static_info(), outfile, indent=4)
    if args.vm_profiling == True:
        time_start_VM=datetime.now()
        vm_info=getVmInfo()
        time_end_VM=datetime.now()
        VM_write_time=time_end_VM-time_start_VM
        output_dict.update(vm_info)
        output_dict["VM_Write_Time"] = VM_write_time.total_seconds()
    if args.container_profiling == True:
        time_start_container=datetime.now()
        container_info=getContainerInfo()
        time_end_container=datetime.now()
        container_write_time=time_end_container-time_start_container
        output_dict.update(container_info)
        output_dict["Container_Write_Time"] = container_write_time.total_seconds()
    if args.processor_profiling == True:
        time_start_proc=datetime.now()
        procces_info=getProcInfo()
        time_end_proc=datetime.now()
        process_write_time=time_end_proc-time_start_proc
        output_dict["pProcesses"] = procces_info
        output_dict["Process_Write_Time"] = process_write_time.total_seconds()
    
    # capture the profiling time in milliseconds
    profiling_time = get_tick_in_ms()-profiling_time
    output_dict['profiling_time'] = profiling_time
    
    # write to output file
    filename = datetime.now().strftime(output_dir+"/%Y_%m_%d_%H_%M_%S.json")
    with open(filename, 'w') as outfile: 
        json.dump(output_dict, outfile, indent=4)

    return profiling_time

print_console=print
profile_time = profile_command()
if time_series > profile_time:
    time.sleep((time_series-profile_time)/1000)
print_console=print_nothing
# keep the process running until it finishes
while is_process_running():
    profile_time = profile_command()
    if time_series > profile_time:
        time.sleep((time_series-profile_time)/1000)
profile_command()

if time_series != 0:
	try:
		os.remove("./profile.pid")
	except:
		pass
	else:
		pass

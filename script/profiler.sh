#!/bin/bash
#======================================================================
#- IMPLEMENTATION
#-    version         profiler (https://www.washington.edu/) 0.6
#-    author          Varik Hoang <varikmp@uw.edu>
#-    copyright       Copyright (c) https://www.washington.edu/
#-    license         GNU General Public License
#======================================================================
#  HISTORY
#     2021/05/19 : varikmp - script creation
#     2021/08/12 : varikmp - implemented time steps for sampling
#     2021/12/03 : varikmp - change the time steps to milliseconds
#                          - generate static metrics separately
#     2022/05/24 : varikmp - report the sample collection time in ms
#     2022/06/24 : varikmp - add option for metric level setup
#     2025/10/16 : varikmp - swap the order of two time steps
#======================================================================
#  OPTION
#    PROFILER_OUTPUT_DIR # specify the output directory
#    PROFILER_TIME_STEPS # specify the time step each milliseconds
#======================================================================

RED='\e[91m'
GREEN='\e[92m'
YELLOW='\e[93m'
BLANK='\e[39m'
WHITE_SPACE="[[:space:]]"

function usage()
{
    echo "Usage: $0 [profile|aggregate|csv|graph]"
    echo "       profile: to profile a set of commands"
    echo "         -o   --output-directory       : specify the output directory for profiling data in JSON format"
    echo "         -m   --metric-level           : specify the metric level to profile (v for VM, c for container, and p for process)"
    echo "         -t   --time-steps             : specify the time steps (in milliseconds) to profile during the command execution"
    echo "         -c   --clean-up               : clean up the profiling files from the previous run"
    echo "       delta: calculate the aggregate values"
    echo "         -i   --input-directory        : specify the input directory for calculating aggregate values in JSON format"
    echo "         -o   --output-directory       : specify the output directory for calculating aggregate values in JSON format"
    echo "         -a   --aggregate-config-file  : specify the aggregate configuration file"
    echo "         -c   --clean-up               : clean up the aggregate files from the previous run"
    echo "       csv: generate records and put into CSV file from aggregate files"
    echo "         -i   --input-directory        : specify the input directory of aggregate files"
    echo "         -o   --csv-output-file        : specify the output file for CSV file generation"
    echo "         -p   --process-output-file    : specify the output file for CSV file generation"
    echo "         -w   --overwrite              : overwrite the CSV file from the previous run"
    echo "       graph: generate graphs from aggregate CSV file"
    echo "         -r   --csv-input-file         : specify the aggregate CSV file"
    echo "         -m   --metric-input-file      : specify the metric file specifying metrics for graphing"
    echo "         -g   --graph-output-directory : specify the output directory for graph images"
    echo "         -s   --single-plot            : plot single curve on a graph"
    echo "Example:"
    echo "       $0 profile -o ./test -c -t 1 \"sleep 3\""
    echo "       $0 delta -i test/ -o test/"
    echo "       $0 delta -i test/ -o test/ -a /test/aggregate.cfg"
    echo "       $0 csv -w -i test/"
    echo "       $0 csv -w -i test/ -o test/delta.csv"
    echo "       $0 graph -r delta.csv -g test/ -m graph.cfg"
    echo "       $0 graph -r delta.csv -g test/ -m graph.cfg -s"
}

function error()
{
    # https://www.cyberciti.biz/faq/bash-get-exit-code-of-command/
    case $1 in
        127) echo -e "[$RED""ERROR"$BLANK"] at least one command not found in set: $RED$2$BLANK" ;;
        *) echo -e "[$RED""ERROR"$BLANK"] could not recognize the error code $RED$1$BLANK" ;;
    esac
}

# TODO: need to have a function that check if all packages installed
# python3: psutil
# ubuntu: bc jq

function profile()
{
	# assign the default metric levels: VM, Container, and Process
	METRIC_LEVEL=vcp
	
    # clean up status file from the previous work
    echo "" > status.log

    # capture the arguments
    echo -e "[$GREEN""INFO "$BLANK"] profiling commands ..."; shift
    eval set -- "$(getopt -a --options o:m:t:cd -- "$@")"
    while true
    do
        ARGUMENT=$1
        if [[ $ARGUMENT =~ $WHITE_SPACE ]]
        then
            ARGUMENT=\"$ARGUMENT\"
        fi

        case "$ARGUMENT" in
            -o|--output-directory)
                PROFILER_OUTPUT_DIR=$2
                shift 2;;
            -m|--metric-level)
                METRIC_LEVEL=$2
                shift 2;;
            -t|--time-steps)
                PROFILER_TIME_STEPS=$2
                shift 2;;
            -c|--clean-up)
                DO_CLEAN_UP=1
                shift 1;;
            --)
                break;;
        esac
    done
    PROFILER_COMMAND_SET="${@:2}"
    shift # to remove the last couple of characters --

    # check if the variable is unset
    if [ -z "$PROFILER_OUTPUT_DIR" ]
    then
        echo -e "[$YELLOW""WARN "$BLANK"] did not specify the output directory to hold profiling files."
        echo -e "[$YELLOW""WARN "$BLANK"] set it to the current directory $YELLOW$(pwd)$BLANK"
        PROFILER_OUTPUT_DIR="$(pwd)"
    else
        # check if the output directory is absolute path
        case $PROFILER_OUTPUT_DIR in
            /*) ;;
            ./*) PROFILER_OUTPUT_DIR="$(pwd)/${PROFILER_OUTPUT_DIR:2}" ;;
            *) PROFILER_OUTPUT_DIR="$(pwd)/${PROFILER_OUTPUT_DIR}" ;;
        esac

        # check if the output directory is existed
        if [ ! -d "$PROFILER_OUTPUT_DIR" ]
        then
            echo -e "[$YELLOW""WARN "$BLANK"] could not find the output directory $YELLOW$PROFILER_OUTPUT_DIR$BLANK"
            echo -e "[$YELLOW""WARN "$BLANK"] set it to the current directory $YELLOW$(pwd)$BLANK"
            PROFILER_OUTPUT_DIR="$(pwd)"
        fi
    fi

    # check if the variable is a whole number
    # https://mathblog.com/regular-expressions-for-numbers-in-bash/
    REAL_REGEX="[+-]?([0-9]+|[0-9]+\.[0-9]*|\.[0-9]+)"
    if [ -z "$PROFILER_TIME_STEPS" ] || \
       ! [[ "$PROFILER_TIME_STEPS" =~ ^$REAL_REGEX$ ]]
    then
        echo -e "[$YELLOW""WARN "$BLANK"] could not recognize the time steps $YELLOW$PROFILER_TIME_STEPS$BLANK, the value must be a whole positive number"
        echo -e "[$YELLOW""WARN "$BLANK"] set the time steps to $YELLOW"0$BLANK" that captures time before and after finishing the commands"
        PROFILER_TIME_STEPS=0
    fi

    # print out arguments
    echo -e "[$GREEN""INFO "$BLANK"] the output directory for the profiling files: $GREEN$PROFILER_OUTPUT_DIR$BLANK"
    echo -e "[$GREEN""INFO "$BLANK"] the time steps (in milliseconds) for the profiling: $GREEN$PROFILER_TIME_STEPS$BLANK"
    echo -e "[$GREEN""INFO "$BLANK"] the set of commands for the profiling: $GREEN$PROFILER_COMMAND_SET$BLANK"

    # clean up the output directory before profiling
    if [ ! -z "$DO_CLEAN_UP" ]
    then
        find $PROFILER_OUTPUT_DIR -name "????_??_??_??_??_??.json" | xargs -r rm -f
    fi

    # start profiling
    if [ -z "$PROFILER_COMMAND_SET" ]
    then
        # generate a single profiling file
        python3 ./rudataall.py -$METRIC_LEVEL $PROFILER_OUTPUT_DIR
        STATUS=$? # must be always zero
    elif [ $(echo "$PROFILER_TIME_STEPS > 0" | bc -l) -le 0 ]
    then
        # execute the set of commands
        python3 ./rudataall.py -$METRIC_LEVEL $PROFILER_OUTPUT_DIR
        eval "$@"
        STATUS=$?
        python3 ./rudataall.py -$METRIC_LEVEL $PROFILER_OUTPUT_DIR
    else
        # execute the set of commands and capture the process id
        eval "$@" & PID=$!

        # keep checking the process id until it finishes in time steps
        #while kill -0 $PID > /dev/null 2>&1
        #do
        #    python3 ./rudataall.py -vcp $PROFILER_OUTPUT_DIR
        #    sleep $PROFILER_TIME_STEPS
        #done

        # capture the status code
        #wait $PID
        #STATUS=$?
        
        # https://github.com/wlloyduw/ContainerProfiler/blob/david/ubuntu/entrypoint.sh
        echo $PID > profile.pid
        python3 ./rudataall.py -$METRIC_LEVEL $PROFILER_OUTPUT_DIR $PROFILER_TIME_STEPS
        STATUS=$?
    fi

    # report the status code
    if [ $STATUS -eq 0 ]
    then
        echo -e "[$GREEN""INFO "$BLANK"] profiling commands passed"
        echo "passed" > status.log
    else
        error $STATUS $PROFILER_COMMAND_SET
        echo -e "[$RED""ERROR"$BLANK"] profiling commands failed"
        echo "failed" > status.log
    fi
}

function delta()
{
    # clean up status file from the previous work
    echo "" > status.log

    # capture the arguments
    echo -e "[$GREEN""INFO "$BLANK"] calculating aggregate values ..."; shift
    eval set -- "$(getopt -a --options i:o:a:c -- "$@")"
    while true
    do
        case "$1" in
            -i|--input-directory)
                PROFILING_INPUT_DIR=$2
                shift 2;;
            -o|--output-directory)
                AGGREGATE_OUTPUT_DIR=$2
                shift 2;;
            -a|--aggregate-configuration)
                AGGREGATE_CONFIG_FILE=$2
                shift 2;;
            -c|--clean-up)
                DO_CLEAN_UP=1
                shift 1;;
            --)
                break;;
        esac
    done

    # check if the input directory is unset
    if [ -z "$PROFILING_INPUT_DIR" ]
    then
        echo -e "[$YELLOW""WARN "$BLANK"] did not specify the input directory of profiling files."
        echo -e "[$YELLOW""WARN "$BLANK"] set it to the current directory $YELLOW$(pwd)$BLANK"
        PROFILING_INPUT_DIR="$(pwd)"
    else
        # check if the output directory is absolute path
        case $PROFILING_INPUT_DIR in
            /*) ;;
            ./*) PROFILING_INPUT_DIR="$(pwd)/${PROFILING_INPUT_DIR:2}" ;;
            *) PROFILING_INPUT_DIR="$(pwd)/${PROFILING_INPUT_DIR}" ;;
        esac

        # check if the output directory is existed
        if [ ! -d "$PROFILING_INPUT_DIR" ]
        then
            echo -e "[$YELLOW""WARN "$BLANK"] could not find the input directory $YELLOW$PROFILING_INPUT_DIR$BLANK"
            echo -e "[$YELLOW""WARN "$BLANK"] set it to the current directory $YELLOW$(pwd)$BLANK"
            PROFILING_INPUT_DIR="$(pwd)"
        fi
    fi

    # check if the output directory is unset
    if [ -z "$AGGREGATE_OUTPUT_DIR" ]
    then
        echo -e "[$YELLOW""WARN "$BLANK"] did not specify the output directory of profiling files."
        echo -e "[$YELLOW""WARN "$BLANK"] set it to the same directory of profiling files $YELLOW$PROFILING_INPUT_DIR$BLANK"
        AGGREGATE_OUTPUT_DIR=$PROFILING_INPUT_DIR
    else
        # check if the output directory is absolute path
        case $AGGREGATE_OUTPUT_DIR in
            /*) ;;
            ./*) AGGREGATE_OUTPUT_DIR="$(pwd)/${AGGREGATE_OUTPUT_DIR:2}" ;;
            *) AGGREGATE_OUTPUT_DIR="$(pwd)/${AGGREGATE_OUTPUT_DIR}" ;;
        esac

        # check if the output directory is existed
        if [ ! -d "$AGGREGATE_OUTPUT_DIR" ]
        then
            echo -e "[$YELLOW""WARN "$BLANK"] could not find the output directory $YELLOW$PROFILING_INPUT_DIR$BLANK"
            echo -e "[$YELLOW""WARN "$BLANK"] set it to the same directory of profiling files $YELLOW$PROFILING_INPUT_DIR$BLANK"
            AGGREGATE_OUTPUT_DIR=$PROFILING_INPUT_DIR
        fi
    fi

    # print out arguments
    echo -e "[$GREEN""INFO "$BLANK"] the input directory of the profiling files: $GREEN$PROFILING_INPUT_DIR$BLANK"
    echo -e "[$GREEN""INFO "$BLANK"] the output directory of the profiling files: $GREEN$AGGREGATE_OUTPUT_DIR$BLANK"

    # clean up the output directory before profiling
    if [ ! -z "$DO_CLEAN_UP" ]
    then
        find $AGGREGATE_OUTPUT_DIR -name "delta_????_??_??_??_??_??.json" | xargs -r rm -f
    fi

    # start calculating aggregate values
    # must sort all files in output directory to alternatively take the aggregate values
    PROFILING_FILES=$(find $PROFILING_INPUT_DIR -name "????_??_??_??_??_??.json" | sort)
    IFS=$'\n' read -rd '' -a PROFILING_FILES <<< "$PROFILING_FILES"
    SIZE=$((${#PROFILING_FILES[@]}-1))

    for INDEX in $(seq 1 $SIZE)
    do
        PREV_INDEX=$(($INDEX-1))
        ./aggregate.sh ${PROFILING_FILES[$PREV_INDEX]} ${PROFILING_FILES[$INDEX]} $AGGREGATE_CONFIG_FILE > $AGGREGATE_OUTPUT_DIR/delta_$(date '+%Y_%m_%d_%H_%M_%S').json
    done

    # report the status code (assume the aggregate calculation is always correct)
    echo -e "[$GREEN""INFO "$BLANK"] calculating aggregate values passed"
    echo "passed" > status.log
}

function keys()
{
    JSON_FILE=$1
    local CURRENT_PATH=$2

    if [ -z "$CURRENT_PATH" ]; then
        KEY_LIST=$(jq $CURRENT_PATH'keys' "$1" | sed '1d;$d;s/,$//;s/^ *//g;s/^.//g;s/.$//g' | tr '\r\n' ' ')
    else
        KEY_LIST=$(jq $CURRENT_PATH'|keys' "$1" | sed '1d;$d;s/,$//;s/^ *//g;s/^.//g;s/.$//g' | tr '\r\n' ' ')
    fi

    if [ ! -z "$KEY_LIST" ]
    then
        for KEY in ${KEY_LIST[@]}
        do
            case "$(jq -r $CURRENT_PATH[\"$KEY\"]\|type "$1" <<< '""')" in

                "object")
                    keys "$JSON_FILE" "$CURRENT_PATH[\"$KEY\"]"
                    ;;

                *)
					printf "$KEY,"
					;;
            esac
        done
    fi
}

function values()
{
	JSON_FILE=$1
    local CURRENT_PATH=$2

    if [ -z "$CURRENT_PATH" ]; then
        KEY_LIST=$(jq $CURRENT_PATH'keys' "$1" | sed '1d;$d;s/,$//;s/^ *//g;s/^.//g;s/.$//g' | tr '\r\n' ' ')
    else
        KEY_LIST=$(jq $CURRENT_PATH'|keys' "$1" | sed '1d;$d;s/,$//;s/^ *//g;s/^.//g;s/.$//g' | tr '\r\n' ' ')
    fi

    if [ ! -z "$KEY_LIST" ]
    then
        for KEY in ${KEY_LIST[@]}
        do
            case "$(jq -r $CURRENT_PATH[\"$KEY\"]\|type "$1" <<< '""')" in

                "object")
                    values "$JSON_FILE" "$CURRENT_PATH[\"$KEY\"]"
                    ;;

                *)
					printf "$(jq -r $CURRENT_PATH[\"$KEY\"] "$1" <<< '""'),"
					;;
            esac
        done
    fi
}

function csv()
{
    # clean up status file from the previous work
    echo "" > status.log

    # capture the arguments
    echo -e "[$GREEN""INFO "$BLANK"] generating CSV files ..."; shift
    eval set -- "$(getopt -a --options i:o:p:w -- "$@")"
    while true
    do
        case "$1" in
            -i|--input-directory)
                DELTA_INPUT_DIR=$2
                shift 2;;
            -o|--aggregate-output-file)
                CSV_OUTPUT_FILE=$2
                shift 2;;
            -p|--process-output-file)
                PROC_OUTPUT_FILE=$2
                shift 2;;
            -w|--overwrite-file)
                DO_OVERWRITE=$2
                shift 1;;
            --)
                break;;
        esac
    done

    # check if the input directory is unset
    if [ -z "$DELTA_INPUT_DIR" ]
    then
        echo -e "[$YELLOW""WARN "$BLANK"] did not specify the input directory of aggregate files."
        echo -e "[$YELLOW""WARN "$BLANK"] set it to the current directory $YELLOW$(pwd)$BLANK"
        DELTA_INPUT_DIR="$(pwd)"
    else
        # check if the output directory is absolute path
        case $DELTA_INPUT_DIR in
            /*) ;;
            ./*) DELTA_INPUT_DIR="$(pwd)/${DELTA_INPUT_DIR:2}" ;;
            *) DELTA_INPUT_DIR="$(pwd)/${DELTA_INPUT_DIR}" ;;
        esac

        # check if the output directory is existed
        if [ ! -d "$DELTA_INPUT_DIR" ]
        then
            echo -e "[$YELLOW""WARN "$BLANK"] could not find the input directory $YELLOW$DELTA_INPUT_DIR$BLANK"
            echo -e "[$YELLOW""WARN "$BLANK"] set it to the current directory $YELLOW$(pwd)$BLANK"
            DELTA_INPUT_DIR="$(pwd)"
        fi
    fi
    
    # check for the static metrics
    FOUND_STATIC=$(find $DELTA_INPUT_DIR -name "static.json")
    if [ -z "$FOUND_STATIC" ]
    then
        echo -e "[$RED""WARN "$BLANK"] could not find static file (static.json) in $DELTA_INPUT_DIR"
    else
        STATIC_FIELDS=$(keys $DELTA_INPUT_DIR/static.json .)
        STATIC_VALUES=$(values $DELTA_INPUT_DIR/static.json .)
    fi
    
    # set up fields
    #PROC_FIELDS="pId,pCmdline,pName,pNumThreads,pCpuTimeUserMode,pCpuTimeKernelMode,pChildrenUserMode,pChildrenKernelMode,pVoluntaryContextSwitches,pInvoluntaryContextSwitches,pBlockIODelays,pVirtualMemoryBytes"
    FOUND_DELTA=$(find $DELTA_INPUT_DIR -name "delta_????_??_??_??_??_??.json")
    if [ -z "$FOUND_DELTA" ]
    then
        echo -e "[$RED""ERROR"$BLANK"] could not find any delta files in $DELTA_INPUT_DIR"
        exit
    fi
    
    DELTA_TEMPLATE_FILE=$(echo ${FOUND_DELTA[0]} | cut -d" " -f1)
    DELTA_FIELDS=$(jq 'keys' $DELTA_TEMPLATE_FILE | sed '1d;$d;s/,$//;s/^ *//g;s/^.//g;s/.$//g' | tr '\n' ',' | sed 's/,$//')
    DELTA_FILTERS=$(echo $DELTA_FIELDS | sed 's/^/[./g;s/$/] | @csv/g;s/,/,./g')

    # check if the CSV output file is unset
    if [ -z "$CSV_OUTPUT_FILE" ]
    then
        echo -e "[$YELLOW""WARN "$BLANK"] did not specify the CSV output file for aggregate values."
        echo -e "[$YELLOW""WARN "$BLANK"] set it to $YELLOW$(pwd)/delta.csv$BLANK"
        CSV_OUTPUT_FILE="$(pwd)/delta.csv"
    else
        # check if the CSV output file is absolute path
        case $CSV_OUTPUT_FILE in
            /*) ;;
            ./*) CSV_OUTPUT_FILE="$(pwd)/${CSV_OUTPUT_FILE:2}" ;;
            *) CSV_OUTPUT_FILE="$(pwd)/${CSV_OUTPUT_FILE}" ;;
        esac
    fi

<< 'PROCESS_OUTPUT_FILE_ENABLE' 
    # check if the CSV output file is unset
    if [ -z "$PROC_OUTPUT_FILE" ]
    then
        echo -e "[$YELLOW""WARN "$BLANK"] did not specify the process output file."
        echo -e "[$YELLOW""WARN "$BLANK"] set it to $YELLOW./process.csv$BLANK"
        PROC_OUTPUT_FILE="$(dirname $CSV_OUTPUT_FILE)/process.csv"
    else
        # check if the CSV output file is absolute path
        case $PROC_OUTPUT_FILE in
            /*) ;;
            ./*) PROC_OUTPUT_FILE="$(pwd)/${PROC_OUTPUT_FILE:2}" ;;
            *) PROC_OUTPUT_FILE="$(pwd)/${PROC_OUTPUT_FILE}" ;;
        esac
    fi
PROCESS_OUTPUT_FILE_ENABLE

    # check if the CSV output file is existed and overwrite flag is on
    if [ ! -z "$DO_OVERWRITE" ] && [ -f "$CSV_OUTPUT_FILE" ]
    then
        # remove the old CSV file
        echo -e "[$YELLOW""WARN "$BLANK"] overwrite the CSV file $YELLOW$CSV_OUTPUT_FILE$BLANK"
        rm -f $CSV_OUTPUT_FILE
    fi
    
    # check if the process output file is existed and overwrite flag is on
    if [ ! -z "$DO_OVERWRITE" ] && [ -f "$PROC_OUTPUT_FILE" ]
    then
        # remove the old CSV file
        echo -e "[$YELLOW""WARN "$BLANK"] overwrite the process file $YELLOW$PROC_OUTPUT_FILE$BLANK"
        rm -f $PROC_OUTPUT_FILE
    fi

    # write headers to CSV output file
    echo "$STATIC_FIELDS$DELTA_FIELDS" > $CSV_OUTPUT_FILE
    
    #echo "$PROC_FIELDS" >> $PROC_OUTPUT_FILE

    # print out arguments
    echo -e "[$GREEN""INFO "$BLANK"] the input directory of the profiling: $GREEN$DELTA_INPUT_DIR$BLANK"
    echo -e "[$GREEN""INFO "$BLANK"] the CSV output file of the profiling: $GREEN$CSV_OUTPUT_FILE$BLANK"

    DELTA_FILES=$(find $DELTA_INPUT_DIR -name "delta_????_??_??_??_??_??.json" | sort)
    for DELTA_FILE in $DELTA_FILES
    do
        printf "$STATIC_VALUES" >> $CSV_OUTPUT_FILE
        jq -r "$DELTA_FILTERS" $DELTA_FILE >> $CSV_OUTPUT_FILE

<< 'PROCESS_OUTPUT_FILE_ENABLE'
        pId=$(jq -r ".pProcesses[].pId" $DELTA_FILE)
        pCmdline=$(jq -r ".pProcesses[].pCmdline" $DELTA_FILE)
        pName=$(jq -r ".pProcesses[].pName" $DELTA_FILE)
        pNumThreads=$(jq -r ".pProcesses[].pNumThreads" $DELTA_FILE)
        pCpuTimeUserMode=$(jq -r ".pProcesses[].pCpuTimeUserMode" $DELTA_FILE)
        pCpuTimeKernelMode=$(jq -r ".pProcesses[].pCpuTimeKernelMode" $DELTA_FILE)
        pChildrenUserMode=$(jq -r ".pProcesses[].pChildrenUserMode" $DELTA_FILE)
        pChildrenKernelMode=$(jq -r ".pProcesses[].pChildrenKernelMode" $DELTA_FILE)
        pVoluntaryContextSwitches=$(jq -r ".pProcesses[].pVoluntaryContextSwitches" $DELTA_FILE)
        pInvoluntaryContextSwitches=$(jq -r ".pProcesses[].pInvoluntaryContextSwitches" $DELTA_FILE)
        pBlockIODelays=$(jq -r ".pProcesses[].pBlockIODelays" $DELTA_FILE)
        pVirtualMemoryBytes=$(jq -r ".pProcesses[].pVirtualMemoryBytes" $DELTA_FILE)

        IFS=$'\n' read -rd '' -a pId <<< "$pId"
        IFS=$'\n' read -rd '' -a pCmdline <<< "$pCmdline"
        IFS=$'\n' read -rd '' -a pName <<< "$pName"
        IFS=$'\n' read -rd '' -a pNumThreads <<< "$pNumThreads"
        IFS=$'\n' read -rd '' -a pCpuTimeUserMode <<< "$pCpuTimeUserMode"
        IFS=$'\n' read -rd '' -a pCpuTimeKernelMode <<< "$pCpuTimeKernelMode"
        IFS=$'\n' read -rd '' -a pChildrenUserMode <<< "$pChildrenUserMode"
        IFS=$'\n' read -rd '' -a pChildrenKernelMode <<< "$pChildrenKernelMode"
        IFS=$'\n' read -rd '' -a pVoluntaryContextSwitches <<< "$pVoluntaryContextSwitches"
        IFS=$'\n' read -rd '' -a pInvoluntaryContextSwitches <<< "$pInvoluntaryContextSwitches"
        IFS=$'\n' read -rd '' -a pBlockIODelays <<< "$pBlockIODelays"
        IFS=$'\n' read -rd '' -a pVirtualMemoryBytes <<< "$pVirtualMemoryBytes"

        count=${#pId[@]}
        for ((index = 0; index < $count; index++))
        do
            echo "${pId[$index]},${pCmdline[$index]},${pName[$index]},${pNumThreads[$index]},${pCpuTimeUserMode[$index]},${pCpuTimeKernelMode[$index]},${pChildrenUserMode[$index]},${pChildrenKernelMode[$index]},${pVoluntaryContextSwitches[$index]},${pInvoluntaryContextSwitches[$index]},${pBlockIODelays[$index]},${pVirtualMemoryBytes[$index]}" >> $PROC_OUTPUT_FILE
        done
PROCESS_OUTPUT_FILE_ENABLE
    done

<< 'PROCESS_OUTPUT_FILE_ENABLE'
    # sort the process CSV output file (first column and ignore the others)
    sort -sk1,1n -o $PROC_OUTPUT_FILE $PROC_OUTPUT_FILE
PROCESS_OUTPUT_FILE_ENABLE
    echo "passed" > status.log
}

function graph()
{
    # clean up status file from the previous work
    echo "" > status.log

    # capture the arguments
    echo -e "[$GREEN""INFO "$BLANK"] graphing metrics ..."; shift
    eval set -- "$(getopt -a --options r:m:g:s -- "$@")"
    while true
    do
        case "$1" in
            -r|--csv-input-file)
                CSV_INPUT_FILE=$2
                shift 2;;
            -m|--metric-input-file)
                METRIC_INPUT_FILE=$2
                shift 2;;
            -g|--graph-output-directory)
                GRAPH_OUTPUT_DIRECTORY=$2
                shift 2;;
            -s|--single-plot)
                SINGLE_PLOT=1
                shift 1;;
            --)
                break;;
        esac
    done

    # check if the CSV input file is unset
    if [ -z "$CSV_INPUT_FILE" ]
    then
        echo -e "[$RED""ERROR"$BLANK"] the input CSV file must be specified"
        usage
        exit
    fi
    
    # check if the CSV input file is existed
    if [ ! -f "$CSV_INPUT_FILE" ]
    then
        echo -e "[$RED""ERROR"$BLANK"] the input CSV file '$CSV_INPUT_FILE' is not existed"
        exit
    fi
    
    # check if the CSV file is absolute path
    case $CSV_INPUT_FILE in
        /*) ;;
        ./*) CSV_INPUT_FILE="$(pwd)/${CSV_INPUT_FILE:2}" ;;
        *) CSV_INPUT_FILE="$(pwd)/${CSV_INPUT_FILE}" ;;
    esac

    # check if the metric file is unset or existed
    if [ -z "$METRIC_INPUT_FILE" ]
    then
        echo -e "[$YELLOW""WARN "$BLANK"] did not specify the CSV input file and will generate graphs for all metrics"
        METRIC_INPUT_FILE="./graph.default.cfg"
    else
        # check if the metric file is absolute path
        case $METRIC_INPUT_FILE in
            /*) ;;
            ./*) METRIC_INPUT_FILE="$(pwd)/${METRIC_INPUT_FILE:2}" ;;
            *) METRIC_INPUT_FILE="$(pwd)/${METRIC_INPUT_FILE}" ;;
        esac

        # check if the metric file is existed
        if [ ! -f "$METRIC_INPUT_FILE" ]
        then
            echo -e "[$YELLOW""WARN "$BLANK"] could not find the metric input file $YELLOW$METRIC_INPUT_FILE$BLANK"
            echo -e "[$YELLOW""WARN "$BLANK"] will generate graphs for all metrics"
            METRIC_INPUT_FILE="$(pwd)/graph.default.cfg"
        fi
    fi

    # check if the graph output directory is unset
    if [ -z "$GRAPH_OUTPUT_DIRECTORY" ]
    then
        echo -e "[$YELLOW""WARN "$BLANK"] did not specify the output directory of graphing files."
        echo -e "[$YELLOW""WARN "$BLANK"] set it to the current directory $YELLOW$(pwd)$BLANK"
        GRAPH_OUTPUT_DIRECTORY=$(pwd)
    else
        # check if the output directory is absolute path
        case $GRAPH_OUTPUT_DIRECTORY in
            /*) ;;
            ./*) GRAPH_OUTPUT_DIRECTORY="$(pwd)/${GRAPH_OUTPUT_DIRECTORY:2}" ;;
            *) GRAPH_OUTPUT_DIRECTORY="$(pwd)/${GRAPH_OUTPUT_DIRECTORY}" ;;
        esac

        # check if the output directory is existed
        if [ ! -d "$GRAPH_OUTPUT_DIRECTORY" ]
        then
            echo -e "[$YELLOW""WARN "$BLANK"] could not find the graphing output directory $YELLOW$GRAPH_OUTPUT_DIRECTORY$BLANK"
            echo -e "[$YELLOW""WARN "$BLANK"] set it to the current directory $YELLOW$(pwd)$BLANK"
            GRAPH_OUTPUT_DIRECTORY=$(pwd)
        fi
    fi

    # print out arguments
    echo -e "[$GREEN""INFO "$BLANK"] the CSV input file: $GREEN$CSV_INPUT_FILE$BLANK"
    echo -e "[$GREEN""INFO "$BLANK"] the metric input file: $GREEN$METRIC_INPUT_FILE$BLANK"
    echo -e "[$GREEN""INFO "$BLANK"] the graphing output directory: $GREEN$GRAPH_OUTPUT_DIRECTORY$BLANK"

    if [ -z "$SINGLE_PLOT" ]
    then
        python3 graph.py $CSV_INPUT_FILE $GRAPH_OUTPUT_DIRECTORY $METRIC_INPUT_FILE
    else
        python3 graph.py $CSV_INPUT_FILE $GRAPH_OUTPUT_DIRECTORY $METRIC_INPUT_FILE $SINGLE_PLOT
    fi
}

if [ -z "$1" ]
then
    usage
    exit
fi

# tool
case "$1" in
    "profile")
        profile "$@" ;;
    "delta")
        delta "$@" ;;
    "csv")
        csv "$@" ;;
    "graph")
        graph "$@" ;;
    *)
        usage
esac

exit
python3 -c "import time; print('%.20f' % time.time())"; date +%s.%3N; echo in seconds

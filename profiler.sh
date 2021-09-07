#!/bin/bash
#======================================================================
#- IMPLEMENTATION
#-    version         profiler (https://www.washington.edu/) 0.4
#-    author          Varik Hoang <varikmp@uw.edu>
#-    copyright       Copyright (c) https://www.washington.edu/
#-    license         GNU General Public License
#======================================================================
#  HISTORY
#     2021/05/19 : varikmp - script creation
#     2021/08/12 : varikmp - implemented time steps for sampling
#======================================================================
#  OPTION
#    PROFILER_OUTPUT_DIR # specify the output directory
#    PROFILER_TIME_STEPS # specify the time step each second
#======================================================================

RED='\e[91m'
GREEN='\e[92m'
YELLOW='\e[93m'
BLANK='\e[39m'

function usage()
{
    echo "Usage: $0 [profile|delta|csv|graph]"
    echo "       profile: to profile a set of commands"
    echo "         -o   --output-directory  : specify the output directory for profiling data in JSON format"
    echo "         -t   --time-steps        : specify the time steps (in seconds) to profile during the command execution"
    echo "         -c   --clean-up          : clean up the profiling files from the previous run"
    echo "       delta: calculate the delta values"
    echo "         -i   --input-directory   : specify the input directory for calculating delta values in JSON format"
    echo "         -o   --output-directory  : specify the output directory for calculating delta values in JSON format"
    echo "         -c   --clean-up          : clean up the delta files from the previous run"
    echo "       csv: generate records and put into CSV file from delta files"
    echo "         -i   --input-directory   : specify the input directory of delta files"
    echo "         -o   --output-file       : specify the output file for CSV file generation"
    echo "         -w   --overwrite         : overwrite the CSV file from the previous run"
    echo "Example:"
    echo "       $0 profile -o ./test -c -t 1 \"sleep 3\""
    echo "       $0 delta -i test/ -o test/"
    echo "       $0 csv -c -i test"
    echo "Todo:"
    echo "     1. Need to have a function that check if all packages installed"
    echo "        - python3: psutil"
    echo "        - ubuntu: bc jq"
    echo "     2. the profiling does not work logically when the time step > 0 and < 1 (generating the JSON files takes too long?)"
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
    # clean up status file from the previous work
    echo "" > status.log

    # capture the arguments
    echo -e "[$GREEN""INFO "$BLANK"] profiling commands ..."; shift
    eval set -- "$(getopt -a --options o:t:cd -- "$@")"
    while true
    do
        case "$1" in
            -o|--output-directory)
                PROFILER_OUTPUT_DIR=$2
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
    PROFILER_COMMAND_SET=$2
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
    echo -e "[$GREEN""INFO "$BLANK"] the time steps (in seconds) for the profiling: $GREEN$PROFILER_TIME_STEPS$BLANK"
    echo -e "[$GREEN""INFO "$BLANK"] the set of commands for the profiling: $GREEN$PROFILER_COMMAND_SET$BLANK"

    # clean up the output directory before profiling
    if [ ! -z "$DO_CLEAN_UP" ]
    then
        find $PROFILER_OUTPUT_DIR -name "????_??_??_??_??_??.json" | xargs -r rm -f
    fi

    # start profiling
    if [ $(echo "$PROFILER_TIME_STEPS > 0" | bc -l) -le 0 ]   
    then
        # execute the set of commands
        python3 ./rudataall.py -vcp $PROFILER_OUTPUT_DIR
        eval $@
        STATUS=$?
        python3 ./rudataall.py -vcp $PROFILER_OUTPUT_DIR
    else
        # execute the set of commands and capture the process id
        eval $@ & PID=$!

        # keep checking the process id until it finishes in time steps
        while kill -0 $PID > /dev/null 2>&1
        do
            python3 ./rudataall.py -vcp $PROFILER_OUTPUT_DIR
            sleep $PROFILER_TIME_STEPS
        done

        # capture the status code
        wait $PID
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
    echo -e "[$GREEN""INFO "$BLANK"] calculating deltas ..."; shift
    eval set -- "$(getopt -a --options i:o:c -- "$@")"
    while true
    do
        case "$1" in
            -i|--input-directory)
                PROFILING_INPUT_DIR=$2
                shift 2;;
            -o|--output-directory)
                DELTA_OUTPUT_DIR=$2
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
    if [ -z "$DELTA_OUTPUT_DIR" ]
    then
        echo -e "[$YELLOW""WARN "$BLANK"] did not specify the output directory of profiling files."
        echo -e "[$YELLOW""WARN "$BLANK"] set it to the same directory of profiling files $YELLOW$PROFILING_INPUT_DIR$BLANK"
        DELTA_OUTPUT_DIR=$PROFILING_INPUT_DIR
    else
        # check if the output directory is absolute path
        case $DELTA_OUTPUT_DIR in
            /*) ;;
            ./*) DELTA_OUTPUT_DIR="$(pwd)/${DELTA_OUTPUT_DIR:2}" ;;
            *) DELTA_OUTPUT_DIR="$(pwd)/${DELTA_OUTPUT_DIR}" ;;
        esac

        # check if the output directory is existed
        if [ ! -d "$DELTA_OUTPUT_DIR" ]
        then
            echo -e "[$YELLOW""WARN "$BLANK"] could not find the output directory $YELLOW$PROFILING_INPUT_DIR$BLANK"
            echo -e "[$YELLOW""WARN "$BLANK"] set it to the same directory of profiling files $YELLOW$PROFILING_INPUT_DIR$BLANK"
            DELTA_OUTPUT_DIR=$PROFILING_INPUT_DIR
        fi
    fi

    # print out arguments
    echo -e "[$GREEN""INFO "$BLANK"] the input directory of the profiling files: $GREEN$PROFILING_INPUT_DIR$BLANK"
    echo -e "[$GREEN""INFO "$BLANK"] the output directory of the profiling files: $GREEN$DELTA_OUTPUT_DIR$BLANK"

    # clean up the output directory before profiling
    if [ ! -z "$DO_CLEAN_UP" ]
    then
        find $DELTA_OUTPUT_DIR -name "delta_????_??_??_??_??_??.json" | xargs -r rm -f
    fi

    # start calculating deltas
    # must sort all files in output directory to alternatively take the deltas
    PROFILING_FILES=$(find $PROFILING_INPUT_DIR -name "????_??_??_??_??_??.json" | sort)
    IFS=$'\n' read -rd '' -a PROFILING_FILES <<< "$PROFILING_FILES"
    SIZE=$((${#PROFILING_FILES[@]}-1))

    for INDEX in $(seq 1 $SIZE)
    do
        PREV_INDEX=$(($INDEX-1))
        ./delta.sh ${PROFILING_FILES[$INDEX]} ${PROFILING_FILES[$PREV_INDEX]} > $DELTA_OUTPUT_DIR/delta_$(date '+%Y_%m_%d_%H_%M_%S').json
    done

    # report the status code (assume the delta calculation is always correct)
    echo -e "[$GREEN""INFO "$BLANK"] calculating deltas passed"
    echo "passed" > status.log
}

function csv()
{
    # clean up status file from the previous work
    echo "" > status.log

    # capture the arguments
    echo -e "[$GREEN""INFO "$BLANK"] generating CSV files ..."; shift
    eval set -- "$(getopt -a --options i:o:w -- "$@")"
    while true
    do
        case "$1" in
            -i|--input-directory)
                DELTA_INPUT_DIR=$2
                shift 2;;
            -o|--output-directory)
                CSV_OUTPUT_FILE=$2
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
        echo -e "[$YELLOW""WARN "$BLANK"] did not specify the input directory of delta files."
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

    # check if the CSV output file is unset
    if [ -z "$CSV_OUTPUT_FILE" ]
    then
        echo -e "[$YELLOW""WARN "$BLANK"] did not specify the CSV output file for deltas."
        echo -e "[$YELLOW""WARN "$BLANK"] set it to $YELLOW./deltas.csv$BLANK"
        CSV_OUTPUT_FILE="$(pwd)/deltas.csv"
    else
        # check if the CSV output file is absolute path
        case $CSV_OUTPUT_FILE in
            /*) ;;
            ./*) CSV_OUTPUT_FILE="$(pwd)/${CSV_OUTPUT_FILE:2}" ;;
            *) CSV_OUTPUT_FILE="$(pwd)/${CSV_OUTPUT_FILE}" ;;
        esac
    fi

    # check if the CSV output file is existed and overwrite flag is on
    if [ ! -z "$DO_OVERWRITE" ] && [ -f "$CSV_OUTPUT_FILE" ]
    then
        # remove the old CSV file
        echo -e "[$YELLOW""WARN "$BLANK"] overwrite the CSV file $YELLOW$CSV_OUTPUT_FILE$BLANK"
        rm -f $CSV_OUTPUT_FILE
    fi

    # set up fields
    CSV_FIELDS="Container_Write_Time","Process_Write_Time","VM_Write_Time","cCpuTime","cCpuTimeKernelMode","cCpuTimeUserMode","cDiskReadBytes","cDiskSectorIO","cDiskWriteBytes","cId","cMajorPGFault","cMemoryMaxUsed","cMemoryUsed","cNetworkBytesRecvd","cNetworkBytesSent","cNumProcesses","cNumProcessors","cPGFault","currentTime","pMetricType","vBootTime","vCpuContextSwitches","vCpuIdleTime","vCpuMhz","vCpuNice","vCpuSteal","vCpuTime","vCpuTimeIOWait","vCpuTimeIntSrvc","vCpuTimeKernelMode","vCpuTimeSoftIntSrvc","vCpuTimeUserMode","vCpuType","vDiskMergedReads","vDiskMergedWrites","vDiskReadTime","vDiskSectorReads","vDiskSectorWrites","vDiskSuccessfulReads","vDiskSuccessfulWrites","vDiskWriteTime","vId","vKernelInfo","vLoadAvg","vMajorPageFault","vMemoryBuffers","vMemoryCached","vMemoryFree","vMemoryTotal","vMetricType","vNetworkBytesRecvd","vNetworkBytesSent","vPgFault"

    # write headers to CSV output file
    echo "$CSV_FIELDS" > $CSV_OUTPUT_FILE

    # print out arguments
    echo -e "[$GREEN""INFO "$BLANK"] the input directory of the profiling: $GREEN$DELTA_INPUT_DIR$BLANK"
    echo -e "[$GREEN""INFO "$BLANK"] the CSV output file of the profiling: $GREEN$CSV_OUTPUT_FILE$BLANK"

    DELTA_FILES=$(find test/ -name "delta_????_??_??_??_??_??.json" | sort)
    for DELTA_FILE in $DELTA_FILES
    do
        jq -r '[.Container_Write_Time,.Process_Write_Time,.VM_Write_Time,.cCpuTime,.cCpuTimeKernelMode,.cCpuTimeUserMode,.cDiskReadBytes,.cDiskSectorIO,.cDiskWriteBytes,.cId,.cMajorPGFault,.cMemoryMaxUsed,.cMemoryUsed,.cNetworkBytesRecvd,.cNetworkBytesSent,.cNumProcesses,.cNumProcessors,.cPGFault,.currentTime,.pMetricType,.vBootTime,.vCpuContextSwitches,.vCpuIdleTime,.vCpuMhz,.vCpuNice,.vCpuSteal,.vCpuTime,.vCpuTimeIOWait,.vCpuTimeIntSrvc,.vCpuTimeKernelMode,.vCpuTimeSoftIntSrvc,.vCpuTimeUserMode,.vCpuType,.vDiskMergedReads,.vDiskMergedWrites,.vDiskReadTime,.vDiskSectorReads,.vDiskSectorWrites,.vDiskSuccessfulReads,.vDiskSuccessfulWrites,.vDiskWriteTime,.vId,.vKernelInfo,.vLoadAvg,.vMajorPageFault,.vMemoryBuffers,.vMemoryCached,.vMemoryFree,.vMemoryTotal,.vMetricType,.vNetworkBytesRecvd,.vNetworkBytesSent,.vPgFault] | @csv' $DELTA_FILE >> $CSV_OUTPUT_FILE
    done

exit







    # clean up the output directory before profiling
    if [ ! -z "$DO_CLEAN_UP" ]
    then
        find $DELTA_OUTPUT_DIR -name "delta_????_??_??_??_??_??.json" | xargs -r rm -f
    fi

    # start calculating deltas
    # must sort all files in output directory to alternatively take the deltas
    PROFILING_FILES=$(find $DELTA_INPUT_DIR -name "????_??_??_??_??_??.json" | sort)
    IFS=$'\n' read -rd '' -a PROFILING_FILES <<< "$PROFILING_FILES"
    SIZE=$((${#PROFILING_FILES[@]}-1))

    for INDEX in $(seq 1 $SIZE)
    do
        PREV_INDEX=$(($INDEX-1))
        ./delta.sh ${PROFILING_FILES[$INDEX]} ${PROFILING_FILES[$PREV_INDEX]} > $DELTA_OUTPUT_DIR/delta_$(date '+%Y_%m_%d_%H_%M_%S').json
    done

    # report the status code (assume the delta calculation is always correct)
    echo -e "[$GREEN""INFO "$BLANK"] calculating deltas passed"
    echo "passed" > status.log
}

if [ -z "$1" ]
then
    usage
    exit
fi

# tool
case "$1" in
    "profile")
        profile $@ ;;
    "delta")
        delta $@ ;;
    "csv")
        csv $@ ;;
    --)
        break;;
esac


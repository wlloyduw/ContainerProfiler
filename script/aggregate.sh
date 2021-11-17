#!/bin/bash
#======================================================================
#- IMPLEMENTATION
#-    version         profiler (https://www.washington.edu/) 0.4
#-    author          Varik Hoang <varikmp@uw.edu>
#-    copyright       Copyright (c) https://www.washington.edu/
#-    license         GNU General Public License
#======================================================================
#  HISTORY
#     2021/11/01 : varikmp - script creation
#     2021/11/08 : varikmp - implemented different aggregate operators
#                            beside the existing one (delta)
#======================================================================
#  OPTION
#    PROFILING_FILE_1 # specify the first  profiling file in JSON format
#    PROFILING_FILE_2 # specify the second profiling file in JSON format
#======================================================================

if [ -z "$1" ] || [ -z "$2" ]
then
    echo "Usage: $0 JSON_FILE_1 JSON_FILE_2"
    exit 1
fi

AGG_CONFIG=aggregate.cfg
DEBUG_FILE=debug.log

function print_aggregations
{
    JSON_FILE_1=$1
    JSON_FILE_2=$2
    local CURRENT_PATH=$3
    
    # remove first line
    # remove last line
    # remove last comma each line
    # remove spaces in the beginning each line
    # remove first quote
    # remove last quote
    if [ -z "$CURRENT_PATH" ]
    then
        KEY_LIST=$(jq $CURRENT_PATH'keys' "$1" | sed '1d;$d;s/,$//;s/^ *//g;s/^.//g;s/.$//g')
    else
        KEY_LIST=$(jq $CURRENT_PATH'|keys' "$1" | sed '1d;$d;s/,$//;s/^ *//g;s/^.//g;s/.$//g')
    fi

    if [ ! -z "$KEY_LIST" ]
    then
        for KEY in ${KEY_LIST[@]}
        do
            
            local DATA_TYPE=$(jq -r $CURRENT_PATH.$KEY'|type' "$1" <<< '""')
            echo "$CURRENT_PATH.$KEY => $DATA_TYPE" >> $DEBUG_FILE
            case $DATA_TYPE in

                "object")
                    #printf "\"$KEY\":{"
                    print_aggregations "$JSON_FILE_1" "$JSON_FILE_2" "$CURRENT_PATH.$KEY"
                    #printf "}"
                    ;;

                "string")
                    printf "\"$KEY\": $(jq "$CURRENT_PATH.$KEY" "$JSON_FILE_1"),"
                    ;;

                "boolean")
                    printf "\"$KEY\": $(jq "$CURRENT_PATH.$KEY" "$JSON_FILE_1"),"
                    ;;

                "null")
                    printf "\"$KEY\": null,"
                    ;;

                "number")
                    VALUE_1=$(jq "$CURRENT_PATH.$KEY" "$JSON_FILE_1")
                    VALUE_2=$(jq "$CURRENT_PATH.$KEY" "$JSON_FILE_2")
                    AGG_OP=$(cat $AGG_CONFIG | grep $CURRENT_PATH.$KEY | cut -d":" -f2)
                    
                    case $AGG_OP in
                        
                        "max")
                            if (( $(bc -l <<< "$VALUE_1 > $VALUE_2") ))
                            then
                                AGG_RS=$VALUE_1
                            else
                                AGG_RS=$VALUE_2
                            fi
                            ;;

                        "min")
                            if (( $(bc -l <<< "$VALUE_1 < $VALUE_2") ))
                            then
                                AGG_RS=$VALUE_1
                            else
                                AGG_RS=$VALUE_2
                            fi
                            ;;

                        "sum")
                            AGG_RS=$(bc -l <<< "$VALUE_2 + $VALUE_1")
                            ;;

                        "avg")
                            AGG_RS=$(bc -l <<< "($VALUE_2 + $VALUE_1) / 2")
                            ;;

                        *) # delta
                            AGG_RS=$(bc -l <<< "$VALUE_2 - $VALUE_1")
                            ;;
                        
                    esac
                    
                    printf "\"$KEY\": $AGG_RS,"
                    ;;

                *) ;;
            esac
        done
    fi
}

# ./delta.sh 2021_11_05_20_45_39.json 2021_11_05_20_45_44.json
# ./delta.sh test1.json test2.json
echo "" > $DEBUG_FILE
printf "{"
sed 's/\$/_/g' "$1" > temp1.json
sed 's/\$/_/g' "$2" > temp2.json

print_aggregations temp1.json temp2.json

rm -f temp1.json
rm -f temp2.json
printf "\"Version\": 1.0"
printf "}"
exit

# check the json data type
# jq -r '[1.23,"abc",true,[],{},null][]| type' <<< '""'
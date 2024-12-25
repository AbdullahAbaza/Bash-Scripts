#!/bin/bash

# variables

global_var="I am global"
readonly read_only_var="you cannot change me"

declare -i int_var=10
declare -r const_var="I am constant readonly "
declare -a array_var=("element1" "element2" "element3")
declare -A assoc_array_var=(["key1"]="value1" ["key2"]="value2")



function modify_var() {
    local local_var="I am local"
    echo $local_var

    global_var="I am global modefied"
}

echo $global_var
modify_var
echo $global_var

echo $local_var # Outputs nothing (undefined)

read_only_var="modify" # Outputs an error message



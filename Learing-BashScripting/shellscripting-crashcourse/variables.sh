#!/bin/bash

name="Abdullah"

n1=3
n2=5
sum=$((n1+n2))
current_date=$date

files=$( ls -lah )
back_teck=`ls -lah`

# echo $back_teck


# variables

global_var="I am global"
readonly read_only_var="you cannot change me"

declare -i int_var=10
declare -r const_var="I am constant readonly "
declare -a array_var=("element1" "element2" "element3")
declare -A assoc_array_var=(["key1"]="value1" ["key2"]="value2")

int_var+=5
echo $int_var
echo "array[0]:" ${array_var[0]}
echo "Dictionary key1:" ${assoc_array_var["key1"]}




